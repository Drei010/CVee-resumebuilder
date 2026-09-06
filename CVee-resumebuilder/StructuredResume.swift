import Foundation
import UIKit
import CoreText
import PDFKit

struct ResumeDocumentLayout: Codable, Equatable {
    var pageWidth: CGFloat = 612
    var pageHeight: CGFloat = 792
    var margin: CGFloat = 36
    var bodySize: CGFloat = 11
    var headingSize: CGFloat = 12
    var nameSize: CGFloat = 18
    var targetPages: Int = 1
}

struct ResumeDocument: Codable, Equatable, Identifiable {
    static let currentVersion = 1
    var version = currentVersion
    var id = UUID()
    var sections: [ResumeDocumentSection]
    var layout = ResumeDocumentLayout()
    var originalSource: String?
    var conversionNotes: [String] = []

    static var empty: ResumeDocument {
        ResumeDocument(sections: [ResumeDocumentSection(kind: .header, title: "Contact", content: .contact(ContactContent()))])
    }

    func data() throws -> Data { try JSONEncoder().encode(self) }

    static func load(_ data: Data) throws -> ResumeDocument {
        let document = try JSONDecoder().decode(Self.self, from: data)
        guard document.version == currentVersion else { throw ResumeDocumentError.unsupportedVersion(document.version) }
        guard document.sections.contains(where: { $0.kind == .header }) else { throw ResumeDocumentError.malformed }
        return document
    }
}

enum ResumeDocumentError: LocalizedError {
    case malformed
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .malformed: "This resume's editable data is damaged. The original document is still available."
        case .unsupportedVersion(let version): "This resume uses an unsupported editable format (version \(version))."
        }
    }
}

struct ResumeDocumentSection: Codable, Equatable, Identifiable {
    var id = UUID()
    var kind: ResumeSectionKind
    var title: String
    var isVisible = true
    var content: ResumeSectionContent

    init(id: UUID = UUID(), kind: ResumeSectionKind, title: String, isVisible: Bool = true, content: ResumeSectionContent) {
        self.id = id; self.kind = kind; self.title = title; self.isVisible = isVisible; self.content = content
    }
}

struct ContactContent: Codable, Equatable {
    var name = ""
    var email = ""
    var phone = ""
    var location = ""
    var links: [LabeledLink] = []
}

struct LabeledLink: Codable, Equatable, Identifiable {
    var id = UUID()
    var label = ""
    var url = ""
}

struct ExperienceEntry: Codable, Equatable, Identifiable {
    var id = UUID()
    var role = ""
    var employer = ""
    var location = ""
    var dates = ""
    var bullets: [ResumeBullet] = []
}

struct ProjectEntry: Codable, Equatable, Identifiable {
    var id = UUID()
    var name = ""
    var description = ""
    var technologies = ""
    var link = ""
    var bullets: [ResumeBullet] = []
}

struct EducationEntry: Codable, Equatable, Identifiable {
    var id = UUID()
    var institution = ""
    var qualification = ""
    var location = ""
    var dates = ""
    var honors = ""
}

struct SkillCategory: Codable, Equatable, Identifiable {
    var id = UUID()
    var name = ""
    var items: [String] = []
}

struct CertificationEntry: Codable, Equatable, Identifiable {
    var id = UUID()
    var name = ""
    var issuer = ""
    var date = ""
    var credentialLink = ""
}

struct CustomContent: Codable, Equatable {
    var paragraphs: [String] = []
    var bullets: [ResumeBullet] = []
}

struct ResumeBullet: Codable, Equatable, Identifiable {
    var id = UUID()
    var text = ""
}

enum ResumeSectionContent: Codable, Equatable {
    case contact(ContactContent)
    case summary(String)
    case experience([ExperienceEntry])
    case projects([ProjectEntry])
    case education([EducationEntry])
    case skills([SkillCategory])
    case certifications([CertificationEntry])
    case custom(CustomContent)

