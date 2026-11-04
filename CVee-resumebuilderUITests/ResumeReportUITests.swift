import XCTest
import UIKit

/// The resume report: its mascot, match percentage, and AI provider choice.
final class ResumeReportUITests: CVeeUITestCase {
    func testResumeReportShowsMascotAndMatchPercentage() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        generateFixture(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.check-job-match"], in: app))
        XCTAssertTrue(app.navigationBars["Resume report"].waitForExistence(timeout: timeout))
        let mascot = app.descendants(matching: .any)["analysis.mascot"]
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        XCTAssertTrue(mascot.label.contains("Let’s check your match"), mascot.label)
        let match = app.descendants(matching: .any)["analysis.match-percentage"]
        XCTAssertTrue(match.waitForExistence(timeout: timeout))
        XCTAssertTrue(match.label.contains("Not calculated"), match.label)

        let requirement = app.textFields["analysis.new-phrase"]
        XCTAssertTrue(revealHittable(requirement, in: app))
        requirement.tap()
        requirement.typeText("Python\n")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["analysis.add-phrase"], in: app))
        let save = app.buttons["analysis.save-requirements"]
        XCTAssertTrue(revealHittable(save, in: app))
        save.tap()
        let meter = app.descendants(matching: .any)["analysis.match-meter"]
        XCTAssertTrue(reveal(meter, in: app))
        XCTAssertEqual(meter.value as? String, "100%")
        XCTAssertTrue(reveal(mascot, in: app))
        XCTAssertTrue(mascot.label.contains("Your resume matches 100%"), mascot.label)
        XCTAssertTrue(match.label.contains("100%"), match.label)
        XCTAssertEqual(app.staticTexts["analysis.coverage-summary"].label, "1 of 1 reviewed requirements mentioned.")
        capture(app, "report-match-percentage")
    }

    func testResumeReportOffersProviderChoiceWithoutAppleIntelligence() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-apple-intelligence-unavailable"]
        app.launch()
        generateFixture(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.check-job-match"], in: app))
        XCTAssertTrue(app.navigationBars["Resume report"].waitForExistence(timeout: timeout))
        let choose = app.buttons["analysis.configure-provider"]
        XCTAssertTrue(revealHittable(choose, in: app))
        XCTAssertFalse(app.buttons["analysis.suggest-requirements"].exists)
        XCTAssertTrue(app.staticTexts["Apple Intelligence isn’t available right now. Choose OpenAI, Gemini, or Claude to get suggestions."].exists)
        capture(app, "report-choose-provider")
        choose.tap()

        let providerSelector = app.buttons["ai-provider.selector"]
        XCTAssertTrue(providerSelector.waitForExistence(timeout: timeout))
        providerSelector.tap()
        app.buttons["OpenAI"].tap()
        let editKey = app.buttons["ai-provider.edit-key"]
        XCTAssertTrue(editKey.waitForExistence(timeout: timeout))
        editKey.tap()
        let key = app.secureTextFields["ai-provider.api-key"]
        XCTAssertTrue(key.waitForExistence(timeout: timeout))
        key.tap()
        key.typeText("ui-test-key")
        let saveKey = app.buttons["ai-provider.save-key"]
        let saveEnabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: saveKey)
        wait(for: [saveEnabled], timeout: timeout)
        saveKey.tap()
        XCTAssertTrue(app.descendants(matching: .any)["ai-provider.key-saved"].firstMatch.waitForExistence(timeout: timeout))
        app.buttons["analysis.provider-done"].tap()

        // The report resolves its route again: Apple Intelligence is still off, so OpenAI is named.
        let suggest = app.buttons["analysis.suggest-requirements"]
        XCTAssertTrue(revealHittable(suggest, in: app))
        XCTAssertEqual(suggest.label, "Suggest with OpenAI")
        XCTAssertTrue(app.staticTexts["Sends the job description to OpenAI."].exists)
        XCTAssertFalse(app.buttons["analysis.configure-provider"].exists)
    }
}
