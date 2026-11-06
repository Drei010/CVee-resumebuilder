import XCTest
import UIKit

/// Generating, editing, saving, and reopening a resume from the wizard.
final class ResumeGenerationUITests: CVeeUITestCase {
    func testGeneratedResumePreviewSaveReopenAndExport() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        app.buttons["Resume Wizard"].firstMatch.tap()
        let name = app.textFields["wizard.full-name"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        name.tap(); name.typeText("Test User\n")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(email.waitForExistence(timeout: timeout))
        email.tap()
        email.typeText("test@example.com")
        app.buttons["wizard.next"].tap()

        // The search card sits below the step header rather than between the title and the header.
        let progress = app.descendants(matching: .any)["wizard.progress"]
        let search = app.textFields["wizard.experience.search"]
        XCTAssertTrue(search.waitForExistence(timeout: timeout))
        XCTAssertGreaterThanOrEqual(search.frame.minY, progress.frame.maxY)
        XCTAssertTrue(app.buttons["wizard.experience.filter"].exists)
        let next = app.buttons["wizard.next"]
        XCTAssertLessThan(abs(next.frame.width - app.frame.width), 48, "Continue spans the bottom bar")
        let task = wizardTaskRows(in: app).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
        // The header checkbox selects every task shown, then clears them.
        let selectAll = app.buttons["wizard.experience.select-all"]
        XCTAssertTrue(selectAll.exists)
        selectAll.tap()
        XCTAssertTrue(app.staticTexts["\(wizardTaskRows(in: app).count) selected"].waitForExistence(timeout: timeout))
        selectAll.tap()
        XCTAssertTrue(app.staticTexts["0 selected"].waitForExistence(timeout: timeout))
        task.tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout))
        task.tap()
        XCTAssertTrue(app.staticTexts["0 selected"].waitForExistence(timeout: timeout))
        task.tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout))
        app.buttons["wizard.next"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["wizard.job-description"].waitForExistence(timeout: timeout))
        let job = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wizard.job.'"))
        XCTAssertTrue(job.firstMatch.waitForExistence(timeout: timeout))
        job.firstMatch.tap()
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.buttons["wizard.edit-profile"].waitForExistence(timeout: timeout))
        // The edit buttons are icons on the leading side of each review row.
        for id in ["wizard.edit-profile", "wizard.edit-experience", "wizard.edit-job"] {
            XCTAssertLessThan(app.buttons[id].frame.midX, app.frame.midX, id)
        }
        let editExperience = app.buttons["wizard.edit-experience"]
        XCTAssertTrue(editExperience.waitForExistence(timeout: timeout))
        let editJob = app.buttons["wizard.edit-job"]
        XCTAssertTrue(editJob.waitForExistence(timeout: timeout))
        editJob.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.job-description"].waitForExistence(timeout: timeout))
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.buttons["wizard.generate"].waitForExistence(timeout: timeout))
        app.buttons["wizard.generate"].tap()

        let preview = app.descendants(matching: .any)["wizard.generated.pdf"]
        XCTAssertTrue(preview.waitForExistence(timeout: timeout))
        XCTAssertFalse(preview.frame.isEmpty)
        assertPreviewContainsText(app, preview, "Test User")
        capture(app, "resume-preview-before-edit")
        let checkMatch = app.buttons["wizard.check-job-match"]
        XCTAssertTrue(checkMatch.waitForExistence(timeout: timeout))
        let saveResume = app.buttons["wizard.save-resume"]
        XCTAssertTrue(saveResume.waitForExistence(timeout: timeout))
        // Edit and Match sit beside Discard draft above the preview; Save Resume spans the bottom bar.
        let discard = app.buttons["wizard.start-over"]
        XCTAssertTrue(discard.exists)
        XCTAssertLessThan(abs(discard.frame.midY - checkMatch.frame.midY), 8)
        XCTAssertLessThan(abs(app.buttons["wizard.edit-resume"].frame.midY - checkMatch.frame.midY), 8)
        XCTAssertLessThan(checkMatch.frame.maxY, preview.frame.minY)
        XCTAssertLessThan(abs(saveResume.frame.width - app.frame.width), 48, "Save Resume spans the bottom bar")
        checkMatch.tap()
        XCTAssertTrue(app.navigationBars["Resume report"].waitForExistence(timeout: timeout))
        let requirement = app.textFields["analysis.new-phrase"]
        // The report's mascot and Resume match rows sit above the requirements, so scroll to the field.
        XCTAssertTrue(revealHittable(requirement, in: app))
        requirement.tap()
        requirement.typeText("Python")
        requirement.typeText("\n")
        dismissKeyboard(in: app)
        let addPhrase = app.buttons["analysis.add-phrase"]
        XCTAssertTrue(tapWhenHittable(addPhrase, in: app))
        XCTAssertTrue(app.staticTexts["Python"].waitForExistence(timeout: timeout))
        dismissKeyboard(in: app)
        XCTAssertFalse(app.buttons["analysis.recheck"].exists)
        XCTAssertFalse(app.buttons["analysis.save-requirements-toolbar"].exists)
        let saveRequirements = app.buttons["analysis.save-requirements"]
        // The report's list only loads rows near the screen, and on iPad this one starts below the sheet's visible rows.
        XCTAssertTrue(revealHittable(saveRequirements, in: app))
        // Measured against the report's own bar: on iPad the report is a sheet narrower than the window.
        XCTAssertGreaterThan(saveRequirements.frame.width, app.navigationBars["Resume report"].frame.width * 0.75, "Save requirements spans its row")
        XCTAssertTrue(tapWhenHittable(saveRequirements, in: app))
        let coverage = app.staticTexts["analysis.coverage-summary"]
        XCTAssertTrue(reveal(coverage, in: app))
        XCTAssertEqual(coverage.label, "1 of 1 reviewed requirements mentioned.")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["wizard.save-resume"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapAction(app.buttons["wizard.edit-resume"], in: app))
        let formattedEditor = app.descendants(matching: .any)["wizard.formatted-editor"]
        XCTAssertTrue(formattedEditor.waitForExistence(timeout: timeout))
        formattedEditor.tap()
        formattedEditor.typeText(" PREVIEW_SENTINEL")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapAction(app.buttons["wizard.edit-resume"], in: app))
        assertPreviewContainsText(app, preview, "PREVIEW")
        for _ in 0..<4 {
            XCTAssertTrue(tapAction(app.buttons["wizard.edit-resume"], in: app))
            XCTAssertTrue(app.descendants(matching: .any)["wizard.formatted-editor"].waitForExistence(timeout: timeout))
            XCTAssertTrue(tapAction(app.buttons["wizard.edit-resume"], in: app))
        }
        capture(app, "resume-preview-after-edit")
        XCTAssertTrue(tapAction(app.buttons["wizard.edit-resume"], in: app))
        XCTAssertTrue(app.buttons["LaTeX"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapAction(app.buttons["LaTeX"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["wizard.latex-editor"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapAction(app.buttons["wizard.edit-resume"], in: app))
        XCTAssertTrue(tapAction(app.buttons["wizard.save-resume"], in: app))

        let resumesTab = app.buttons["Resumes"].firstMatch
        XCTAssertTrue(resumesTab.waitForExistence(timeout: timeout))
        resumesTab.tap()
        let savedResume = app.buttons["resume.saved-row"].firstMatch
        XCTAssertTrue(savedResume.waitForExistence(timeout: timeout))
        savedResume.tap()
        XCTAssertTrue(app.descendants(matching: .any)["resume.editor-mode"].waitForExistence(timeout: timeout))
        app.buttons["Preview"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["resume.structured-preview"].waitForExistence(timeout: timeout))
        XCTAssertTrue((app.descendants(matching: .any)["resume.structured-preview"].value as? String ?? "").contains("PREVIEW"))
        app.buttons["Content"].tap()
        XCTAssertTrue(app.buttons["resume.add-section"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resume.export"].waitForExistence(timeout: timeout))
        app.buttons["resume.export"].tap()
        XCTAssertTrue(app.buttons["resume.export-pdf"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resume.export-rtf"].waitForExistence(timeout: timeout))
    }

    func testDraftSurvivesNavigationFailedReplacementAndSaveRetry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-regeneration-failure", "-ui-testing-save-failure"]
        app.launch()
        generateFixture(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.edit-resume"], in: app))
        let editor = app.textViews["wizard.formatted-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: timeout))
        editor.tap(); editor.typeText(" NAVIGATION_SENTINEL")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.edit-resume"], in: app))
        app.buttons["wizard.back"].tap()
        XCTAssertTrue(app.buttons["wizard.return-to-draft"].waitForExistence(timeout: timeout))
        selectTab("Tasks", in: app)
        selectTab("Resume Wizard", in: app)
        XCTAssertTrue(app.buttons["wizard.return-to-draft"].waitForExistence(timeout: timeout))
        app.buttons["wizard.generate"].tap()
        XCTAssertTrue(app.buttons["wizard.confirm-replacement"].firstMatch.waitForExistence(timeout: timeout))
        dismissConfirmation("Keep draft", in: app)
        app.buttons["wizard.generate"].tap()
        app.buttons["wizard.confirm-replacement"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.error"].waitForExistence(timeout: timeout))
        app.buttons["wizard.error-dismiss"].tap()
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.return-to-draft"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.edit-resume"], in: app))
        XCTAssertTrue((editor.value as? String ?? "").contains("NAVIGATION_SENTINEL"))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.start-over"], in: app))
        dismissConfirmation("Keep working", in: app)
        XCTAssertTrue((editor.value as? String ?? "").contains("NAVIGATION_SENTINEL"))
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.edit-resume"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.save-resume"], in: app))
        let saveError = app.staticTexts["wizard.draft-error"]
        XCTAssertTrue(saveError.waitForExistence(timeout: timeout))
        XCTAssertTrue(saveError.label.hasPrefix("Your draft is kept."))
        XCTAssertEqual(app.staticTexts["wizard.error-title"].label, "Couldn’t save your resume")
        app.buttons["wizard.error-dismiss"].tap()
        XCTAssertTrue(waitForDisappearance(saveError))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.save-resume"], in: app))
        XCTAssertTrue(app.navigationBars["Resumes"].waitForExistence(timeout: timeout))
        XCTAssertEqual(app.buttons.matching(identifier: "resume.saved-row").count, 2, "One fixture and one generated resume; retry must not insert a duplicate")
        app.buttons["resume.saved-row"].firstMatch.tap()
        app.buttons["Preview"].tap()
        let pdf = app.descendants(matching: .any)["resume.structured-preview"]
        XCTAssertTrue(pdf.waitForExistence(timeout: timeout))
        XCTAssertTrue((pdf.value as? String ?? "").contains("NAVIGATION_SENTINEL"))
        capture(app, "draft-recovered-saved-reopened")
    }

    func testWizardErrorPopupShowsMascotCardAndKeepsDraft() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-regeneration-failure"]
        app.launch()
        generateFixture(in: app)
        app.buttons["wizard.back"].tap()
        XCTAssertTrue(app.buttons["wizard.generate"].waitForExistence(timeout: timeout))
        app.buttons["wizard.generate"].tap()
        app.buttons["wizard.confirm-replacement"].firstMatch.tap()

        let popup = app.descendants(matching: .any)["wizard.error-popup"]
        XCTAssertTrue(popup.waitForExistence(timeout: timeout))
        XCTAssertEqual(app.staticTexts["wizard.error-title"].label, "Couldn’t generate your resume")
        XCTAssertTrue(app.staticTexts["wizard.error"].exists)
        // The card holds the 112-point dog above its title, message and OK.
        XCTAssertGreaterThan(popup.frame.height, 112 + 44)
        XCTAssertFalse(app.buttons["wizard.back"].exists, "Back hides while the popup shows")
        let ok = app.buttons["wizard.error-dismiss"]
        XCTAssertLessThan(abs(ok.frame.midX - popup.frame.midX), 4)
        capture(app, "wizard-generation-error-popup")
        ok.tap()
        XCTAssertTrue(waitForDisappearance(popup))
        XCTAssertTrue(app.buttons["wizard.back"].waitForExistence(timeout: timeout))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.return-to-draft"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["wizard.generated.pdf"].waitForExistence(timeout: timeout))
    }
}