    private enum CodingKeys: String, CodingKey { case type, value }
    private enum Kind: String, Codable { case contact, summary, experience, projects, education, skills, certifications, custom }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .contact(let value): try container.encode(Kind.contact, forKey: .type); try container.encode(value, forKey: .value)
        case .summary(let value): try container.encode(Kind.summary, forKey: .type); try container.encode(value, forKey: .value)
        case .experience(let value): try container.encode(Kind.experience, forKey: .type); try container.encode(value, forKey: .value)
        case .projects(let value): try container.encode(Kind.projects, forKey: .type); try container.encode(value, forKey: .value)
        case .education(let value): try container.encode(Kind.education, forKey: .type); try container.encode(value, forKey: .value)
        case .skills(let value): try container.encode(Kind.skills, forKey: .type); try container.encode(value, forKey: .value)
        case .certifications(let value): try container.encode(Kind.certifications, forKey: .type); try container.encode(value, forKey: .value)
        case .custom(let value): try container.encode(Kind.custom, forKey: .type); try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .contact: self = .contact(try container.decode(ContactContent.self, forKey: .value))
        case .summary: self = .summary(try container.decode(String.self, forKey: .value))
        case .experience: self = .experience(try container.decode([ExperienceEntry].self, forKey: .value))
        case .projects: self = .projects(try container.decode([ProjectEntry].self, forKey: .value))
        case .education: self = .education(try container.decode([EducationEntry].self, forKey: .value))
        case .skills: self = .skills(try container.decode([SkillCategory].self, forKey: .value))
        case .certifications: self = .certifications(try container.decode([CertificationEntry].self, forKey: .value))
        case .custom: self = .custom(try container.decode(CustomContent.self, forKey: .value))
        }
    }
}

enum ResumeDocumentConverter {
    static func document(for resume: Resume) throws -> ResumeDocument {
        if let data = resume.structuredDocumentData { return try ResumeDocument.load(data) }
        let sections = resume.sections.sorted { $0.order < $1.order }
        guard !sections.isEmpty else { return .empty }
        return document(from: sections.map { $0.attributedText.string }.joined(separator: "\n"), name: resume.name)
    }

    static func document(from draft: ResumeDraft) -> ResumeDocument {
        document(from: draft.rawText.isEmpty ? JakesResumeTemplate().render(draft: draft).string : draft.rawText, name: draft.name)
    }

    static func document(from text: String, name: String = "Untitled resume") -> ResumeDocument {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var sections: [ResumeDocumentSection] = []
        var contact = ContactContent(name: lines.first ?? name)
        if lines.count > 1, !isHeading(lines[1]) { contact.email = lines[1].components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces) ?? "" }
        sections.append(ResumeDocumentSection(kind: .header, title: "Contact", content: .contact(contact)))

        var currentKind: ResumeSectionKind?
        var currentTitle = ""
        var currentLines: [String] = []
        func flush() {
            guard let currentKind, !currentLines.isEmpty else { return }
            sections.append(section(kind: currentKind, title: currentTitle, lines: currentLines))
            currentLines.removeAll()
        }
        for line in lines.dropFirst(contact.email.isEmpty ? 1 : 2) {
            if let kind = headingKind(line) { flush(); currentKind = kind; currentTitle = kind == .custom ? line : kind.title }
            else if !line.isEmpty { currentLines.append(line) }
        }
        flush()
        if sections.count == 1 {
            sections.append(ResumeDocumentSection(kind: .custom, title: "Review placement", content: .custom(CustomContent(paragraphs: [text]))))
        }
        return ResumeDocument(sections: sections, originalSource: text, conversionNotes: ["Review the proposed section placement before exporting."])
    }

    private static func section(kind: ResumeSectionKind, title: String, lines: [String]) -> ResumeDocumentSection {
        switch kind {
        case .header: return ResumeDocumentSection(kind: .header, title: "Contact", content: .contact(ContactContent()))
        case .summary: return ResumeDocumentSection(kind: .summary, title: title, content: .summary(lines.joined(separator: " ")))
        case .experience: return ResumeDocumentSection(kind: .experience, title: title, content: .experience(entries(from: lines)))
        case .projects: return ResumeDocumentSection(kind: .projects, title: title, content: .projects([ProjectEntry(name: lines.first ?? "", bullets: bullets(from: Array(lines.dropFirst()))) ]))
        case .education: return ResumeDocumentSection(kind: .education, title: title, content: .education([EducationEntry(institution: lines.first ?? "", qualification: lines.dropFirst().first ?? "", honors: lines.dropFirst(2).joined(separator: " "))]))
        case .skills: return ResumeDocumentSection(kind: .skills, title: title, content: .skills(lines.map { line in let parts = line.split(separator: ":", maxSplits: 1).map(String.init); return SkillCategory(name: parts.first ?? "Skills", items: parts.dropFirst().first?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []) }))
        case .certifications: return ResumeDocumentSection(kind: .certifications, title: title, content: .certifications(lines.map { CertificationEntry(name: $0) }))
        case .custom: return ResumeDocumentSection(kind: .custom, title: title, content: .custom(CustomContent(paragraphs: lines.filter { !$0.hasPrefix("•") && !$0.hasPrefix("-") }, bullets: bullets(from: lines))))
        }
    }

    private static func entries(from lines: [String]) -> [ExperienceEntry] {
        var result: [ExperienceEntry] = []
        for line in lines {
            if line.hasPrefix("•") || line.hasPrefix("-") {
                if result.isEmpty { result.append(ExperienceEntry()) }
                result[result.count - 1].bullets.append(ResumeBullet(text: line.trimmingCharacters(in: CharacterSet(charactersIn: "•- "))))
            } else {
                let parts = line.components(separatedBy: "|")
                result.append(ExperienceEntry(role: parts.first?.trimmingCharacters(in: .whitespaces) ?? line, employer: parts.dropFirst().first?.trimmingCharacters(in: .whitespaces) ?? "", dates: parts.dropFirst(2).joined(separator: "|").trimmingCharacters(in: .whitespaces), bullets: []))
            }
        }
        if result.isEmpty { result = [ExperienceEntry()] }
        return result
    }

    private static func bullets(from lines: [String]) -> [ResumeBullet] { lines.filter { $0.hasPrefix("•") || $0.hasPrefix("-") }.map { ResumeBullet(text: $0.trimmingCharacters(in: CharacterSet(charactersIn: "•- "))) } }
    private static func isHeading(_ line: String) -> Bool { headingKind(line) != nil }
    private static func headingKind(_ line: String) -> ResumeSectionKind? {
        switch line.uppercased() {
        case "SUMMARY", "PROFESSIONAL SUMMARY": .summary
        case "WORK EXPERIENCE", "EXPERIENCE": .experience
        case "PROJECTS": .projects
        case "EDUCATION": .education
        case "SKILLS", "SKILLS & ABILITIES": .skills
        case "CERTIFICATIONS": .certifications
        default: nil
        }
    }
}

