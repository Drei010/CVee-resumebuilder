import Foundation
import PDFKit
import SwiftData
import UIKit
import UniformTypeIdentifiers
import Vision

enum JobCaptureReviewState: String, Codable {
    case reviewed
    case needsReview
}

struct JobAttachmentReference: Codable, Hashable, Identifiable {
    let id: UUID
    let filename: String
    let relativePath: String
    let contentType: String
    var displayName: String { filename }
}

struct JobCapturePackageAttachment: Codable, Hashable {
    let filename: String
    let relativePath: String
    let contentType: String
}

struct JobCapturePackage: Codable, Identifiable {
    static let currentVersion = 1
    let version: Int
    let id: UUID
    let createdAt: Date
    var text: String?
    var sourceURL: String?
    var title: String?
    var company: String?
    var attachments: [JobCapturePackageAttachment]

    init(id: UUID = UUID(), createdAt: Date = .now, text: String? = nil, sourceURL: String? = nil, title: String? = nil, company: String? = nil, attachments: [JobCapturePackageAttachment] = []) {
        version = Self.currentVersion
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.sourceURL = sourceURL
        self.title = title
        self.company = company
        self.attachments = attachments
    }
}

struct JobCaptureDraft: Codable, Equatable {
    var title = ""
    var company = ""
    var sourceURL = ""
    var description = ""
    var originalSource = ""
    var sourceType: JobTargetSource = .pastedText
    var captureID: UUID?
    var reviewState: JobCaptureReviewState = .reviewed
    var attachments: [JobAttachmentReference] = []

    var hasContent: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        URL(string: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines))?.isHTTPURL == true ||
        !attachments.isEmpty
    }
}

extension URL {
    var isHTTPURL: Bool { scheme?.lowercased() == "http" || scheme?.lowercased() == "https" }
}

enum JobCaptureError: LocalizedError {
    case invalidURL
    case unsupported
    case tooManyImages
    case tooManyPages
    case tooLarge
    case tooMuchText
    case empty
    case unreadable(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Enter a valid HTTP(S) URL."
        case .unsupported: "Choose a PDF, DOCX, TXT, or image file."
        case .tooManyImages: "Choose one document or up to ten images."
        case .tooManyPages: "This PDF has more than 20 pages."
        case .tooLarge: "Attachments must be 10 MB or smaller in total."
        case .tooMuchText: "The capture contains more than 100,000 characters."
        case .empty: "No readable job details were found."
        case .unreadable(let message): message
        case .fetchFailed(let message): message
        }
    }
}

enum JobCaptureLimits {
    static let maxBytes = 10_000_000
    static let maxImages = 10
    static let maxPages = 20
    static let maxCharacters = 100_000
}

struct JobCaptureStore {
    static let appGroupIdentifier = "group.com.drei010.CVee-resumebuilder"
    private let fileManager = FileManager.default
    private let root: URL

