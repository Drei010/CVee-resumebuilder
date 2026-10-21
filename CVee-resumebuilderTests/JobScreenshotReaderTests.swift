import XCTest
import UIKit
@testable import CVee_resumebuilder

@MainActor
final class JobScreenshotReaderTests: XCTestCase {
    private let linkedInText = """
        Senior iOS Engineer
        Grab
        Taguig, Philippines · On-site · Full-time

        Grab is Southeast Asia's leading superapp. We are looking for a Senior iOS Engineer to help millions of people get around, order food, and pay every day.

        What you will do:
        • Build and ship features in Swift and SwiftUI for the Grab app used across eight countries.
        • Work with designers and product managers to plan, test, and release new experiences.
        • Review code and mentor engineers on testing, performance, and accessibility.

        Requirements
        • 5+ years of experience building iOS apps in Swift.
        • Strong knowledge of UIKit, SwiftUI, and concurrency.

        We offer flexible hybrid work, health coverage for you and your family, and a yearly learning budget.
        """

    func testLinkedInScreenshotsBecomeOneDescription() {
        let post = FakeJobPost.linkedIn()
        for offsets: [CGFloat] in [[0, 320, 560], [0, 600]] {
            let result = JobScreenshotReader().read(pages: post.screenshots(scrolledTo: offsets))
            XCTAssertTrue(result.isLinkedIn)
            XCTAssertEqual(result.title, "Senior iOS Engineer")
            XCTAssertEqual(result.company, "Grab")
            XCTAssertFalse(result.isTruncated)
            // Overlapping lines appear once, wrapped lines are rejoined, and LinkedIn's bars, buttons, and later sections are gone.
            XCTAssertEqual(result.text, linkedInText, "Scrolled to \(offsets)")
        }
    }

    func testScreenshotsChosenOutOfOrderOrTwiceReadTheSame() {
        let pages = FakeJobPost.linkedIn().screenshots(scrolledTo: [0, 320, 560])
        XCTAssertEqual(JobScreenshotReader().read(pages: [pages[2], pages[0], pages[1]]).text, linkedInText)
        XCTAssertEqual(JobScreenshotReader().read(pages: [pages[0], pages[0], pages[1], pages[2]]).text, linkedInText)
    }

    func testCollapsedLinkedInDescriptionIsFlaggedAsCutShort() {
        let result = JobScreenshotReader().read(pages: FakeJobPost.linkedIn(collapsed: true).screenshots(scrolledTo: [0, 400]))
        XCTAssertTrue(result.isTruncated)
        XCTAssertEqual(result.text, """
            Senior iOS Engineer
            Grab
            Taguig, Philippines · On-site · Full-time

            Grab is Southeast Asia's leading superapp. We are looking for a Senior iOS Engineer to help millions of people get around, order food, and pay every day.

            What you will do:
            """)
    }

    func testOlderLinkedInLayoutNamesTheCompanyBesideTheLocation() {
        var post = FakeJobPost()
        post.line("Senior iOS Engineer", size: 24)
        post.line("Grab · Taguig, Philippines (On-site)", size: 14)
        post.line("2 days ago · 45 applicants", size: 13)
        post.row([("Easy Apply", 40), ("Save", 230)], size: 16, gap: 16)
        post.line("About the job", size: 20, gap: 8)
        post.paragraph("We are looking for a Senior iOS Engineer to build the Grab app with a small, friendly team.")
        let result = JobScreenshotReader().read(pages: post.screenshots(scrolledTo: [0]))
        XCTAssertEqual(result.title, "Senior iOS Engineer")
        XCTAssertEqual(result.company, "Grab")
        XCTAssertEqual(result.text, "Senior iOS Engineer\nGrab\n\nWe are looking for a Senior iOS Engineer to build the Grab app with a small, friendly team.")
    }

    func testOtherScreenshotsKeepTheirTextWithoutTheStatusBar() {
        var post = FakeJobPost(bars: FakeJobPost.statusBar)
        post.line("iOS Developer", size: 22)
        post.line("Acme Corp · Remote", size: 14, gap: 16)
        post.paragraph("Acme builds tools for small shops. You will own our iPhone app from design review to release, working closely with a small team.")
        post.paragraph("Apply with your resume and two apps you are proud of.")
        let result = JobScreenshotReader().read(pages: post.screenshots(scrolledTo: [0]))
        XCTAssertFalse(result.isLinkedIn)
        XCTAssertNil(result.title)
        XCTAssertEqual(result.text, "iOS Developer\n\nAcme Corp · Remote\n\nAcme builds tools for small shops. You will own our iPhone app from design review to release, working closely with a small team.\n\nApply with your resume and two apps you are proud of.")
    }

