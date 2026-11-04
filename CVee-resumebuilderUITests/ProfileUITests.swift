import XCTest
import UIKit

/// Profile details and the AI Provider settings.
final class ProfileUITests: CVeeUITestCase {
    func testAIProviderSelectionAndModelConfiguration() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        selectTab("Profile", in: app)
        let providerLink = app.buttons["profile.ai-provider"]
        XCTAssertTrue(revealHittable(providerLink, in: app))
        providerLink.tap()
        XCTAssertTrue(app.navigationBars["AI Provider"].waitForExistence(timeout: timeout))
        let providerSelector = app.buttons["ai-provider.selector"]
        XCTAssertTrue(providerSelector.waitForExistence(timeout: timeout))
        providerSelector.tap()
        app.buttons["OpenAI"].tap()
        let model = app.buttons["ai-provider.model"]
        XCTAssertTrue(model.waitForExistence(timeout: timeout))
        // OpenAI offers the GPT-6 models. GPT-6.1 Sol, the default, also shows on the row, so pick Luna.
        model.tap()
        let luna = app.buttons["GPT-6 Luna"]
        XCTAssertTrue(luna.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["GPT-6.1 Sol"].exists)
        XCTAssertTrue(app.buttons["GPT-6 Astra"].exists)
        luna.tap()
        app.buttons["ai-provider.edit-key"].tap()
        let key = app.secureTextFields["ai-provider.api-key"]
        XCTAssertTrue(key.waitForExistence(timeout: timeout))
        let saveKey = app.buttons["ai-provider.save-key"]
        // A button that fills a Form row reports the whole row as its frame, wider than the inset field.
        XCTAssertGreaterThanOrEqual(saveKey.frame.width, key.frame.width - 8, "Save spans the API key row")
        key.tap()
        key.typeText("ui-test-key")
        let saveEnabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: saveKey)
        wait(for: [saveEnabled], timeout: timeout)
        saveKey.tap()
        let saved = app.descendants(matching: .any)["ai-provider.key-saved"].firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: timeout))
        // With a key saved, editing it is a pencil at the end of the "API key saved" row.
        let editKey = app.buttons["ai-provider.edit-key"]
        XCTAssertLessThan(abs(editKey.frame.midY - saved.frame.midY), 12, "The pencil sits on the API key saved row")
        XCTAssertGreaterThan(editKey.frame.minX, saved.frame.maxX)
        editKey.tap()
        XCTAssertTrue(app.buttons["ai-provider.save-key"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Save"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["ai-provider.key-saved"].waitForExistence(timeout: timeout))
        app.buttons["ai-provider.edit-key"].tap()
        app.buttons["ai-provider.remove-key"].tap()
        app.buttons.matching(identifier: "Delete API key").element(boundBy: 0).tap()
    }

    func testProfileDetailsStackLabelsAndSaveChanges() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        selectTab("Profile", in: app)
        let nameRow = app.descendants(matching: .any)["profile.detail.name"].firstMatch
        XCTAssertTrue(nameRow.waitForExistence(timeout: timeout))
        XCTAssertTrue(nameRow.label.contains("Full name") && nameRow.label.contains("Not set"), nameRow.label)
        let update = app.buttons["Update personal info"]
        XCTAssertTrue(revealHittable(update, in: app))
        update.tap()

        // Labels sit above the fields, so each field starts at its label's leading edge, below it.
        let name = app.textFields["Full name"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        let fieldFrame = name.frame
        let nameLabel = app.staticTexts["Full name"].firstMatch
        XCTAssertTrue(nameLabel.exists)
        XCTAssertLessThan(abs(nameLabel.frame.minX - fieldFrame.minX), 8, "Fields start below their labels, not beside them")
        XCTAssertLessThanOrEqual(nameLabel.frame.maxY, fieldFrame.minY + 2, "The label sits above its field")
        name.tap()
        name.typeText("Test User")
        dismissKeyboard(in: app)
        let save = app.buttons["profile.save"]
        XCTAssertTrue(revealHittable(save, in: app))
        // A button that fills a Form row reports the whole row as its frame, wider than the inset field.
        XCTAssertGreaterThanOrEqual(save.frame.width, fieldFrame.width - 8, "Save changes spans the row")
        save.tap()
        XCTAssertTrue(app.alerts["Personal info updated"].waitForExistence(timeout: timeout))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(nameRow.waitForExistence(timeout: timeout))
        XCTAssertTrue(nameRow.label.contains("Test User"), nameRow.label)
    }
}
