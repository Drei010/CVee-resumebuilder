import XCTest
@testable import CVee_resumebuilder

final class ResumeReportTests: XCTestCase {
    private func report(resume: String, phrases: [String]) -> ResumeAnalysisReport {
        let snapshot = ResumeAnalysisSnapshot(
            resumeName: "Test",
            attributedResume: NSAttributedString(string: resume),
            jobDescription: phrases.joined(separator: ", "),
            requirements: phrases.map { ResumeRequirement(phrase: $0, sourcePassage: $0) },
            workLibrary: [],
            pageTarget: 1
        )
        return ResumeAnalysisService().analyze(snapshot, includeDocumentHealth: false)
    }

    func testMatchPercentageIsNilWithoutConfirmedPhrases() {
        XCTAssertNil(report(resume: "Python", phrases: []).matchPercentage)
    }

    func testMatchPercentageRoundsToWholePercent() {
        XCTAssertEqual(report(resume: "Python", phrases: ["Python"]).matchPercentage, 100)
        XCTAssertEqual(report(resume: "Go", phrases: ["Python"]).matchPercentage, 0)
        XCTAssertEqual(report(resume: "Python Swift", phrases: ["Python", "Swift", "Rust"]).matchPercentage, 67)
        XCTAssertEqual(report(resume: "Python", phrases: ["Python", "Swift", "Rust"]).matchPercentage, 33)
        XCTAssertEqual(report(resume: "Python", phrases: ["Python", "Swift", "Rust", "Go", "Kotlin", "Java", "Ruby", "Perl"]).matchPercentage, 13)
    }

    func testRoutePrefersAppleIntelligenceWhenReady() {
        XCTAssertEqual(AnalysisSuggestionRoute.resolve(appleIntelligenceReady: true, selectedProvider: .openAI, hasKey: { _ in true }), .onDevice)
        XCTAssertEqual(AnalysisSuggestionRoute.resolve(appleIntelligenceReady: true, selectedProvider: nil, hasKey: { _ in false }), .onDevice)
    }

    func testRouteFallsBackToSelectedRemoteProviderWithKey() {
        XCTAssertEqual(AnalysisSuggestionRoute.resolve(appleIntelligenceReady: false, selectedProvider: .gemini, hasKey: { $0 == .gemini }), .remote(.gemini))
        XCTAssertEqual(AnalysisSuggestionRoute.remote(.claude).providerName, "Claude")
    }

    func testRouteIsNoneWithoutAnUsableProvider() {
        XCTAssertEqual(AnalysisSuggestionRoute.resolve(appleIntelligenceReady: false, selectedProvider: .apple, hasKey: { _ in true }), .none)
        XCTAssertEqual(AnalysisSuggestionRoute.resolve(appleIntelligenceReady: false, selectedProvider: .openAI, hasKey: { _ in false }), .none)
        XCTAssertEqual(AnalysisSuggestionRoute.resolve(appleIntelligenceReady: false, selectedProvider: nil, hasKey: { _ in true }), .none)
        XCTAssertNil(AnalysisSuggestionRoute.none.providerName)
    }

    func testRequirementSuggestionsParseFencedJSONAndKeepOnlyVerbatimQuotes() throws {
        let description = "We need Python experience. SwiftUI is a plus."
        let response = """
        Here are the requirements:
        ```json
        [{"phrase": "Python", "sourcePassage": "We need Python experience."},
         {"phrase": "Kubernetes", "sourcePassage": "Kubernetes clusters at scale"}]
        ```
        """
        let values = try AnalysisSuggestionService.requirements(in: response, description: description)
        XCTAssertEqual(values.map(\.phrase), ["Python"])
    }

    func testEvidenceSuggestionsKeepOnlyQuotesFromTheirPassage() throws {
        let passages = ["Built SwiftUI tools", "Led a Python migration"]
        let response = #"[{"passageID": 1, "quotation": "Python migration"}, {"passageID": 0, "quotation": "Python migration"}, {"passageID": 5, "quotation": "Built"}]"#
        let values = try AnalysisSuggestionService.evidence(in: response, passages: passages)
        XCTAssertEqual(values.map(\.passageID), [1])
    }

    func testInvalidSuggestionResponsesThrowDecodingErrors() {
        XCTAssertNil(AnalysisSuggestionService.jsonArray(in: "No requirements found."))
        XCTAssertThrowsError(try AnalysisSuggestionService.requirements(in: "Sorry, I can’t help with that.", description: "Python"))
        XCTAssertThrowsError(try AnalysisSuggestionService.evidence(in: "[not json]", passages: ["Python"]))
    }
}
