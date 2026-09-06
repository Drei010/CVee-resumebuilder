import XCTest
@testable import CVee_resumebuilder

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
}
