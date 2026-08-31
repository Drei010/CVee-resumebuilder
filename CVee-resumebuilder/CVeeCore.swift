import Foundation
import SwiftData
import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

enum JobTargetSource: String, Codable, CaseIterable, Identifiable {
    case pastedText
    case linkedInURL

    var id: String { rawValue }
    var label: String { self == .pastedText ? "Paste text" : "LinkedIn URL" }
}

enum ResumeSectionKind: String, Codable, CaseIterable {
    case header
    case summary
    case experience
    case skills
    case education

    var title: String { rawValue.capitalized }
}

@Model
final class WorkExperience {
    var id: UUID
    var jobTitle: String
    var company: String
    var startDate: Date
    var endDate: Date?
    var tasksText: String
    var createdAt: Date

    init(jobTitle: String, company: String, startDate: Date = .now, endDate: Date? = nil, tasks: [String] = []) {
        self.id = UUID()
        self.jobTitle = jobTitle
        self.company = company
        self.startDate = startDate
        self.endDate = endDate
        self.tasksText = tasks.joined(separator: "\n")
        self.createdAt = .now
    }

    var tasks: [String] {
        get { tasksText.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }
        set { tasksText = newValue.joined(separator: "\n") }
    }

    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "\(formatter.string(from: startDate)) – \(endDate.map(formatter.string(from:)) ?? "Present")"
    }
}

@Model
final class JobTarget {
    var id: UUID
    var sourceTypeRawValue: String
    var rawText: String
    var linkedInURL: String?
    var parsedTitle: String?
    var parsedCompany: String?
    var createdAt: Date

    init(sourceType: JobTargetSource, rawText: String, linkedInURL: String? = nil, parsedTitle: String? = nil, parsedCompany: String? = nil) {
        self.id = UUID()
        self.sourceTypeRawValue = sourceType.rawValue
        self.rawText = rawText
        self.linkedInURL = linkedInURL
        self.parsedTitle = parsedTitle
        self.parsedCompany = parsedCompany
        self.createdAt = .now
    }

    var sourceType: JobTargetSource {
        get { JobTargetSource(rawValue: sourceTypeRawValue) ?? .pastedText }
        set { sourceTypeRawValue = newValue.rawValue }
    }
}

@Model
final class ResumeSection {
    var id: UUID
    var kindRawValue: String
    var order: Int
    var title: String
    var rtfData: Data
    var resume: Resume? = nil

    init(kind: ResumeSectionKind, order: Int, title: String, attributedText: NSAttributedString) {
        self.id = UUID()
        self.kindRawValue = kind.rawValue
        self.order = order
        self.title = title
        self.rtfData = (try? attributedText.data(from: NSRange(location: 0, length: attributedText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])) ?? Data()
    }

    var kind: ResumeSectionKind {
        get { ResumeSectionKind(rawValue: kindRawValue) ?? .summary }
        set { kindRawValue = newValue.rawValue }
    }

    var attributedText: NSAttributedString {
        get { (try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)) ?? NSAttributedString(string: title) }
        set { rtfData = (try? newValue.data(from: NSRange(location: 0, length: newValue.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])) ?? Data() }
    }
}

@Model
final class Resume {
    var id: UUID
    var name: String
    var template: String
    var createdAt: Date
    var updatedAt: Date
    var jobTarget: JobTarget?
    var workExperienceIDs: String
    @Relationship(deleteRule: .cascade, inverse: \ResumeSection.resume) var sections: [ResumeSection] = []

    init(name: String = "Untitled resume", jobTarget: JobTarget? = nil, workExperienceIDs: [UUID] = [], sections: [ResumeSection] = []) {
        self.id = UUID()
        self.name = name
        self.template = "jakes"
        self.createdAt = .now
        self.updatedAt = .now
        self.jobTarget = jobTarget
        self.workExperienceIDs = workExperienceIDs.map(\.uuidString).joined(separator: ",")
        self.sections = sections
    }

    var linkedWorkExperienceIDs: [UUID] {
        workExperienceIDs.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
    }
}