    /// The whole path on real pixels: PNG screenshots, Vision OCR, then the reader.
    func testRenderedLinkedInScreenshotsAreReadWithVision() async throws {
        let post = FakeJobPost.linkedIn(measure: FakeJobPost.renderedWidth)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        var urls: [URL] = []
        for (index, image) in post.images(scrolledTo: [0, 560]).enumerated() {
            let url = folder.appendingPathComponent("Screenshot \(index + 1).png")
            try XCTUnwrap(image.pngData()).write(to: url)
            urls.append(url)
        }
        let result = try await JobCaptureExtractor().extract(urls: urls)
        XCTAssertTrue(result.isLinkedIn, result.text)
        XCTAssertEqual(result.title, "Senior iOS Engineer", result.text)
        XCTAssertEqual(result.company, "Grab", result.text)
        for phrase in ["help millions of people get around", "release new experiences", "health coverage for you and your family"] {
            XCTAssertEqual(result.text.components(separatedBy: phrase).count, 2, "'\(phrase)' should appear once in:\n\(result.text)")
        }
        for chrome in ["Easy Apply", "Notifications", "followers", "9:41", "Show less", "About the company"] {
            XCTAssertFalse(result.text.contains(chrome), "'\(chrome)' should be left out of:\n\(result.text)")
        }
    }
}

/// A job post laid out as one tall page in points, then cut into iPhone screenshots that overlap as you scroll. Each
/// screenshot also shows the bars, which stay put; a line half hidden by a bar reads as noise, as it would from OCR.
@MainActor
private struct FakeJobPost {
    struct Line {
        let text: String
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
    }

    static let screen = CGSize(width: 393, height: 852)
    static let contentTop: CGFloat = 100
    static let contentBottom: CGFloat = 780
    nonisolated static let statusBar = [Line(text: "9:41", x: 32, y: 16, size: 17), Line(text: "5G", x: 300, y: 18, size: 13), Line(text: "85", x: 350, y: 18, size: 12)]
    nonisolated static let linkedInBars = statusBar + [
        Line(text: "‹", x: 16, y: 60, size: 22), Line(text: "Search", x: 60, y: 62, size: 17),
        Line(text: "Home", x: 16, y: 808, size: 10), Line(text: "Video", x: 92, y: 808, size: 10), Line(text: "My Network", x: 150, y: 808, size: 10),
        Line(text: "Notifications", x: 228, y: 808, size: 10), Line(text: "3", x: 262, y: 794, size: 9), Line(text: "Jobs", x: 340, y: 808, size: 10),
    ]
    /// Text widths for laid-out tests: an average glyph half as wide as the font size.
    nonisolated static let estimatedWidth: @Sendable (String, CGFloat) -> CGFloat = { text, size in CGFloat(text.count) * size * 0.5 }
    static let renderedWidth: (String, CGFloat) -> CGFloat = { text, size in (text as NSString).size(withAttributes: [.font: FakeJobPost.font(size)]).width }

    let bars: [Line]
    let measure: (String, CGFloat) -> CGFloat
    private(set) var lines: [Line] = []
    private var y: CGFloat = 110

    init(bars: [Line] = FakeJobPost.linkedInBars, measure: @escaping (String, CGFloat) -> CGFloat = FakeJobPost.estimatedWidth) {
        self.bars = bars
        self.measure = measure
    }

