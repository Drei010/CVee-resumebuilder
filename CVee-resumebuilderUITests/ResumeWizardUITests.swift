import XCTest
import UIKit
import Vision

final class ResumeWizardUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    func testTaskGroupsAndCreationRemainAccessible() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        let group = app.buttons["tasks.company-section"].firstMatch
        XCTAssertTrue(group.waitForExistence(timeout: timeout))
        let task = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(task.exists)
        capture(app, "tasks-light")
        for _ in 0..<3 where !group.isHittable { app.swipeUp() }
        XCTAssertTrue(group.isHittable)
        group.tap()
        XCTAssertFalse(task.exists)
        group.tap()
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
        let add = app.buttons["tasks.actions"]
        XCTAssertTrue(add.isHittable)
        add.tap()
        app.buttons["Add manually"].tap()
        XCTAssertTrue(app.textFields["Job title"].waitForExistence(timeout: timeout))
        app.buttons["Cancel"].tap()
        for tab in ["Saved Jobs", "Resume Wizard", "Resumes", "Profile"] {
            selectTab(tab, in: app)
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: timeout))
            capture(app, tab.replacingOccurrences(of: " ", with: "-").lowercased())
        }
    }

    func testTaskCaptureCardValidationAndRecording() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let record = app.buttons["tasks.record"]
        XCTAssertTrue(record.waitForExistence(timeout: timeout))
        XCTAssertFalse(record.isEnabled)

        let details = app.descendants(matching: .any)["tasks.capture-details"]
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
        app.buttons["tasks.confirm-company"].tap()
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
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Product Designer'")).firstMatch.waitForExistence(timeout: timeout))
    }

    func testTaskRowsLeadWithAchievementAndHideCompanyBadge() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
        XCTAssertFalse(task.label.contains("Accenture Philippines"))
    }

    func testTaskSearchControlsReflectAndClearFilters() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mock-data"]
        app.launch()

        let search = app.textFields["tasks.search"]
        XCTAssertTrue(search.waitForExistence(timeout: timeout))
        let resultCount = app.staticTexts["tasks.result-count"]
        XCTAssertTrue(resultCount.waitForExistence(timeout: timeout))
        XCTAssertTrue(resultCount.label.contains("30"))

        search.tap()
        search.typeText("Pinecone")
        XCTAssertTrue(app.buttons["tasks.search.clear"].waitForExistence(timeout: timeout))
        XCTAssertTrue(resultCount.label.contains("5"))
        app.buttons["tasks.search.clear"].tap()
        XCTAssertFalse((search.value as? String ?? "").contains("Pinecone"))

        app.buttons["tasks.filter"].tap()
        app.buttons["[Mock] Pinecone Systems"].tap()
        let chip = app.buttons["tasks.active-company-filter"]
        XCTAssertTrue(chip.waitForExistence(timeout: timeout))
        XCTAssertTrue(resultCount.label.contains("5"))
        chip.tap()
        XCTAssertFalse(chip.exists)

        search.tap()
        search.typeText("No matching task")
        dismissKeyboard(in: app)
        let clearFilters = app.buttons["tasks.clear-filters"]
        XCTAssertTrue(clearFilters.waitForExistence(timeout: timeout))
        clearFilters.tap()
        XCTAssertTrue(resultCount.label.contains("30"))
    }

    func testCaptureAndConfirmationDetailsRemainEditable() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let details = app.textFields["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
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

        let details = app.textFields["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
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

        let details = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
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

    func testAIEnhancementCanBeReviewedAndAccepted() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai"]
        app.launch()

        let original = "Improved the onboarding flow."
        let details = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
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
        let details = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        details.tap()
        details.typeText(original)
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        app.buttons["tasks.record.improve-ai"].tap()

        XCTAssertTrue(app.staticTexts["task.ai-review.error"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["task.ai-review.use"].isEnabled)
        let keepOriginal = app.buttons["task.ai-review.keep"]
        XCTAssertTrue(revealBelow(keepOriginal, in: app))
        keepOriginal.tap()
        XCTAssertTrue((app.textFields["tasks.record.details"].value as? String ?? "").contains(original))
        app.buttons["Cancel"].tap()
    }

    func testAIEnhancementEmptyResponseCannotBeApplied() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-ai-empty"]
        app.launch()

        let details = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        details.tap()
        details.typeText("Improved the onboarding flow.")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        app.buttons["tasks.record.improve-ai"].tap()

        XCTAssertTrue(app.staticTexts["task.ai-review.error"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["task.ai-review.use"].isEnabled)
        app.buttons["Cancel"].tap()
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
        XCTAssertTrue(app.buttons["task.ai-review.use"].waitForExistence(timeout: timeout))
        app.buttons["task.ai-review.use"].tap()
        XCTAssertTrue((details.value as? String ?? "").contains("Improved task details for testing"))
        app.buttons["Cancel"].tap()
    }

    func testAIEnhancementReviewWorksInExistingTaskEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-ai"]
        app.launch()

        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
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

    func testQuickCaptureDraftRestoresAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let draft = "Unfinished task draft to restore."
        let details = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        details.tap()
        details.typeText(draft)
        dismissKeyboard(in: app)
        app.terminate()

        app.launchArguments = ["-ui-testing", "-ui-testing-preserve-drafts"]
        app.launch()
        let restored = app.descendants(matching: .any)["tasks.capture-details"]
        XCTAssertTrue(restored.waitForExistence(timeout: timeout))
        XCTAssertEqual((restored.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), draft)

        app.buttons["tasks.actions"].tap()
        XCTAssertTrue(app.buttons["tasks.discard-draft"].waitForExistence(timeout: timeout))
        app.buttons["tasks.discard-draft"].tap()
        XCTAssertTrue(app.buttons["tasks.discard-draft-confirm"].waitForExistence(timeout: timeout))
        app.buttons["tasks.discard-draft-confirm"].firstMatch.tap()
        XCTAssertFalse(app.buttons["tasks.record"].isEnabled)
    }

    func testTaskCreationImportAndClearConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.buttons["tasks.actions"].tap()
        app.buttons["Add manually"].tap()
        let title = app.textFields["task.role"]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        title.tap()
        title.typeText("Product Designer")
        app.textFields["Company"].tap()
        app.textFields["Company"].typeText("Example Studio")
        app.buttons["task.save"].tap()
        let task = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Product Designer'")).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
        task.tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: timeout))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["tasks.import"].waitForExistence(timeout: timeout))
        app.buttons["tasks.import"].tap()
        XCTAssertTrue(app.buttons["import.choose-document"].waitForExistence(timeout: timeout))
        app.buttons["Cancel"].tap()
        selectTab("Profile", in: app)
        app.swipeUp()
        app.swipeUp()
        app.buttons["Clear all data"].tap()
        XCTAssertTrue(app.textFields["Type CLEAR to confirm"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons.matching(identifier: "Clear all data").allElementsBoundByIndex.contains { !$0.isEnabled })
        app.buttons["Cancel"].tap()
        selectTab("Tasks", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
    }

    func testDarkLargeTextTaskLayout() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-dark",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["tasks.actions"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["tasks.actions"].isHittable)
        let companySection = app.buttons["tasks.company-section"].firstMatch
        for _ in 0..<3 where !companySection.isHittable { app.swipeUp() }
        XCTAssertTrue(companySection.isHittable)
        capture(app, "tasks-dark-accessibility")
        app.buttons["Resume Wizard"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.progress"].waitForExistence(timeout: timeout))
        capture(app, "wizard-dark-accessibility")
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func selectTab(_ name: String, in app: XCUIApplication) {
        if name == "Profile", app.frame.width > 600, app.buttons["Next Page"].exists {
            app.buttons["Next Page"].tap()
        } else if app.frame.width > 600, app.buttons["Previous Page"].exists {
            app.buttons["Previous Page"].tap()
        }
        app.buttons[name].firstMatch.tap()
    }

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
        fullName.typeText("\n")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(revealBelow(email, in: app))
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

    func testAIProviderSelectionAndModelConfiguration() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        selectTab("Profile", in: app)
        app.swipeUp()
        let providerLink = app.buttons["profile.ai-provider"]
        XCTAssertTrue(providerLink.waitForExistence(timeout: timeout))
        providerLink.tap()
        XCTAssertTrue(app.navigationBars["AI Provider"].waitForExistence(timeout: timeout))
        let providerSelector = app.buttons["ai-provider.selector"]
        XCTAssertTrue(providerSelector.waitForExistence(timeout: timeout))
        providerSelector.tap()
        app.buttons["OpenAI"].tap()
        XCTAssertTrue(app.buttons["ai-provider.model"].waitForExistence(timeout: timeout))
        app.buttons["ai-provider.edit-key"].tap()
        let key = app.secureTextFields["ai-provider.api-key"]
        XCTAssertTrue(key.waitForExistence(timeout: timeout))
        key.tap()
        key.typeText("ui-test-key")
        let saveKey = app.buttons["ai-provider.save-key"]
        let saveEnabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: saveKey)
        wait(for: [saveEnabled], timeout: timeout)
        saveKey.tap()
        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["ai-provider.key-saved"].waitForExistence(timeout: timeout))
        app.buttons["ai-provider.edit-key"].tap()
        XCTAssertTrue(app.buttons["ai-provider.save-key"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Save"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["ai-provider.key-saved"].waitForExistence(timeout: timeout))
        app.buttons["ai-provider.edit-key"].tap()
        app.buttons["ai-provider.remove-key"].tap()
        app.buttons.matching(identifier: "Delete API key").element(boundBy: 0).tap()
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
        XCTAssertTrue(app.buttons["wizard.edit-profile"].waitForExistence(timeout: timeout))
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
        assertPreviewContainsText(app, preview, "Andrei Hidalgo")
        capture(app, "resume-preview-before-edit")
        let checkMatch = app.buttons["wizard.check-job-match"]
        XCTAssertTrue(checkMatch.waitForExistence(timeout: timeout))
        let saveResume = app.buttons["wizard.save-resume"]
        XCTAssertTrue(saveResume.waitForExistence(timeout: timeout))
        XCTAssertLessThan(abs(saveResume.frame.midY - checkMatch.frame.midY), 8)
        checkMatch.tap()
        XCTAssertTrue(app.navigationBars["Resume report"].waitForExistence(timeout: timeout))
        let requirement = app.textFields["analysis.new-phrase"]
        XCTAssertTrue(requirement.waitForExistence(timeout: timeout))
        requirement.tap()
        requirement.typeText("Python")
        let addPhrase = app.buttons["analysis.add-phrase"]
        XCTAssertTrue(tapWhenHittable(addPhrase, in: app))
        XCTAssertTrue(app.staticTexts["Python"].waitForExistence(timeout: timeout))
        requirement.typeText("\n")
        dismissKeyboard(in: app)
        let toolbarSave = app.buttons["analysis.save-requirements-toolbar"]
        if toolbarSave.waitForExistence(timeout: 2) {
            XCTAssertTrue(tapAction(toolbarSave, in: app))
        } else {
            XCTAssertTrue(tapWhenHittable(app.buttons["analysis.save-requirements"], in: app))
        }
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
        let savedResume = app.buttons["resume.saved-row"]
        XCTAssertTrue(savedResume.waitForExistence(timeout: timeout))
        savedResume.tap()
        XCTAssertTrue(app.descendants(matching: .any)["resume.editor-mode"].waitForExistence(timeout: timeout))
        app.buttons["Preview"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["resume.structured-preview"].waitForExistence(timeout: timeout))
        app.buttons["Content"].tap()
        XCTAssertTrue(app.buttons["resume.add-section"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resume.export"].waitForExistence(timeout: timeout))
        app.buttons["resume.export"].tap()
        XCTAssertTrue(app.buttons["resume.export-pdf"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resume.export-rtf"].waitForExistence(timeout: timeout))
    }

    private func assertPreviewContainsText(_ app: XCUIApplication, _ preview: XCUIElement, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let screenshot = app.screenshot().image
        guard let image = screenshot.cgImage else { XCTFail("Preview screenshot could not be read", file: file, line: line); return }
        let scale = CGFloat(image.width) / app.frame.width
        let frame = preview.frame.integral
        let cropRect = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale, height: frame.height * scale).intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let crop = image.cropping(to: cropRect) else { XCTFail("Preview screenshot could not be cropped", file: file, line: line); return }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        try? VNImageRequestHandler(cgImage: crop, options: [:]).perform([request])
        let recognized = request.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ") ?? ""
        XCTAssertTrue(recognized.localizedCaseInsensitiveContains(expected), "Preview OCR did not find '\(expected)' in '\(recognized)'", file: file, line: line)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<5 {
            if element.waitForExistence(timeout: 2) { return true }
            app.swipeDown()
        }
        return element.waitForExistence(timeout: timeout)
    }

    private func revealBelow(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<5 {
            if element.waitForExistence(timeout: 2) { return true }
            app.swipeUp()
        }
        return element.waitForExistence(timeout: timeout)
    }

    private func tapWhenHittable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<5 {
            if element.waitForExistence(timeout: 2) {
                if element.isHittable && element.isEnabled {
                    element.tap()
                    return true
                }
                dismissKeyboard(in: app)
                if element.isHittable && element.isEnabled {
                    element.tap()
                    return true
                }
            }
            app.swipeUp()
        }
        guard element.waitForExistence(timeout: timeout), element.isHittable, element.isEnabled else { return false }
        element.tap()
        return true
    }

    private func tapAction(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if app.frame.width < 700 {
            guard element.waitForExistence(timeout: timeout) else { return false }
            element.tap()
            return true
        }
        return tapWhenHittable(element, in: app)
    }

    private func dismissKeyboard(in app: XCUIApplication) {
        if app.keyboards.element.waitForExistence(timeout: 1) {
            let hide = app.keyboards.buttons["Hide keyboard"]
            if hide.waitForExistence(timeout: 1) { hide.tap(); return }
            let done = app.keyboards.buttons["Done"]
            if done.waitForExistence(timeout: 1) { done.tap(); return }
        }
        let globalHide = app.buttons["Hide keyboard"]
        if globalHide.waitForExistence(timeout: 1) { globalHide.tap() }
    }
}
