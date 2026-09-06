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

    func testSuggestionsUseExplicitLabels() {
        let result = JobCaptureExtractor().suggestions(from: "Job Title: iOS Engineer\nCompany: CVee\nBuild local workflows")
        XCTAssertEqual(result.title, "iOS Engineer")
        XCTAssertEqual(result.company, "CVee")
    }
}
