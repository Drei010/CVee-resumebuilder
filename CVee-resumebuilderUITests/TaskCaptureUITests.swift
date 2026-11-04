import XCTest
import UIKit

/// Tasks quick capture: the collapsed card, recording a task, and its draft.
final class TaskCaptureUITests: CVeeUITestCase {
    func testTaskCaptureCardValidationAndRecording() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let details = expandTaskCapture(app)
        let record = app.buttons["tasks.record"]
        XCTAssertTrue(record.waitForExistence(timeout: timeout))
        XCTAssertFalse(record.isEnabled)

        details.tap()
        details.typeText("Improved the onboarding flow.")
        dismissKeyboard(in: app)

        XCTAssertTrue(record.isEnabled)
        XCTAssertTrue(tapWhenHittable(record, in: app))
        XCTAssertTrue(app.buttons["tasks.record.improve-ai"].waitForExistence(timeout: timeout))
        if app.frame.width > 700 {
            XCTAssertTrue(app.buttons["tasks.confirm-company"].waitForExistence(timeout: timeout))
            app.buttons["Cancel"].tap()
            return
        }
        // The sheet opens at full height, with no grabber to drag, and Confirm recording spans its bar.
        let recordBar = app.navigationBars["Record task"]
        XCTAssertLessThan(recordBar.frame.minY, app.frame.height * 0.2, "The record sheet reaches the top")
        XCTAssertFalse(app.buttons["Sheet Grabber"].exists)
        let confirm = app.buttons["tasks.confirm-recording"]
        XCTAssertEqual(confirm.frame.width, recordBar.frame.width - 32, accuracy: 2, "Confirm recording spans the sheet")
        capture(app, "tasks-record-sheet")
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.confirm-company"], in: app))
        XCTAssertTrue(app.buttons["New company"].waitForExistence(timeout: timeout))
        app.buttons["New company"].tap()
        let company = app.textFields["tasks.confirm-company-name"]
        XCTAssertTrue(company.waitForExistence(timeout: timeout))
        company.tap()
        company.typeText("Example Studio")
        XCTAssertTrue(app.buttons["Confirm recording"].isHittable)
        dismissKeyboard(in: app)
        let role = app.textFields["tasks.confirm-role"]
        XCTAssertTrue(role.waitForExistence(timeout: timeout))
        role.tap()
        role.typeText("Product Designer")
        dismissKeyboard(in: app)
        app.buttons["Confirm recording"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["tasks.mascot"].waitForExistence(timeout: timeout))
        // Recording folds the recorder back into the action card.
        XCTAssertTrue(app.buttons["tasks.capture-card"].waitForExistence(timeout: timeout))
        XCTAssertTrue(revealHittable(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Product Designer'")).firstMatch, in: app))
    }

    func testCaptureAndConfirmationDetailsRemainEditable() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let details = expandTaskCapture(app)
        details.tap()
        details.typeText("Captured the first version of this achievement.")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))

        let confirmationDetails = app.textFields["tasks.record.details"]
        XCTAssertTrue(confirmationDetails.waitForExistence(timeout: timeout))
        confirmationDetails.tap()
        confirmationDetails.typeText(" Added context.")
        dismissKeyboard(in: app)
        XCTAssertTrue((confirmationDetails.value as? String ?? "").contains("Added context"))
        XCTAssertTrue(app.buttons["Confirm recording"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue((details.value as? String ?? "").contains("Added context"))

        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        XCTAssertTrue((app.textFields["tasks.record.details"].value as? String ?? "").contains("Added context"))
        app.buttons["Cancel"].tap()
    }

    func testCaptureFieldAcceptsLongMultilineContent() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let details = expandTaskCapture(app)
        details.tap()
        details.typeText("A long achievement description with enough words to wrap across multiple lines and exercise the growing capture field before its internal scrolling limit is reached.")
        XCTAssertTrue((details.value as? String ?? "").contains("internal scrolling limit"))
        XCTAssertTrue(app.buttons["tasks.record"].isEnabled)
        capture(app, "tasks-capture-multiline")
    }

    func testTypedRoleSurvivesNewCompanySelection() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        let details = expandTaskCapture(app)
        details.tap()
        details.typeText("Documented a new design decision.")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))

        let role = app.textFields["tasks.confirm-role"]
        XCTAssertTrue(role.waitForExistence(timeout: timeout))
        let seededRole = role.value as? String
        if app.frame.width > 700 {
            XCTAssertEqual(role.value as? String, seededRole)
            app.buttons["Cancel"].tap()
            return
        }
        app.buttons["tasks.confirm-company"].tap()
        app.buttons["New company"].tap()
        XCTAssertEqual(role.value as? String, seededRole)
        app.buttons["Cancel"].tap()
    }

    func testQuickCaptureDraftRestoresAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let draft = "Unfinished task draft to restore."
        let details = expandTaskCapture(app)
        details.tap()
        details.typeText(draft)
        dismissKeyboard(in: app)
        app.terminate()

        app.launchArguments = ["-ui-testing", "-ui-testing-preserve-drafts"]
        app.launch()
        // A restored draft opens the recorder on launch, without a tap on the action card.
        let restored = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(restored.waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["tasks.capture-card"].exists)
        XCTAssertEqual((restored.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), draft)

        // With a draft, Task actions still holds only Add manually and Import tasks: no Discard draft.
        app.buttons["tasks.actions"].tap()
        XCTAssertTrue(app.buttons["tasks.add-manually"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["tasks.import"].exists)
        XCTAssertFalse(app.buttons["tasks.discard-draft"].exists)
        XCTAssertFalse(app.buttons["Discard draft"].exists)
        capture(app, "tasks-actions-menu-with-draft")
    }

    func testTaskCaptureCardStartsCollapsedAndExpands() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let card = app.buttons["tasks.capture-card"]
        let details = app.textFields["tasks.capture-details"]
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.isHittable)
        XCTAssertFalse(details.exists)
        XCTAssertTrue(app.descendants(matching: .any)["tasks.first-use-guidance"].exists)
        capture(app, "tasks-capture-collapsed")

        // Tap where the leaning mascot overlaps the card: the dog must not swallow the tap. 8 points
        // below the card's top edge stays inside MascotMetrics.leaningOverlap (22 points).
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0)).withOffset(CGVector(dx: 0, dy: 8)).tap()
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        let collapse = app.buttons["tasks.capture-collapse"]
        XCTAssertTrue(collapse.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForDisappearance(card))
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: details)
        XCTAssertEqual(XCTWaiter.wait(for: [focused], timeout: timeout), .completed)
        capture(app, "tasks-capture-expanded")

        XCTAssertTrue(revealHittable(collapse, in: app))
        collapse.tap()
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForDisappearance(details))
        XCTAssertFalse(collapse.exists)
    }
}