    init() {
        root = Self.containerURL()
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: root.appendingPathComponent("Inbox", isDirectory: true), withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: root.appendingPathComponent("Attachments", isDirectory: true), withIntermediateDirectories: true)
    }

    private static func containerURL() -> URL {
        if let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) { return shared.appendingPathComponent("JobCapture", isDirectory: true) }
        return (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]).appendingPathComponent("CVee/JobCapture", isDirectory: true)
    }

    private var inbox: URL { root.appendingPathComponent("Inbox", isDirectory: true) }
    private var attachments: URL { root.appendingPathComponent("Attachments", isDirectory: true) }

    func packages() -> [JobCapturePackage] {
        guard let urls = try? fileManager.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil) else { return [] }
        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url.appendingPathComponent("package.json")) else { return nil }
            return try? JSONDecoder().decode(JobCapturePackage.self, from: data)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func save(package: JobCapturePackage, attachmentURLs: [URL] = []) throws {
        let staging = inbox.appendingPathComponent(".staging-\(package.id.uuidString)", isDirectory: true)
        let destination = inbox.appendingPathComponent(package.id.uuidString, isDirectory: true)
        try? fileManager.removeItem(at: staging)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        var copied: [JobCapturePackageAttachment] = []
        for url in attachmentURLs {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            guard (values.fileSize ?? 0) <= JobCaptureLimits.maxBytes else { throw JobCaptureError.tooLarge }
            let filename = url.lastPathComponent.isEmpty ? "attachment" : url.lastPathComponent
            let relative = filename.replacingOccurrences(of: "/", with: "-")
            try Data(contentsOf: url).write(to: staging.appendingPathComponent(relative), options: .atomic)
            copied.append(JobCapturePackageAttachment(filename: filename, relativePath: relative, contentType: url.pathExtension))
        }
        var package = package
        package.attachments = package.attachments + copied
        let packageData = try JSONEncoder().encoded(package)
        try packageData.write(to: staging.appendingPathComponent("package.json"), options: .atomic)
        try? fileManager.removeItem(at: destination)
        try fileManager.moveItem(at: staging, to: destination)
    }

    func copyAttachments(from package: JobCapturePackage) throws -> [JobAttachmentReference] {
        let source = inbox.appendingPathComponent(package.id.uuidString, isDirectory: true)
        let destination = attachments.appendingPathComponent(package.id.uuidString, isDirectory: true)
        try? fileManager.removeItem(at: destination)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        return try package.attachments.map { attachment in
            let safeName = attachment.relativePath.replacingOccurrences(of: "/", with: "-")
            let target = destination.appendingPathComponent(safeName)
            try fileManager.copyItem(at: source.appendingPathComponent(attachment.relativePath), to: target)
            return JobAttachmentReference(id: UUID(), filename: attachment.filename, relativePath: "\(package.id.uuidString)/\(safeName)", contentType: attachment.contentType)
        }
    }

    func copyAttachments(from urls: [URL], for captureID: UUID) throws -> [JobAttachmentReference] {
        let destination = attachments.appendingPathComponent(captureID.uuidString, isDirectory: true)
        try? fileManager.removeItem(at: destination)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let totalBytes = try urls.reduce(0) { total, url in total + ((try url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        guard totalBytes <= JobCaptureLimits.maxBytes else { throw JobCaptureError.tooLarge }
        return try urls.map { url in
            let filename = url.lastPathComponent.isEmpty ? "attachment" : url.lastPathComponent
            let safeName = filename.replacingOccurrences(of: "/", with: "-")
            try fileManager.copyItem(at: url, to: destination.appendingPathComponent(safeName))
            return JobAttachmentReference(id: UUID(), filename: filename, relativePath: "\(captureID.uuidString)/\(safeName)", contentType: url.pathExtension)
        }
    }

    func removePackage(_ package: JobCapturePackage) { try? fileManager.removeItem(at: inbox.appendingPathComponent(package.id.uuidString)) }

    func removeAttachments(for job: JobTarget) {
        for reference in job.attachments {
            let url = attachments.appendingPathComponent(reference.relativePath)
            try? fileManager.removeItem(at: url)
        }
        if let captureID = job.captureID { try? fileManager.removeItem(at: attachments.appendingPathComponent(captureID.uuidString)) }
    }

    func removeAttachments(for captureID: UUID) { try? fileManager.removeItem(at: attachments.appendingPathComponent(captureID.uuidString)) }

    func fileURL(for reference: JobAttachmentReference) -> URL {
        attachments.appendingPathComponent(reference.relativePath)
    }

    func removeAll() {
        try? fileManager.removeItem(at: inbox)
        try? fileManager.removeItem(at: attachments)
        try? fileManager.createDirectory(at: inbox, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: attachments, withIntermediateDirectories: true)
    }

    func importPendingPackages(in context: ModelContext) throws -> Int {
        let existing = try context.fetch(FetchDescriptor<JobTarget>())
        var imported = 0
        for package in packages() where !existing.contains(where: { $0.captureID == package.id }) {
            let refs = try copyAttachments(from: package)
            let sourceType: JobTargetSource = package.attachments.contains(where: { $0.contentType.lowercased().contains("image") || ["png", "jpg", "jpeg"].contains($0.contentType.lowercased()) }) ? .screenshot : .shareExtension
            let job = JobTarget(sourceType: sourceType, rawText: package.text ?? "", parsedTitle: package.title, parsedCompany: package.company, sourceURL: package.sourceURL, captureID: package.id, attachmentReferencesData: try? JSONEncoder().encode(refs), captureReviewState: .needsReview)
            context.insert(job)
            do { try context.save() } catch { context.delete(job); throw error }
            removePackage(package)
            imported += 1
        }
        return imported
    }
}

private extension JSONEncoder {
    func encoded<T: Encodable>(_ value: T) throws -> Data { try encode(value) }
}

enum JobCaptureDraftStore {
    private static let key = "job.capture.draft"
    static func load() -> JobCaptureDraft? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(JobCaptureDraft.self, from: data)
    }
    static func save(_ draft: JobCaptureDraft) { UserDefaults.standard.set(try? JSONEncoder().encode(draft), forKey: key) }
    static func clear() { UserDefaults.standard.removeObject(forKey: key) }
}

struct JobCaptureExtractor {
    func extract(urls: [URL]) async throws -> String {
        guard !urls.isEmpty else { throw JobCaptureError.empty }
        let images = urls.filter { ["png", "jpg", "jpeg", "heic", "tiff"].contains($0.pathExtension.lowercased()) }
        if images.count > JobCaptureLimits.maxImages || (images.isEmpty == false && images.count != urls.count) { throw JobCaptureError.tooManyImages }
        if images.isEmpty && urls.count > 1 { throw JobCaptureError.tooManyImages }
        let totalBytes = try urls.reduce(0) { total, url in total + ((try url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        guard totalBytes <= JobCaptureLimits.maxBytes else { throw JobCaptureError.tooLarge }

        var pages: [String] = []
        for url in urls {
            if images.contains(url) {
                pages.append(try await recognizeText(in: url))
            } else if url.pathExtension.lowercased() == "pdf" {
                pages.append(contentsOf: try await extractPDF(url))
            } else {
                pages.append(try TaskDocumentReader().read(url))
            }
        }
        let result = pages.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: "\n\n")
        guard !result.isEmpty else { throw JobCaptureError.empty }
        guard result.count <= JobCaptureLimits.maxCharacters else { throw JobCaptureError.tooMuchText }
        return result
    }

    func suggestions(from text: String) -> (title: String?, company: String?) {
        let lines = text.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let title = lines.first(where: { $0.range(of: "^(job title|role|position)\\s*[:\\-]", options: [.regularExpression, .caseInsensitive]) != nil })?.split(separator: ":", maxSplits: 1).last.map { $0.trimmingCharacters(in: .whitespaces) }
            ?? lines.first(where: { $0.count < 100 && !$0.contains("@") })
        let company = lines.first(where: { $0.range(of: "^(company|employer)\\s*[:\\-]", options: [.regularExpression, .caseInsensitive]) != nil })?.split(separator: ":", maxSplits: 1).last.map { $0.trimmingCharacters(in: .whitespaces) }
        return (title, company)
    }

    private func extractPDF(_ url: URL) async throws -> [String] {
        guard let document = PDFDocument(url: url) else { throw JobCaptureError.unreadable("The PDF could not be opened.") }
        guard document.pageCount <= JobCaptureLimits.maxPages else { throw JobCaptureError.tooManyPages }
        var pages: [String] = []
        for index in 0..<document.pageCount {
            try Task.checkCancellation()
            let text = document.page(at: index)?.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            pages.append(text.count >= 20 ? text : try await recognizeText(in: document.page(at: index)))
        }
        return pages
    }

    private func recognizeText(in url: URL) async throws -> String {
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { throw JobCaptureError.unreadable("The image could not be opened.") }
        return try await recognizeText(in: image)
    }

    private func recognizeText(in page: PDFPage?) async throws -> String {
        guard let page, let image = page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox).cgImage else { throw JobCaptureError.unreadable("The PDF page could not be rendered.") }
        return try await recognizeText(in: image)
    }

    private func recognizeText(in image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error { continuation.resume(throwing: error); return }
                    let text = (request.results as? [VNRecognizedTextObservation] ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    continuation.resume(returning: text)
                }
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-US"]
                request.usesLanguageCorrection = true
                do { try VNImageRequestHandler(cgImage: image, options: [:]).perform([request]) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
}

enum JobTargetDuplicateDetector {
    static func normalizedURL(_ value: String) -> String? {
        guard var components = URLComponents(string: value.trimmingCharacters(in: .whitespacesAndNewlines)), components.url?.isHTTPURL == true else { return nil }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        if components.port == 80 && components.scheme == "http" || components.port == 443 && components.scheme == "https" { components.port = nil }
        components.fragment = nil
        components.queryItems = components.queryItems?.filter { !["fbclid", "gclid"].contains($0.name.lowercased()) && !$0.name.lowercased().hasPrefix("utm_") }
        return components.string
    }

    static func normalizedDescription(_ value: String) -> String { value.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased() }
    static func duplicate(of draft: JobCaptureDraft, in jobs: [JobTarget]) -> JobTarget? {
        let url = normalizedURL(draft.sourceURL)
        let text = normalizedDescription(draft.description)
        return jobs.first { job in
            (url != nil && normalizedURL(job.sourceURL ?? "") == url) || (!text.isEmpty && normalizedDescription(job.rawText) == text)
        }
    }
}

struct JobDescriptionFetcher {
    struct Result { let text: String; let title: String?; let company: String? }

    func fetch(urlString: String) async throws -> Result {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)), url.isHTTPURL else { throw JobCaptureError.invalidURL }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode else { throw JobCaptureError.fetchFailed("The page could not be loaded.") }
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count > 2_000_000 { throw JobCaptureError.fetchFailed("The page is larger than 2 MB.") }
        }
        let html = String(decoding: data, as: UTF8.self)
        let title = metadata("og:title", in: html) ?? metadata("title", in: html)
        let company = metadata("og:site_name", in: html)
        let text = LinkedInJobFetcher.visibleText(from: html)
        guard text.count > 40 else { throw JobCaptureError.fetchFailed("The page did not contain readable job details.") }
        return Result(text: text, title: title, company: company)
    }

    private func metadata(_ name: String, in html: String) -> String? {
        let pattern = "(?is)<meta[^>]+(?:property|name)=[\\\"']\(name)[\\\"'][^>]+content=[\\\"']([^\\\"']+)"
        return html.range(of: pattern, options: .regularExpression).map { String(html[$0]).replacingOccurrences(of: "(?is).*content=[\\\"']|[\\\"'].*", with: "", options: .regularExpression) }
    }
}