struct LinkedInFetchResult {
    let text: String
    let title: String?
    let company: String?
}

enum LinkedInFetchError: LocalizedError {
    case invalidURL
    case loginWall
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Enter a valid LinkedIn jobs URL."
        case .loginWall: "LinkedIn requires sign-in for this listing. Paste the job description instead."
        case .emptyContent: "The listing did not contain readable job details. Paste the job description instead."
        }
    }
}

struct LinkedInJobFetcher {
    func fetch(urlString: String) async throws -> LinkedInFetchResult {
        guard let url = URL(string: urlString), url.scheme == "https", url.host?.contains("linkedin.com") == true else {
            throw LinkedInFetchError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode else { throw LinkedInFetchError.emptyContent }
        let html = String(decoding: data, as: UTF8.self)
        let lower = html.lowercased()
        if lower.contains("sign in | linkedin") || lower.contains("join linkedin") || lower.contains("authwall") {
            throw LinkedInFetchError.loginWall
        }
        let text = Self.visibleText(from: html)
        guard text.count > 80 else { throw LinkedInFetchError.emptyContent }
        return LinkedInFetchResult(text: text, title: Self.metaContent("og:title", in: html), company: nil)
    }

    static func visibleText(from html: String) -> String {
        var value = html.replacingOccurrences(of: "(?is)<script.*?</script>|<style.*?</style>|<noscript.*?</noscript>", with: " ", options: .regularExpression)
        value = value.replacingOccurrences(of: "(?s)<[^>]+>", with: " ", options: .regularExpression)
        value = value.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
        return value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func metaContent(_ property: String, in html: String) -> String? {
        let pattern = "<meta[^>]+property=[\\\"']\(property)[\\\"'][^>]+content=[\\\"']([^\\\"']+)"
        return html.range(of: pattern, options: [.regularExpression, .caseInsensitive]).map { String(html[$0]).replacingOccurrences(of: "(?is).*content=[\\\"']|[\\\"'].*", with: "", options: .regularExpression) }
    }
}

struct ResumeDraft {
    var name: String
    var summary: String
    var experience: [(heading: String, bullets: [String])]
    var skills: [String]
    var rawText: String = ""
}

enum ModelAvailabilityState: Equatable {
    case ready
    case unavailable(String)
}

struct FoundationModelsAvailability {
    func state() -> ModelAvailabilityState {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return .ready
            case .unavailable(.deviceNotEligible): return .unavailable("This device does not support Apple Intelligence generation.")
            case .unavailable(.appleIntelligenceNotEnabled): return .unavailable("Turn on Apple Intelligence in Settings to generate resumes.")
            case .unavailable(.modelNotReady): return .unavailable("The on-device model is still preparing. Try again shortly.")
            @unknown default: return .unavailable("On-device generation is not currently available.")
            }
        }
        #endif
        return .unavailable("CVee requires iOS 26 or later with Apple Intelligence enabled.")
    }
}

