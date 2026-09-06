import XCTest
import PDFKit
import UIKit
@testable import CVee_resumebuilder

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

    func testLatexImporterUnescapesSupportedSymbolsAndReportsUnknownCommands() {
        let result = ResumeLaTeXImporter.convert(#"\begin{document}\section{Skills}\textbf{C\&C++} \mystery{kept}\end{document}"#)
        XCTAssertTrue(result.text.contains("C&C++"))
        XCTAssertTrue(result.unsupportedCommands.contains("\\mystery"))
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