struct ResumeDocumentRenderer {
    func attributedText(for document: ResumeDocument) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let body = UIFont(name: "Arial", size: document.layout.bodySize) ?? UIFont.systemFont(ofSize: document.layout.bodySize)
        let heading = UIFont(name: "Arial-BoldMT", size: document.layout.headingSize) ?? UIFont.boldSystemFont(ofSize: document.layout.headingSize)
        let name = UIFont(name: "Arial-BoldMT", size: document.layout.nameSize) ?? UIFont.boldSystemFont(ofSize: document.layout.nameSize)
        let contact = UIFont(name: "Arial", size: 10) ?? UIFont.systemFont(ofSize: 10)
        for section in document.sections where section.isVisible && section.hasVisibleContent {
            if case .contact(let value) = section.content {
                append(value.name, font: name, alignment: .center, to: result)
                append([value.email, value.phone, value.location, value.links.map { "\($0.label): \($0.url)" }.joined(separator: " · ")].filter { !$0.isEmpty }.joined(separator: " | "), font: contact, color: ResumeTextFormatter.documentContactColor, alignment: .center, to: result)
                continue
            }
            append(section.title.uppercased(), font: heading, spacing: 8, to: result)
            switch section.content {
            case .summary(let text): append(text, font: body, spacing: 5, to: result)
            case .experience(let entries): for entry in entries { appendEntry(entry.role, detail: [entry.employer, entry.location, entry.dates].filter { !$0.isEmpty }.joined(separator: " · "), bullets: entry.bullets, font: body, to: result) }
            case .projects(let entries): for entry in entries { appendEntry(entry.name, detail: [entry.description, entry.technologies, entry.link].filter { !$0.isEmpty }.joined(separator: " · "), bullets: entry.bullets, font: body, to: result) }
            case .education(let entries): for entry in entries { appendEntry(entry.qualification, detail: [entry.institution, entry.location, entry.dates, entry.honors].filter { !$0.isEmpty }.joined(separator: " · "), bullets: [], font: body, to: result) }
            case .skills(let categories): for category in categories { append(category.name.isEmpty ? category.items.joined(separator: ", ") : "\(category.name): \(category.items.joined(separator: ", "))", font: body, spacing: 3, to: result) }
            case .certifications(let entries): for entry in entries { append([entry.name, entry.issuer, entry.date].filter { !$0.isEmpty }.joined(separator: " · "), font: body, spacing: 3, to: result) }
            case .custom(let custom): for paragraph in custom.paragraphs { append(paragraph, font: body, spacing: 4, to: result); for bullet in custom.bullets { append("• \(bullet.text)", font: body, hanging: true, to: result) } }
            case .contact: break
            }
        }
        return result
    }

    func pdfData(for document: ResumeDocument) -> Data {
        let text = attributedText(for: document)
        guard !text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return Data() }
        let page = CGRect(x: 0, y: 0, width: document.layout.pageWidth, height: document.layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { context in
            let framesetter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
            var location = 0
            while location < text.length {
                context.beginPage(); context.cgContext.saveGState(); context.cgContext.translateBy(x: 0, y: page.height); context.cgContext.scaleBy(x: 1, y: -1)
                let path = CGPath(rect: page.insetBy(dx: document.layout.margin, dy: document.layout.margin), transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: location, length: 0), path, nil)
                CTFrameDraw(frame, context.cgContext); let visible = CTFrameGetVisibleStringRange(frame); context.cgContext.restoreGState()
                guard visible.length > 0 else { break }; location += visible.length
            }
        }
    }

    func pageCount(for document: ResumeDocument) -> Int { PDFDocument(data: pdfData(for: document))?.pageCount ?? 0 }

    private func append(_ value: String, font: UIFont, color: UIColor = .black, alignment: NSTextAlignment = .left, spacing: CGFloat = 0, hanging: Bool = false, to result: NSMutableAttributedString) {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let paragraph = NSMutableParagraphStyle(); paragraph.paragraphSpacing = spacing; paragraph.lineSpacing = 1
        if hanging { paragraph.headIndent = 14 }
        paragraph.alignment = alignment
        result.append(NSAttributedString(string: value + "\n", attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]))
    }

    private func appendEntry(_ title: String, detail: String, bullets: [ResumeBullet], font: UIFont, to result: NSMutableAttributedString) {
        append([title, detail].filter { !$0.isEmpty }.joined(separator: " | "), font: font, spacing: 2, to: result)
        for bullet in bullets { append("• \(bullet.text)", font: font, hanging: true, to: result) }
    }
}

