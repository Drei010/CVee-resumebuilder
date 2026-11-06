import XCTest
import UIKit

/// Resume Wizard steps, navigation, guidance, and job selection.
final class ResumeWizardUITests: CVeeUITestCase {
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
        let mascot = app.descendants(matching: .any)["wizard.mascot"]
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        let fullName = app.textFields["wizard.full-name"]
        XCTAssertTrue(fullName.waitForExistence(timeout: timeout))
        XCTAssertTrue(fullName.isHittable)
        fullName.tap()
        XCTAssertTrue(waitForDisappearance(mascot), "The mascot hides while typing")
        fullName.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 64))
        fullName.typeText("Test User")
        fullName.typeText("\n")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(revealBelow(email, in: app))
        email.tap()
        email.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 64))
        email.typeText("test@example.com")
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: next)
        wait(for: [enabled], timeout: timeout)
        XCTAssertFalse(app.buttons["wizard.start-over"].exists, "Discarding a draft is only offered on the Resume step")
        dismissKeyboard(in: app)
        next.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.work-library"].waitForExistence(timeout: timeout))
        // An empty library offers only Add experience, with no Add task row or select-all box.
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Add experience"].exists)
        XCTAssertFalse(app.buttons["Add task"].exists)
        XCTAssertFalse(app.buttons["wizard.experience.select-all"].exists)
        let back = app.buttons["wizard.back"]
        XCTAssertTrue(back.waitForExistence(timeout: timeout))
        back.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.start"].waitForExistence(timeout: timeout))
    }

    func testFirstUseGuidanceAndEmptyResumeAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["tasks.first-use-guidance"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.companyMix"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.resumeUsage"].exists)
        capture(app, "first-use-tasks")
        selectTab("Resumes", in: app)
        XCTAssertTrue(app.buttons["resumes.create"].waitForExistence(timeout: timeout))
        app.buttons["resumes.create"].tap()
        XCTAssertTrue(app.textFields["wizard.full-name"].waitForExistence(timeout: timeout))
        XCTAssertEqual(app.textFields["wizard.full-name"].value as? String, "Full name")
        XCTAssertFalse(app.buttons["wizard.next"].isEnabled)
        XCTAssertTrue(app.staticTexts["wizard.advance-guidance"].exists)
        capture(app, "first-use-wizard-validation")
        if #available(iOS 17.0, *) { try app.performAccessibilityAudit(for: [.hitRegion, .elementDetection]) }
    }

    func testLargeTextKeyboardAndLandscapeWizard() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-dark", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        selectTab("Resume Wizard", in: app)
        let name = app.textFields["wizard.full-name"]
        XCTAssertTrue(revealBelow(name, in: app))
        XCTAssertFalse(app.descendants(matching: .any)["wizard.mascot"].exists, "No mascot at accessibility text sizes")
        name.tap(); name.typeText("A very long candidate name\n")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(revealBelow(email, in: app))
        email.tap(); email.typeText("candidate@example.com")
        capture(app, "wizard-dark-large-text-keyboard")
        dismissKeyboard(in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        // Rotation relayouts asynchronously; wait for it instead of sampling mid-animation.
        let nextHittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: app.buttons["wizard.next"])
        XCTAssertEqual(XCTWaiter.wait(for: [nextHittable], timeout: timeout), .completed)
        capture(app, "wizard-dark-large-text-landscape")
    }

    func testJobRepairAndProviderConfigurationKeepWizardSelections() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-unreviewed-job"]
        app.launch()
        selectTab("Resume Wizard", in: app)
        let name = app.textFields["wizard.full-name"]
        name.tap(); name.typeText("Test User\n")
        app.textFields["wizard.email"].tap(); app.textFields["wizard.email"].typeText("test@example.com")
        dismissKeyboard(in: app)
        app.buttons["wizard.next"].tap()
        selectFirstWizardTask(in: app)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.job-description"].waitForExistence(timeout: timeout))
        let job = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wizard.job.'")).firstMatch
        XCTAssertTrue(job.isEnabled)
        XCTAssertFalse(app.buttons["wizard.next"].isEnabled)
        job.tap()
        XCTAssertTrue(app.buttons["Mark reviewed"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapWhenHittable(app.buttons["Mark reviewed"], in: app))
        app.buttons["Done"].tap()
        job.tap()
        XCTAssertTrue(app.buttons["wizard.next"].isEnabled)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.summary"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.configure-provider"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["ai-provider.selector"].waitForExistence(timeout: timeout))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["wizard.generate"].waitForExistence(timeout: timeout))
        app.swipeDown()
        app.buttons["wizard.edit-experience"].tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout))
        capture(app, "wizard-job-repaired-selection-retained")
    }

    func testNoMatchingJobsAndDeletionCancellation() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        selectTab("Saved Jobs", in: app)
        let search = app.textFields["jobs.search"]
        XCTAssertTrue(search.waitForExistence(timeout: timeout))
        // Return closes the keyboard so the empty state's button below the search card stays on screen.
        search.tap(); search.typeText("NO_MATCH_SENTINEL\n")
        XCTAssertTrue(app.staticTexts["No matching jobs"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapWhenHittable(app.buttons["jobs.clear-filters"], in: app))
        XCTAssertFalse((search.value as? String ?? "").contains("NO_MATCH_SENTINEL"))
        let job = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Ready for resume'")).firstMatch
        XCTAssertTrue(job.waitForExistence(timeout: timeout))
        job.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete job"].waitForExistence(timeout: timeout))
        dismissConfirmation("Cancel", in: app)
        XCTAssertTrue(job.exists)
        selectTab("Resumes", in: app)
        let resume = app.buttons["resume.saved-row"].firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        resume.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete resume"].waitForExistence(timeout: timeout))
        dismissConfirmation("Cancel", in: app)
        XCTAssertTrue(resume.exists)
        capture(app, "saved-resume-delete-cancelled")
        selectTab("Tasks", in: app)
        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(revealHittable(task, in: app))
        task.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete task"].firstMatch.waitForExistence(timeout: timeout))
        dismissConfirmation("Cancel", in: app)
        XCTAssertTrue(task.exists)
        capture(app, "task-delete-cancelled")
    }

    func testWizardBubbleSpeaksForEmptyLibraries() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        fillWizardProfile(in: app)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.work-library"].waitForExistence(timeout: timeout))
        let mascot = app.descendants(matching: .any)["wizard.mascot"]
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        XCTAssertTrue(mascot.label.contains("No tasks added yet"), mascot.label)
        // The bubble carries the guidance, so the empty state keeps only its title and button.
        XCTAssertTrue(app.buttons["Add experience"].exists)
        XCTAssertFalse(app.staticTexts["Add a task or achievement to use in your resume."].exists)
        // On iPhone the title sits in the navigation bar beside Back, above the bubble.
        let back = app.buttons["wizard.back"]
        XCTAssertTrue(back.exists)
        if isPhone {
            let title = app.navigationBars["Resume Wizard"].staticTexts["bar.title"]
            XCTAssertTrue(title.exists)
            XCTAssertEqual(title.label, "Resume Wizard")
            XCTAssertLessThan(abs(title.frame.midY - back.frame.midY), 12)
            XCTAssertGreaterThan(title.frame.minX, back.frame.maxX)
            XCTAssertLessThan(title.frame.maxY, mascot.frame.minY)
        }

        // Tasks but no saved jobs.
        app.terminate()
        app.launchArguments = ["-ui-testing", "-mock-data"]
        app.launch()
        fillWizardProfile(in: app)
        app.buttons["wizard.next"].tap()
        selectFirstWizardTask(in: app)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.job-description"].waitForExistence(timeout: timeout))
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        XCTAssertTrue(mascot.label.contains("No jobs saved yet"), mascot.label)
        XCTAssertTrue(app.buttons["wizard.jobs.empty-add-job"].exists)
        XCTAssertFalse(app.staticTexts["Add a job description to continue."].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add job'")).count, 1, "Only the empty state offers Add job")
    }

    func testWizardNoMatchingJobsOffersAddJob() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        fillWizardProfile(in: app)
        app.buttons["wizard.next"].tap()
        selectFirstWizardTask(in: app)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.job-description"].waitForExistence(timeout: timeout))
        let filter = app.buttons["wizard.jobs.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: timeout))
        filter.tap()
        let needsReview = app.buttons["Needs review"]
        XCTAssertTrue(needsReview.waitForExistence(timeout: timeout))
        needsReview.tap()
        XCTAssertTrue(app.staticTexts["No matching jobs"].waitForExistence(timeout: timeout))
        let addJob = app.buttons["wizard.jobs.empty-add-job"]
        let clear = app.buttons["wizard.jobs.clear-filters"]
        XCTAssertTrue(addJob.exists)
        XCTAssertTrue(clear.exists)
        // Both sit fully above the bottom bar without scrolling, Add job first.
        let bar = app.descendants(matching: .any)["wizard.bottom-bar"]
        XCTAssertLessThanOrEqual(addJob.frame.maxY, bar.frame.minY)
        XCTAssertLessThanOrEqual(clear.frame.maxY, bar.frame.minY, "Clear search and filters stays above the bottom bar")
        XCTAssertTrue(addJob.frame.maxX <= clear.frame.minX || addJob.frame.maxY <= clear.frame.minY, "Add job comes first")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add job'")).count, 1, "The trailing Add job row hides")
        capture(app, "wizard-no-matching-jobs")
        addJob.tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: timeout), "Add job opens the add job sheet")
        cancel.tap()
        XCTAssertTrue(tapWhenHittable(clear, in: app))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wizard.job.'")).firstMatch.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add job'")).firstMatch.exists)
    }
}
