import XCTest

final class ResumeWizardUITests: XCTestCase {
    func testWizardProgressAndBackNavigation() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()

        app.tabBars.buttons["Resume Wizard"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.progress"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["wizard.start"].exists)

        let next = app.buttons["wizard.next"]
        XCTAssertFalse(next.isEnabled)
        app.textFields["Full name"].tap()
        app.textFields["Full name"].typeText("Test User")
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@example.com")
        XCTAssertTrue(next.isEnabled)
        next.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.work-library"].waitForExistence(timeout: 2))
        app.buttons["wizard.back"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.start"].exists)
    }
}
