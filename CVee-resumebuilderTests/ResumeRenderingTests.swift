import XCTest
import SwiftData
import SwiftUI
import PDFKit
import UIKit
@testable import CVee_resumebuilder

@MainActor
final class ResumeRenderingTests: XCTestCase {
    func testStructuredDocumentRoundTripPreservesOrderVisibilityAndUnicode() throws {
        var document = ResumeDocument.empty
        document.sections.append(ResumeDocumentSection(kind: .experience, title: "Experience", isVisible: false, content: .experience([ExperienceEntry(role: "Développeur", bullets: [ResumeBullet(text: "Built résumé tools")])])) )
        let restored = try ResumeDocument.load(document.data())
        XCTAssertEqual(restored, document)
        XCTAssertEqual(restored.sections.map(\.kind), [.header, .experience])
        XCTAssertFalse(restored.sections[1].isVisible)
    }

    func testLegacyConversionKeepsAmbiguousSourceForReview() {
        let source = "Taylor Example\ntaylor@example.com\nA passage without a known heading."
        let document = ResumeDocumentConverter.document(from: source, name: "Taylor Example")
        XCTAssertEqual(document.originalSource, source)
        XCTAssertTrue(document.conversionNotes.isEmpty == false)
        XCTAssertTrue(document.sections.contains { $0.title == "Review placement" })
    }

    func testEditedResumePersistsAndExportsAllSuppliedContent() throws {
        let source = """
        Taylor Edited
        taylor@example.com | https://linkedin.com/in/taylor | Manila
        Unclassified supplied content.
        WORK EXPERIENCE
        Engineer | Example Company | 2024 – Present
        Built EDITED_SENTINEL tools with SwiftUI.
        • Preserved BULLET_SENTINEL metrics supplied by the user.
        PROJECTS
        Resume workspace
        Kept PROJECT_SENTINEL description.
        SKILLS & ABILITIES
        :
        SwiftUI, Python
        CERTIFICATIONS
        CERTIFICATION_SENTINEL | 2025
        """
        let container = try ModelContainer(for: Resume.self, ResumeSection.self, JobTarget.self, WorkExperience.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let document = ResumeDocumentConverter.document(from: source, name: "Edited resume")
        let resume = Resume(name: "Edited resume", structuredDocumentData: try document.data())
        context.insert(resume)
        try context.save()
        let saved = try XCTUnwrap(context.fetch(FetchDescriptor<Resume>()).first)
        let reopened = try ResumeDocumentConverter.document(for: saved)
        let rendered = ResumeDocumentRenderer().attributedText(for: reopened).string
        let pdf = try XCTUnwrap(PDFDocument(data: ResumeExportService().pdfData(for: saved))).string ?? ""
        let data = try ResumeExportService().rtfData(for: saved)
        let rtf = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil).string
        for expected in ["Taylor Edited", "https://linkedin.com/in/taylor", "Manila", "Unclassified supplied content", "EDITED_SENTINEL", "BULLET_SENTINEL", "PROJECT_SENTINEL", "SwiftUI", "Python", "CERTIFICATION_SENTINEL"] {
            for actual in [rendered, pdf, rtf] { XCTAssertTrue(actual.contains(expected), "Missing \(expected)") }
        }
        XCTAssertEqual(reopened.originalSource, source)
    }

    func testCustomBulletOnlySectionExportsOnce() throws {
        var document = ResumeDocument.empty
        document.sections.append(ResumeDocumentSection(kind: .custom, title: "Achievements", content: .custom(CustomContent(bullets: [ResumeBullet(text: "UNIQUE_BULLET")]))))
        let rendered = ResumeDocumentRenderer().attributedText(for: document).string
        XCTAssertEqual(rendered.components(separatedBy: "UNIQUE_BULLET").count - 1, 1)
        document.sections[1].content = .custom(CustomContent(paragraphs: ["First paragraph", "Second paragraph"], bullets: [ResumeBullet(text: "UNIQUE_BULLET")]))
        XCTAssertEqual(ResumeDocumentRenderer().attributedText(for: document).string.components(separatedBy: "UNIQUE_BULLET").count - 1, 1)
    }

