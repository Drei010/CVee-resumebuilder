import XCTest
import PDFKit
import UIKit
@testable import CVee_resumebuilder

final class ResumeRenderingTests: XCTestCase {
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
