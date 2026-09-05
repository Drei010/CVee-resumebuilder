import XCTest

final class ResumeWizardUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    func testWizardProgressAndBackNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let wizardTab = app.buttons["Resume Wizard"].firstMatch
        XCTAssertTrue(wizardTab.waitForExistence(timeout: timeout))
        XCTAssertTrue(wizardTab.isHittable)
        wizardTab.tap()

        XCTAssertTrue(app.descendants(matching: .any)["wizard.progress"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.descendants(matching: .any)["wizard.start"].waitForExistence(timeout: timeout))

        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: timeout))
        XCTAssertFalse(next.isEnabled)
        let fullName = app.textFields["wizard.full-name"]
        XCTAssertTrue(fullName.waitForExistence(timeout: timeout))
        XCTAssertTrue(fullName.isHittable)
        fullName.tap()
        fullName.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 64))
        fullName.typeText("Test User")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(email.waitForExistence(timeout: timeout))
        XCTAssertTrue(email.isHittable)
        email.tap()
        email.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 64))
        email.typeText("test@example.com")
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: next)
        wait(for: [enabled], timeout: timeout)
        next.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.work-library"].waitForExistence(timeout: timeout))
        let back = app.buttons["wizard.back"]
        XCTAssertTrue(back.waitForExistence(timeout: timeout))
        back.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.start"].waitForExistence(timeout: timeout))
    }

    func testGeneratedResumePreviewSaveReopenAndExport() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        app.buttons["Resume Wizard"].firstMatch.tap()
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(email.waitForExistence(timeout: timeout))
        email.tap()
        email.typeText("test@example.com")
        app.buttons["wizard.next"].tap()

        XCTAssertTrue(app.buttons["wizard.select-all"].waitForExistence(timeout: timeout))
        app.buttons["wizard.select-all"].tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout))
        app.buttons["wizard.clear-selection"].tap()
        XCTAssertTrue(app.staticTexts["0 selected"].waitForExistence(timeout: timeout))
        app.buttons["wizard.select-all"].tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout))
        app.buttons["wizard.next"].tap()

        let job = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Full Stack AI Developer'"))
        XCTAssertTrue(job.firstMatch.waitForExistence(timeout: timeout))
        job.firstMatch.tap()
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.buttons["wizard.generate"].waitForExistence(timeout: timeout))
        app.buttons["wizard.generate"].tap()

        XCTAssertTrue(app.otherElements["wizard.generated.pdf"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["wizard.save-resume"].waitForExistence(timeout: timeout))
        app.buttons["wizard.edit-resume"].tap()
        XCTAssertTrue(app.buttons["wizard.latex-mode"].waitForExistence(timeout: timeout))
        app.buttons["wizard.latex-mode"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.latex-editor"].waitForExistence(timeout: timeout))
        app.buttons["wizard.edit-resume"].tap()
        app.buttons["wizard.save-resume"].tap()

        let resumesTab = app.buttons["Resumes"].firstMatch
        XCTAssertTrue(resumesTab.waitForExistence(timeout: timeout))
        resumesTab.tap()
        let savedResume = app.buttons["resume.saved-row"]
        XCTAssertTrue(savedResume.waitForExistence(timeout: timeout))
        savedResume.tap()
        let latexOption = app.buttons["LaTeX"]
        XCTAssertTrue(latexOption.waitForExistence(timeout: timeout))
        latexOption.tap()
        XCTAssertTrue(app.descendants(matching: .any)["resume.latex-editor"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resume.export"].waitForExistence(timeout: timeout))
        app.buttons["resume.export"].tap()
        XCTAssertTrue(app.buttons["resume.export-pdf"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resume.export-rtf"].waitForExistence(timeout: timeout))
    }
}
