import XCTest
@testable import CVee_resumebuilder

@MainActor
final class AIProvidersTests: XCTestCase {
    func testNonAppleProviderSelectionPersists() {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: "ai.provider")
        defer {
            if let previous { defaults.set(previous, forKey: "ai.provider") }
            else { defaults.removeObject(forKey: "ai.provider") }
        }

        let selection = AIProviderSelection()
        selection.setProvider(.gemini)

        XCTAssertEqual(selection.provider(), .gemini)
    }

    func testOpenAIOffersGPT6ModelsWithSolAsDefault() {
        XCTAssertEqual(AIProvider.openAI.models.map(\.id), ["gpt-6-luna", "gpt-6.1-sol", "gpt-6-astra"])
        XCTAssertEqual(AIProvider.openAI.defaultModel.id, "gpt-6.1-sol")
    }

    func testRetiredModelChoiceFallsBackToDefault() {
        let defaults = UserDefaults.standard
        let key = "ai.model.\(AIProvider.openAI.rawValue)"
        let previous = defaults.object(forKey: key)
        defer {
            if let previous { defaults.set(previous, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }

        defaults.set("gpt-5.6-terra", forKey: key)

        XCTAssertEqual(AIProviderSelection().model(for: .openAI).id, "gpt-6.1-sol")
    }
}
