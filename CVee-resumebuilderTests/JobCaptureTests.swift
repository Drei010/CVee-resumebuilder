import XCTest
@testable import CVee_resumebuilder

final class JobCaptureTests: XCTestCase {
    func testDuplicateNormalizationDropsTrackingOnly() {
        let first = JobTargetDuplicateDetector.normalizedURL("HTTPS://Example.com:443/jobs/42?utm_source=share&ref=mobile#details")
        let second = JobTargetDuplicateDetector.normalizedURL("https://example.com/jobs/42?ref=mobile")
        XCTAssertEqual(first, second)
    }

    func testCaptureRequiresDescriptionOrValidURL() {
        var draft = JobCaptureDraft()
        XCTAssertFalse(draft.hasContent)
        draft.sourceURL = "https://example.com/jobs/42"
        XCTAssertTrue(draft.hasContent)
        draft.sourceURL = "example.com/jobs/42"
        XCTAssertFalse(draft.hasContent)
    }

    func testJobLinkAddsHTTPSAndRefusesTextThatIsNotAWebAddress() {
        XCTAssertEqual(URL(jobLink: " linkedin.com/jobs/view/123 ")?.absoluteString, "https://linkedin.com/jobs/view/123")
        XCTAssertEqual(URL(jobLink: "http://example.com/jobs/1")?.absoluteString, "http://example.com/jobs/1")
        XCTAssertNil(URL(jobLink: "Barista job"))
        XCTAssertNil(URL(jobLink: "ftp://example.com/jobs/1"))
    }

    func testFetchedPageDecodesEntitiesAndKeepsApostrophesInTitles() {
        let html = #"<html><head><meta property="og:title" content="Barista at Joe's Coffee &amp; Tea"></head><body><p>We&#39;re hiring &ndash; apply&nbsp;now &#x2019;</p></body></html>"#
        XCTAssertEqual(JobDescriptionFetcher.metadata("og:title", in: html), "Barista at Joe's Coffee & Tea")
        XCTAssertEqual(JobDescriptionFetcher.visibleText(from: html), "We're hiring – apply now ’")
    }

    func testWordDocumentTextIsRead() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TaskImportSample", withExtension: "docx"))
        XCTAssertEqual(try TaskDocumentReader().read(url), "Led the migration to SwiftUI.\nCut build times by 40%.")
    }

    func testSuggestionsUseExplicitLabels() {
        let result = JobCaptureExtractor().suggestions(from: "Job Title: iOS Engineer\nCompany: CVee\nBuild local workflows")
        XCTAssertEqual(result.title, "iOS Engineer")
        XCTAssertEqual(result.company, "CVee")
    }
}