    static func font(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: size >= 20 ? .bold : .regular) }

    static func linkedIn(collapsed: Bool = false, measure: @escaping (String, CGFloat) -> CGFloat = FakeJobPost.estimatedWidth) -> FakeJobPost {
        var post = FakeJobPost(measure: measure)
        post.line("Grab", size: 14, x: 60)
        post.line("Senior iOS Engineer", size: 24)
        post.line("Taguig, Philippines · 2 days ago · Over 100 applicants", size: 13)
        post.line("Promoted by hirer · Actively reviewing applicants", size: 13)
        post.row([("On-site", 16), ("Full-time", 110)], size: 13)
        post.row([("Easy Apply", 40), ("Save", 230)], size: 16, gap: 16)
        post.line("Meet the hiring team", size: 20)
        post.line("Maria Santos", x: 70, gap: 2)
        post.line("Talent Acquisition · Job poster", size: 13, x: 70)
        post.line("Message", gap: 18)
        post.line("About the job", size: 20, gap: 8)
        post.paragraph("Grab is Southeast Asia's leading superapp. We are looking for a Senior iOS Engineer to help millions of people get around, order food, and pay every day.")
        post.paragraph("What you will do:", gap: 4)
        if collapsed {
            post.line("Show more", gap: 18)
            post.line("Set alert for similar jobs", size: 17, gap: 18)
        } else {
            post.paragraph("• Build and ship features in Swift and SwiftUI for the Grab app used across eight countries.", gap: 4)
            post.paragraph("• Work with designers and product managers to plan, test, and release new experiences.", gap: 4)
            post.paragraph("• Review code and mentor engineers on testing, performance, and accessibility.")
            post.paragraph("Requirements", gap: 4)
            post.paragraph("• 5+ years of experience building iOS apps in Swift.", gap: 4)
            post.paragraph("• Strong knowledge of UIKit, SwiftUI, and concurrency.")
            post.paragraph("We offer flexible hybrid work, health coverage for you and your family, and a yearly learning budget.")
            post.line("Show less", gap: 18)
        }
        post.line("About the company", size: 20, gap: 8)
        post.line("Grab", gap: 2)
        post.line("1,234,567 followers", size: 13)
        post.line("Follow", gap: 8)
        post.line("Software Development · 10,001+ employees", size: 13)
        return post
    }

    mutating func line(_ text: String, size: CGFloat = 15, x: CGFloat = 16, gap: CGFloat = 4) {
        lines.append(Line(text: text, x: x, y: y, size: size))
        y += size * 1.35 + gap
    }

    /// Pieces of text side by side, such as chips or buttons.
    mutating func row(_ parts: [(String, CGFloat)], size: CGFloat, gap: CGFloat = 8) {
        for (text, x) in parts { lines.append(Line(text: text, x: x, y: y, size: size)) }
        y += size * 1.35 + gap
    }

    /// Wraps 15-point text to the column, 16 points from each edge; a list item's wrapped lines hang under its text.
    mutating func paragraph(_ text: String, gap: CGFloat = 18) {
        var current = ""
        var x: CGFloat = 16
        for word in text.split(separator: " ").map(String.init) {
            let candidate = current.isEmpty ? word : current + " " + word
            if !current.isEmpty, measure(candidate, 15) > Self.screen.width - 16 - x {
                line(current, x: x, gap: 0)
                current = word
                if text.hasPrefix("• ") { x = 30 }
            } else {
                current = candidate
            }
        }
        line(current, x: x, gap: gap)
    }

    func screenshots(scrolledTo offsets: [CGFloat]) -> [[ScreenshotTextLine]] {
        offsets.map { offset in
            let content = lines.compactMap { line -> ScreenshotTextLine? in
                let top = line.y - offset
                let bottom = top + line.size * 1.2
                guard bottom > Self.contentTop, top < Self.contentBottom else { return nil }
                let isCut = top < Self.contentTop || bottom > Self.contentBottom
                return textLine(isCut ? String(line.text.prefix(line.text.count / 2)) + " ~" : line.text, x: line.x, y: top, size: line.size)
            }
            return content + bars.map { textLine($0.text, x: $0.x, y: $0.y, size: $0.size) }
        }
    }

    func images(scrolledTo offsets: [CGFloat]) -> [UIImage] {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let renderer = UIGraphicsImageRenderer(size: Self.screen, format: format)
        return offsets.map { offset in
            renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: Self.screen))
                for line in lines { draw(line, down: -offset) }
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: Self.screen.width, height: Self.contentTop))
                context.fill(CGRect(x: 0, y: Self.contentBottom, width: Self.screen.width, height: Self.screen.height - Self.contentBottom))
                for bar in bars { draw(bar, down: 0) }
            }
        }
    }

    private func draw(_ line: Line, down offset: CGFloat) {
        (line.text as NSString).draw(at: CGPoint(x: line.x, y: line.y + offset), withAttributes: [.font: Self.font(line.size), .foregroundColor: UIColor.black])
    }

    private func textLine(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat) -> ScreenshotTextLine {
        ScreenshotTextLine(text: text, frame: CGRect(x: x / Self.screen.width, y: y / Self.screen.height, width: measure(text, size) / Self.screen.width, height: size * 1.2 / Self.screen.height))
    }
}