    func testConverterReadsTheGenerationPromptLayout() {
        let text = """
        Taylor Example
        taylor@example.com | linkedin.com/in/taylor
        WORK EXPERIENCE
        iOS Engineer | Acme Corp. Seattle, WA                 Sep 2022 – Present
        Shipped offline sync for 40,000 users.
        Cut crash rate by 30%.
        Intern | Beta LLC                 Jun 2021 – Aug 2021
        Built test tooling.
        PROJECTS
        CVee - Resume builder | Swift, SwiftUI
        Added PDF export.
        Budget Bot - Expense tracker | Python
        Parsed bank statements.
        EDUCATION
        BS Computer Science                 Sep 2017 – Jun 2021
        State University - Austin, USA
        Dean's List
        MS Software Engineering                 Sep 2021 – Jun 2022
        Tech Institute
        """
        let sections = ResumeDocumentConverter.document(from: text).sections
        guard case .experience(let jobs)? = sections.first(where: { $0.kind == .experience })?.content,
              case .projects(let projects)? = sections.first(where: { $0.kind == .projects })?.content,
              case .education(let schools)? = sections.first(where: { $0.kind == .education })?.content else { return XCTFail("Missing a section") }
        XCTAssertEqual(jobs.map(\.role), ["iOS Engineer", "Intern"])
        XCTAssertEqual(jobs.map(\.employer), ["Acme Corp. Seattle, WA", "Beta LLC"])
        XCTAssertEqual(jobs.map(\.dates), ["Sep 2022 – Present", "Jun 2021 – Aug 2021"])
        XCTAssertEqual(jobs[0].bullets.map(\.text), ["Shipped offline sync for 40,000 users.", "Cut crash rate by 30%."])
        XCTAssertEqual(projects.map(\.name), ["CVee", "Budget Bot"])
        XCTAssertEqual(projects.map(\.description), ["Resume builder", "Expense tracker"])
        XCTAssertEqual(projects.map(\.technologies), ["Swift, SwiftUI", "Python"])
        XCTAssertEqual(projects[1].bullets.map(\.text), ["Parsed bank statements."])
        XCTAssertEqual(schools.map(\.qualification), ["BS Computer Science", "MS Software Engineering"])
        XCTAssertEqual(schools.map(\.institution), ["State University - Austin, USA", "Tech Institute"])
        XCTAssertEqual(schools.map(\.dates), ["Sep 2017 – Jun 2021", "Sep 2021 – Jun 2022"])
        XCTAssertEqual(schools[0].honors, "Dean's List")
    }