struct ResumeGenerationService {
    func generate(jobText: String, work: [WorkExperience], profileName: String = "", profileText: String = "", baselineText: String? = nil) async throws -> ResumeDraft {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let name = profileName.isEmpty ? "Test Resume" : profileName
            let text = "(name)\n\nWORK EXPERIENCE\n" + work.map { "\($0.jobTitle) | \($0.company)\n\($0.tasks.joined(separator: "\n"))" }.joined(separator: "\n\n") + "\n\nSKILLS & ABILITIES\nCommunication, Execution"
            return ResumeDraft(name: name, summary: "A focused professional summary for the selected role.", experience: work.map { ($0.jobTitle + " • " + $0.company, $0.tasks) }, skills: ["Communication", "Execution"], rawText: text)
        }
        #endif
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            let session = LanguageModelSession(instructions: ResumePrompt.system)
            let workText = work.map { "\($0.jobTitle) at \($0.company) (\($0.dateRange)): \($0.tasks.joined(separator: "; "))" }.joined(separator: "\n")
            let prompt = "Profile:\n\(profileText)\n\nBaseline resume (optional):\n\(baselineText ?? "None")\n\nTarget job:\n\(jobText)\n\nSelected work library:\n\(workText)\n\nReturn a polished ATS-friendly resume draft with a 2-3 sentence summary, one bullet list per selected role, and 6-10 relevant skills."
            let response = try await session.respond(to: prompt)
            return Self.parse(response.content, work: work, profileName: profileName)
        }
        #endif
        throw GenerationError.unavailable(FoundationModelsAvailability().state())
    }

    private static func parse(_ content: String, work: [WorkExperience], profileName: String = "") -> ResumeDraft {
        let lines = content.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let summary = lines.first(where: { $0.count > 60 }) ?? ""
        let skills = Array(Set(lines.filter { $0.hasPrefix("-") || $0.hasPrefix("•") }.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-• ")) })).prefix(8)
        let experience = work.map { ($0.jobTitle + " • " + $0.company, $0.tasks) }
        return ResumeDraft(name: profileName.isEmpty ? (work.first?.jobTitle ?? "Tailored resume") : profileName, summary: summary, experience: experience, skills: Array(skills), rawText: content.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

private enum ResumePrompt {
    static let outputFormat = """
    OUTPUT FORMAT — follow this exact plain-text layout. Do not use markdown (no **, ##, or other symbols for emphasis). If the candidate did not provide any information for a section (e.g. no projects, no certifications), delete that entire section heading and its contents from the output — do not print \"N/A\", \"None provided\", empty headings, or placeholder text of any kind. Never fill in a placeholder like \"City, State\" or \"Company Name\" with generic text; just leave it out.

    Full Name
    Email | LinkedIn (only include contact details that were provided)

    WORK EXPERIENCE
    Job Title | Company Name[. City, State if provided]                 Month Year – Month Year (or Present)
    Achievement-focused bullet line starting with a strong action verb.
    Another bullet line, one per line, no bullet character needed.

    Job Title | Company Name[. City, State if provided]                 Month Year – Month Year
    Bullet line.

    PROJECTS
    Project Name - Short Description | Tech1, Tech2, Tech3
    Bullet line describing the project or achievement.

    SKILLS & ABILITIES
    Category: item, item, item
    Category: item, item, item

    CERTIFICATIONS
    Certification Name (Abbreviation) | Year

    EDUCATION
    Degree Name                 Month Year – Month Year
    Institution Name[ - City, Country if provided]
    Honor or award, if provided

    Generate the resume now based on the provided information, following this layout exactly.
    """

    static let system = """
    You are an expert ATS resume writer.

    Generate a polished, concise, professional resume using only facts explicitly provided by the candidate.

    IMPORTANT RULES:

    1. Never invent employers, job titles, dates, degrees, certifications, technologies, awards, responsibilities, or metrics.
    2. Never ask follow-up questions or request clarification.
    3. Omit information that was not provided instead of guessing.
    4. Improve grammar, clarity, and professional wording without changing factual meaning.
    5. Use reverse chronological order when dates are available.
    6. Use strong action verbs and concise bullet points, one achievement per line.
    7. Use metrics only when the candidate explicitly supplied them.
    8. Avoid tables, columns, icons, emojis, graphics, and decorative formatting.
    9. Keep the resume to one page when reasonably possible.
    10. Return only the completed resume, with no commentary about the process.

    \(outputFormat)
    """

    static let parseResumeSystem = "Extract resume facts into JSON. Never invent or infer facts. Return only valid JSON with the requested profile, companies, and entries fields. Preserve wording and dates when possible; use empty strings for missing values."

    static let tailorSystem = """
    You are an expert ATS resume writer tailoring work experience to a target job description. Use only facts in the supplied work database entries. Select only entries materially relevant to the target job description, discard unrelated entries, preserve exact company, job title, and month facts, and return only the finished plain-text WORK EXPERIENCE section. Never invent facts, placeholders, N/A, or commentary.

    \(outputFormat)
    """
}

struct TaskEnhancementService {
    func enhance(_ task: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            let session = LanguageModelSession(instructions: """
            Rewrite one resume achievement in Google XYZ style, using only facts stated in the input. \
            Preserve every number in the input exactly — never invent, drop, round, or alter any metric, tool, scope, or outcome. \
            If multiple metrics are stated, lead sentence one with the single most significant one, and work any remaining stated metrics into sentence two rather than omitting them. \
            If the input states no quantifiable metric, lead sentence one with the outcome as described, without inventing a number. \
            If no tools or technologies are mentioned, omit that clause in sentence two rather than naming one. \
            Return exactly two sentences and nothing else: sentence one leads with the result; sentence two states what was done and, if mentioned, what tools or technologies were used. \
            Do not use first-person pronouns, headings, labels, or quotation marks — output only the two sentences, nothing else.

            The example below is style-only; never reuse its facts, numbers, tools, or wording.
            Input: I created typescript automation to reduce manual report generation done by 2 people saving about 3000 dollars per month
            Output: Delivered $40,000 in annual cost savings and eliminated the manual workload of 2 FTEs by developing custom TypeScript data-processing tools to automate complex reporting workflows.
            """)

            let response = try await session.respond(to: "Rewrite this task:\n\(task)")
            return Self.limitToTwoSentences(response.content)
                .split(whereSeparator: \.isNewline)
                .joined(separator: " ")
                .trimmingCharacters(in: CharacterSet(charactersIn: "•·- \t\n"))
        }
        #endif
        throw GenerationError.unavailable(FoundationModelsAvailability().state())
    }

    private static func limitToTwoSentences(_ text: String) -> String {
        var sentenceCount = 0
        var end = text.endIndex
        for index in text.indices where ".!?".contains(text[index]) {
            let next = text.index(after: index)
            guard next == text.endIndex || text[next].isWhitespace else { continue }
            sentenceCount += 1
            if sentenceCount == 2 {
                end = next
                break
            }
        }
        return String(text[..<end])
    }
}

enum GenerationError: LocalizedError {
    case unavailable(ModelAvailabilityState)
    var errorDescription: String? {
        if case .unavailable(let state) = self, case .unavailable(let message) = state { return message }
        return "On-device generation is unavailable."
    }
}

protocol ResumeTemplate {
    var identifier: String { get }
    func render(draft: ResumeDraft) -> NSAttributedString
}

struct JakesResumeTemplate: ResumeTemplate {
    let identifier = "jakes"

    func render(draft: ResumeDraft) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let body = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 10))
        let heading = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.boldSystemFont(ofSize: 11))
        let name = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.boldSystemFont(ofSize: 18))
        func add(_ text: String, font: UIFont, color: UIColor = .label, spacing: CGFloat = 2) {
            result.append(NSAttributedString(string: text + "\n", attributes: [.font: font, .foregroundColor: color, .paragraphStyle: { let p = NSMutableParagraphStyle(); p.paragraphSpacing = spacing; return p }()]))
        }
        add(draft.name.uppercased(), font: name)
        add("TAILORED RESUME", font: body, color: .secondaryLabel, spacing: 10)
        add("SUMMARY", font: heading)
        add(draft.summary, font: body, spacing: 8)
        add("EXPERIENCE", font: heading)
        for role in draft.experience {
            add(role.heading, font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.boldSystemFont(ofSize: 10)), spacing: 1)
            role.bullets.forEach { add("• \($0)", font: body, spacing: 1) }
            result.append(NSAttributedString(string: "\n"))
        }
        add("SKILLS", font: heading)
        add(draft.skills.joined(separator: "  •  "), font: body)
        return result
    }
}

struct ResumeExportService {
    func rtfData(for resume: Resume) throws -> Data {
        let text = combinedText(for: resume)
        return try text.data(from: NSRange(location: 0, length: text.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
    }

    func pdfData(for resume: Resume) -> Data {
        let text = combinedText(for: resume)
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { context in
            context.beginPage()
            text.draw(in: page.insetBy(dx: 48, dy: 48))
        }
    }

    private func combinedText(for resume: Resume) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for section in resume.sections.sorted(by: { $0.order < $1.order }) {
            result.append(section.attributedText)
            result.append(NSAttributedString(string: "\n"))
        }
        return result
    }
}