extension ResumeDocumentSection {
    var hasVisibleContent: Bool {
        switch content {
        case .contact(let value): return [value.name, value.email, value.phone, value.location].contains { !$0.isEmpty } || !value.links.isEmpty
        case .summary(let value): return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .experience(let value): return value.contains { !$0.role.isEmpty || !$0.employer.isEmpty || !$0.bullets.isEmpty }
        case .projects(let value): return value.contains { !$0.name.isEmpty || !$0.description.isEmpty || !$0.bullets.isEmpty }
        case .education(let value): return value.contains { !$0.institution.isEmpty || !$0.qualification.isEmpty }
        case .skills(let value): return value.contains { !$0.name.isEmpty || !$0.items.isEmpty }
        case .certifications(let value): return value.contains { !$0.name.isEmpty || !$0.issuer.isEmpty }
        case .custom(let value): return value.paragraphs.contains { !$0.isEmpty } || value.bullets.contains { !$0.text.isEmpty }
        }
    }
}

enum ResumeLaTeXImporter {
    struct Result { let text: String; let unsupportedCommands: [String] }

    static func convert(_ source: String) -> Result {
        var text = source
        text = text.replacingOccurrences(of: #"(?s).*?\\begin\{document\}"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"(?s)\\end\{document\}.*"#, with: "", options: .regularExpression)
        let commands = Set(text.matches(of: /\\[A-Za-z]+\*?/).map { String($0.output) }).filter { !["\\textbf", "\\textit", "\\emph", "\\section", "\\section*", "\\subsection", "\\subsection*", "\\item", "\\begin", "\\end", "\\hfill", "\\linebreak", "\\newline"].contains($0) }.sorted()
        text = text.replacingOccurrences(of: #"\\(?:textbf|textit|emph|section\*?|subsection\*?)\{([^{}]*)\}"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\\item\s*"#, with: "• ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\\(?:begin|end)\{[^}]+\}"#, with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\\(?:hfill|linebreak|newline|\\)"#, with: "\n", options: .regularExpression)
        for (escaped, value) in [("\\&", "&"), ("\\%", "%"), ("\\#", "#"), ("\\_", "_"), ("\\{", "{"), ("\\}", "}"), (#"\\textbackslash{}"#, "\\")] { text = text.replacingOccurrences(of: escaped, with: value) }
        text = text.replacingOccurrences(of: #"\\[A-Za-z]+(?:\*)?(?:\[[^]]*\])?"#, with: "", options: .regularExpression)
        return Result(text: text.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").trimmingCharacters(in: .whitespacesAndNewlines), unsupportedCommands: commands)
    }
}