    func testLatexImporterReadsJakesTemplate() {
        let source = #"""
        \documentclass[letterpaper,11pt]{article}
        \begin{document}
        %----------HEADING----------
        \begin{center}
            \textbf{\Huge \scshape Jake Ryan} \\ \vspace{1pt}
            \small 123-456-7890 $|$ \href{mailto:jake@su.edu}{\underline{jake@su.edu}}
        \end{center}
        %-----------EXPERIENCE-----------
        \section{Experience}
          \resumeSubHeadingListStart
            \resumeSubheading
              {Research Assistant}{June 2020 -- Present}
              {Texas A\&M University}{College Station, TX}
              \resumeItemListStart
                \resumeItem{Developed a REST API using FastAPI and PostgreSQL}
              \resumeItemListEnd
          \resumeSubHeadingListEnd
        \end{document}
        """#
        let result = ResumeLaTeXImporter.convert(source)
        let lines = result.text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        XCTAssertEqual(lines, ["Jake Ryan", "123-456-7890 | jake@su.edu", "Experience", "Research Assistant | June 2020 -- Present", "Texas A&M University | College Station, TX", "Developed a REST API using FastAPI and PostgreSQL"])
        XCTAssertFalse(result.unsupportedCommands.contains("\\vspace"))
        XCTAssertEqual(ResumeLaTeXImporter.convert(#"\begin{document}a \textbackslash{} b\end{document}"#).text, #"a \ b"#)
    }

    func testElementBindingGivesTheFallbackOnceItsItemIsDeleted() {
        var bullets = [ResumeBullet(text: "First"), ResumeBullet(text: "Second")]
        let list = Binding(get: { bullets }, set: { bullets = $0 })
        let second = list.element(bullets[1].id, or: bullets[1])
        second.wrappedValue.text = "Edited"
        XCTAssertEqual(bullets.map(\.text), ["First", "Edited"])
        bullets.removeLast()
        XCTAssertEqual(second.wrappedValue.text, "Second")
        second.wrappedValue.text = "Stale write"
        XCTAssertEqual(bullets.map(\.text), ["First"])
    }

    func testLatexImporterUnescapesSupportedSymbolsAndReportsUnknownCommands() {
        let result = ResumeLaTeXImporter.convert(#"\begin{document}\section{Skills}\textbf{C\&C++} \mystery{kept}\end{document}"#)
        XCTAssertTrue(result.text.contains("C&C++"))
        XCTAssertTrue(result.unsupportedCommands.contains("\\mystery"))
    }

    func testLaTeXEditorRoundTripRestoresEscapedSymbolsAndHeadings() {
        let draft = "Taylor Example\ntaylor@example.com\nWORK EXPERIENCE\n• Raised retention to 83% for team #2 using snake_case scripts\nSKILLS & ABILITIES\nSwift, Python"
        let restored = ResumeLaTeXFormatter.attributedText(from: ResumeLaTeXFormatter.source(from: ResumeTextFormatter.format(draft)))
        XCTAssertEqual(restored.string.trimmingCharacters(in: .whitespacesAndNewlines), draft)
        let heading = (restored.string as NSString).range(of: "SKILLS & ABILITIES")
        XCTAssertNotEqual(heading.location, NSNotFound)
        XCTAssertNotNil(restored.attribute(.underlineStyle, at: heading.location, effectiveRange: nil))
    }

    func testStructuredRendererOmitsHiddenSectionsAndKeepsLongContent() throws {
        var document = ResumeDocument.empty
        document.sections[0].content = .contact(ContactContent(name: "Taylor Example", email: "taylor@example.com"))
        document.sections.append(ResumeDocumentSection(kind: .summary, title: "Summary", content: .summary(String(repeating: "Visible résumé content. ", count: 900))))
        document.sections.append(ResumeDocumentSection(kind: .custom, title: "Hidden", isVisible: false, content: .custom(CustomContent(paragraphs: ["SECRET_SENTINEL"]))))
        let pdf = try XCTUnwrap(PDFDocument(data: ResumeDocumentRenderer().pdfData(for: document)))
        XCTAssertGreaterThan(pdf.pageCount, 1)
        XCTAssertTrue(pdf.string?.contains("Visible résumé content") == true)
        XCTAssertFalse(pdf.string?.contains("SECRET_SENTINEL") == true)
    }

    func testPDFAndRTFKeepLegacyContentVisibleInBothAppearances() throws {
        let source = NSMutableAttributedString(string: "Taylor Example\nemail@example.com\nSUMMARY\nVisible resume text • résumé\nFINAL SENTINEL")
        source.addAttributes([.foregroundColor: UIColor.label, .backgroundColor: UIColor.black], range: NSRange(location: 0, length: source.length))
        let service = ResumeExportService()

        for style in [UIUserInterfaceStyle.light, .dark] {
            let normalized = ResumeTextFormatter.documentStyle(source)
            XCTAssertEqual(normalized.string, source.string)
            XCTAssertEqual(normalized.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor, nil)
            let pdf = try XCTUnwrap(PDFDocument(data: service.pdfData(for: normalized)))
            XCTAssertEqual(pdf.string?.contains("FINAL SENTINEL"), true, "Missing text in \(style) appearance")
            XCTAssertTrue(visibleInk(in: try XCTUnwrap(pdf.page(at: 0))))
        }

        let resume = Resume(name: "Taylor Example", sections: [ResumeSection(kind: .summary, order: 0, title: "Resume", attributedText: source)])
        let rtf = try ResumeExportService().rtfData(for: resume)
        let restored = try NSAttributedString(data: rtf, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        XCTAssertTrue(restored.string.contains("FINAL SENTINEL"))
        let restoredColor = restored.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertTrue(restoredColor == nil || restoredColor == .black)
    }

    func testLongResumeKeepsSectionOrderAcrossPages() throws {
        let lines = (0..<180).map { "Work line \($0)" }.joined(separator: "\n")
        let text = ResumeTextFormatter.format("Taylor Example\nemail@example.com\nEXPERIENCE\n\(lines)\nFINAL PAGE SENTINEL")
        let document = try XCTUnwrap(PDFDocument(data: ResumeExportService().pdfData(for: text)))
        XCTAssertGreaterThan(document.pageCount, 1)
        XCTAssertTrue(document.string?.hasPrefix("Taylor Example") == true)
        XCTAssertTrue(document.string?.contains("FINAL PAGE SENTINEL") == true)
        for index in 0..<document.pageCount { XCTAssertTrue(visibleInk(in: try XCTUnwrap(document.page(at: index)))) }
    }

    func testEmptyResumeProducesNoPDF() {
        XCTAssertTrue(ResumeExportService().pdfData(for: NSAttributedString(string: " \n ")).isEmpty)
    }

    func testAnalysisUsesUnicodeWhitespaceAndTechnicalWholeTermMatching() {
        XCTAssertEqual(ResumeAnalysisService.normalized("  Résumé\n  Builder  "), "résumé builder")
        XCTAssertNotNil(ResumeAnalysisService.match("Python", in: "Built PYTHON, APIs"))
        XCTAssertNil(ResumeAnalysisService.match("Java", in: "JavaScript"))
        XCTAssertNil(ResumeAnalysisService.match("C", in: "C++ and C#"))
        XCTAssertNotNil(ResumeAnalysisService.match("C++", in: "C++ and C#"))
        XCTAssertNotNil(ResumeAnalysisService.match(".NET", in: "Worked with .NET"))
    }

    func testAnalysisCountsEachRequirementOnceAndSeparatesLibraryEvidence() {
        let requirements = [
            ResumeRequirement(phrase: "Python", sourcePassage: "Python required"),
            ResumeRequirement(phrase: "Python", sourcePassage: "Python required"),
            ResumeRequirement(phrase: "SwiftUI", sourcePassage: "SwiftUI preferred")
        ]
        let snapshot = ResumeAnalysisSnapshot(
            resumeName: "Test",
            attributedResume: NSAttributedString(string: "Python\nSUMMARY\nPython used twice"),
            jobDescription: "Python required. SwiftUI preferred.",
            requirements: requirements,
            workLibrary: [ResumeAnalysisWorkEntry(id: UUID(), role: "Engineer", company: "Example", achievement: "Built SwiftUI tools", includedInResume: false)],
            pageTarget: 1
        )
        let report = ResumeAnalysisService().analyze(snapshot, pdfData: ResumeExportService().pdfData(for: snapshot.attributedResume))
        XCTAssertEqual(report.reviewedCount, 2)
        XCTAssertEqual(report.mentionedCount, 1)
        XCTAssertEqual(report.relatedWork.count, 1)
        XCTAssertFalse(report.relatedWork[0].includedInResume)
    }

    func testLightweightAnalysisUpdatesCoverageWithoutDocumentHealth() {
        let requirement = ResumeRequirement(phrase: "Python", sourcePassage: "Python required")
        let snapshot = ResumeAnalysisSnapshot(
            resumeName: "Test",
            attributedResume: NSAttributedString(string: "Taylor Example\nSUMMARY\nPython"),
            jobDescription: "Python required.",
            requirements: [requirement],
            workLibrary: [ResumeAnalysisWorkEntry(id: UUID(), role: "Engineer", company: "Example", achievement: "Built Python tools", includedInResume: false)],
            pageTarget: 1
        )

        let report = ResumeAnalysisService().analyze(snapshot, includeDocumentHealth: false)

        XCTAssertEqual(report.reviewedCount, 1)
        XCTAssertEqual(report.mentionedCount, 1)
        XCTAssertEqual(report.relatedWork.count, 1)
        XCTAssertTrue(report.healthFindings.isEmpty)
    }

    func testAnalysisShowsNoRequirementsReviewedAndHealthOnlyReport() {
        let report = ResumeAnalysisService().analyze(ResumeAnalysisSnapshot(
            resumeName: "Test",
            attributedResume: NSAttributedString(string: "Taylor Example\nemail@example.com\nSUMMARY\nContent"),
            jobDescription: nil,
            requirements: [],
            workLibrary: [],
            pageTarget: 1
        ))
        XCTAssertEqual(report.reviewedCount, 0)
        XCTAssertEqual(report.mentionedCount, 0)
        XCTAssertTrue(report.healthFindings.contains { $0.title == "Contact information" && $0.kind == .passed })
    }

    func testHealthFindingsCoverSmallTextMissingEmailEmptyHeadingAndRepeatedLines() {
        let repeated = "This is a repeated line with enough words to trigger the duplicate check"
        let source = NSMutableAttributedString(string: "Taylor Example\nSUMMARY\nEXPERIENCE\n\(repeated)\n\(repeated)")
        source.addAttribute(.font, value: UIFont.systemFont(ofSize: 9), range: NSRange(location: 0, length: source.length))
        let report = ResumeAnalysisService().analyze(ResumeAnalysisSnapshot(
            resumeName: "Test",
            attributedResume: source,
            jobDescription: nil,
            requirements: [],
            workLibrary: [],
            pageTarget: 1
        ))
        XCTAssertTrue(report.healthFindings.contains { $0.title == "Text size" && $0.kind == .suggestion })
        XCTAssertTrue(report.healthFindings.contains { $0.title == "Contact information" && $0.kind == .suggestion })
        XCTAssertTrue(report.healthFindings.contains { $0.title == "Empty section: SUMMARY" })
        XCTAssertTrue(report.healthFindings.contains { $0.title == "Repeated content" && $0.kind == .suggestion })
    }

    func testChecklistRoundTripsAndInvalidatesWhenJobDescriptionChanges() throws {
        let checklist = JobRequirementChecklist(description: "Python required", requirements: [ResumeRequirement(phrase: "Python", sourcePassage: "Python required")])
        let restored = try XCTUnwrap(JobRequirementChecklist.load(try checklist.data()))
        XCTAssertEqual(restored.requirements.count, 1)
        XCTAssertFalse(restored.requiresReview(for: "Python required"))
        XCTAssertTrue(restored.requiresReview(for: "Swift required"))
    }

    private func visibleInk(in page: PDFPage) -> Bool {
        let image = page.thumbnail(of: CGSize(width: 612, height: 792), for: .mediaBox)
        guard let cgImage = image.cgImage, let data = cgImage.dataProvider?.data as Data? else { return false }
        let bytes = [UInt8](data)
        let components = cgImage.bitsPerPixel / 8
        guard components >= 3 else { return false }
        var darkPixels = 0
        for index in stride(from: 0, to: bytes.count - components, by: components) {
            let luminance = (Int(bytes[index]) * 299 + Int(bytes[index + 1]) * 587 + Int(bytes[index + 2]) * 114) / 1000
            if luminance < 220 { darkPixels += 1 }
        }
        return darkPixels > 20
    }
}
