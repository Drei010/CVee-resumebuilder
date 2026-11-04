import XCTest
import UIKit

/// Improve with AI and Enhance with AI on Tasks, with stubbed results.
final class TaskAIUITests: CVeeUITestCase {
    func testAIEnhancementCanBeReviewedAndAccepted() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai"]
        app.launch()

        let original = "Improved the onboarding flow."
        let details = expandTaskCapture(app)
        details.tap()
        details.typeText(original)
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        let confirmationDetails = app.textFields["tasks.record.details"]
        XCTAssertTrue(confirmationDetails.waitForExistence(timeout: timeout))
        confirmationDetails.tap()
        confirmationDetails.typeText(" Edited before review.")
        dismissKeyboard(in: app)
        app.buttons["tasks.record.improve-ai"].tap()

        let originalReview = app.staticTexts["task.ai-review.original"]
        XCTAssertTrue(originalReview.waitForExistence(timeout: timeout))
        XCTAssertTrue(originalReview.label.contains("Edited before review"))
        let useSuggestion = app.buttons["task.ai-review.use"]
        XCTAssertTrue(useSuggestion.waitForExistence(timeout: timeout))
        XCTAssertTrue(useSuggestion.isEnabled)
        useSuggestion.tap()

        let preview = app.textFields["tasks.record.details"]
        XCTAssertTrue(preview.waitForExistence(timeout: timeout))
        XCTAssertTrue((preview.value as? String ?? "").contains("Improved task details for testing"))
        app.buttons["Cancel"].tap()
    }

    func testAIEnhancementFailureKeepsOriginalAvailable() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai-failure"]
        app.launch()

        let original = "Improved the onboarding flow."
        let details = expandTaskCapture(app)
        details.tap()
        details.typeText(original)
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        app.buttons["tasks.record.improve-ai"].tap()

        // A failure shows as the mascot popup: Configure AI provider, then Not now below it.
        let popup = app.descendants(matching: .any)["task.ai-review.error-popup"]
        XCTAssertTrue(popup.waitForExistence(timeout: timeout))
        XCTAssertEqual(app.staticTexts["task.ai-review.error-title"].label, "Couldn’t get an AI suggestion")
        XCTAssertTrue(app.staticTexts["task.ai-review.error"].exists)
        let configure = app.buttons["task.ai-review.error-action"]
        let notNow = app.buttons["task.ai-review.error-dismiss"]
        XCTAssertTrue(configure.exists)
        XCTAssertEqual(notNow.label, "Not now")
        XCTAssertLessThanOrEqual(configure.frame.maxY, notNow.frame.minY)
        capture(app, "tasks-ai-review-error-popup")
        // Not now closes the review and keeps the original details.
        notNow.tap()
        XCTAssertTrue(waitForDisappearance(popup))
        XCTAssertTrue((app.textFields["tasks.record.details"].value as? String ?? "").contains(original))
        app.buttons["Cancel"].tap()
    }

    func testAIEnhancementFailureOpensAIProviderInProfile() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai-failure"]
        app.launch()

        let original = "Improved the onboarding flow."
        let details = expandTaskCapture(app)
        details.tap()
        details.typeText(original)
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        app.buttons["tasks.record.improve-ai"].tap()
        let configure = app.buttons["task.ai-review.error-action"]
        XCTAssertTrue(configure.waitForExistence(timeout: timeout))
        configure.tap()

        // The sheets close and Profile opens on AI Provider; the quick capture draft stays on Tasks.
        XCTAssertTrue(app.navigationBars["AI Provider"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["ai-provider.selector"].waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForDisappearance(app.buttons["tasks.confirm-recording"]))
        capture(app, "tasks-ai-error-opens-ai-provider")
        selectTab("Tasks", in: app)
        let restored = app.textFields["tasks.capture-details"]
        XCTAssertTrue(restored.waitForExistence(timeout: timeout))
        XCTAssertTrue((restored.value as? String ?? "").contains(original))
    }

    func testAIEnhancementEmptyResponseCannotBeApplied() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai-empty"]
        app.launch()

        let details = expandTaskCapture(app)
        details.tap()
        details.typeText("Improved the onboarding flow.")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        app.buttons["tasks.record.improve-ai"].tap()

        let popup = app.descendants(matching: .any)["task.ai-review.error-popup"]
        XCTAssertTrue(popup.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["task.ai-review.error"].exists)
        // On iPad both stacked sheets show a Cancel button, so close the review explicitly first.
        app.buttons["task.ai-review.error-dismiss"].tap()
        XCTAssertTrue(waitForDisappearance(popup))
        XCTAssertFalse(app.buttons["task.ai-review.use"].exists)
        app.buttons["Cancel"].tap()
    }

    func testAIEnhancementReviewWorksInManualEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai"]
        app.launch()
        app.buttons["tasks.actions"].tap()
        let addManually = app.buttons["Add manually"]
        XCTAssertTrue(addManually.waitForExistence(timeout: timeout))
        addManually.tap()

        let details = app.descendants(matching: .any)["task.details"]
        XCTAssertTrue(app.textFields["Job title"].waitForExistence(timeout: timeout))
        XCTAssertTrue(revealBelow(details, in: app))
        details.tap()
        details.typeText("Improved the onboarding flow.")
        dismissKeyboard(in: app)
        app.buttons["task.enhance-ai"].tap()
        // Keep original sits on the left of Use suggestion, as an outlined button of the same width.
        let keep = app.buttons["task.ai-review.keep"]
        let use = app.buttons["task.ai-review.use"]
        XCTAssertTrue(use.waitForExistence(timeout: timeout))
        XCTAssertTrue(keep.exists)
        XCTAssertLessThanOrEqual(keep.frame.maxX, use.frame.minX)
        XCTAssertLessThan(abs(keep.frame.midY - use.frame.midY), 2)
        XCTAssertEqual(keep.frame.width, use.frame.width, accuracy: 1)
        capture(app, "tasks-ai-review-suggestion")
        use.tap()
        XCTAssertTrue((details.value as? String ?? "").contains("Improved task details for testing"))
        app.buttons["task.back"].tap()
    }

    func testAIEnhancementReviewWorksInExistingTaskEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-ai"]
        app.launch()

        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(revealHittable(task, in: app))
        task.tap()
        app.buttons["Edit"].tap()
        let details = app.descendants(matching: .any)["task.detail.details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        app.buttons["task.detail.enhance-ai"].tap()
        XCTAssertTrue(app.buttons["task.ai-review.use"].waitForExistence(timeout: timeout))
        app.buttons["task.ai-review.use"].tap()
        XCTAssertTrue((details.value as? String ?? "").contains("Improved task details for testing"))
        app.buttons["Cancel"].tap()
        app.buttons["Done"].tap()
    }
}
