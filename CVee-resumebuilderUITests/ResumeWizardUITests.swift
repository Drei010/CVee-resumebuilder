import XCTest
import UIKit
import Vision

final class ResumeWizardUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    func testTaskGroupsAndCreationRemainAccessible() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        let companyMix = app.descendants(matching: .any)["tasks.metric.companyMix"]
        XCTAssertTrue(companyMix.waitForExistence(timeout: timeout))
        XCTAssertTrue((companyMix.value as? String ?? "").contains("Accenture Philippines"))
        capture(app, "tasks-light")
        let group = app.buttons["tasks.company-section"].firstMatch
        let task = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(revealHittable(task, in: app))
        XCTAssertTrue(group.isHittable)
        group.tap()
        XCTAssertFalse(task.exists)
        // Collapsing shortens the list, so the header can settle behind the tab bar.
        XCTAssertTrue(revealHittable(group, in: app))
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
        app.buttons["Sheet Grabber"].firstMatch.swipeUp()
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

    func testTaskRowsLeadWithAchievementAndHideCompanyBadge() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(revealHittable(task, in: app))
        XCTAssertFalse(task.label.contains("Accenture Philippines"))
    }

    func testTaskSearchControlsReflectAndClearFilters() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mock-data"]
        app.launch()

        let search = app.textFields["tasks.search"]
        XCTAssertTrue(revealHittable(search, in: app))
        XCTAssertFalse(app.descendants(matching: .any)["tasks.result-count"].exists)

        search.tap()
        search.typeText("Pinecone")
        XCTAssertTrue(app.buttons["tasks.search.clear"].waitForExistence(timeout: timeout))
        // Return closes the keyboard so the filtered sections below the search bar stay on screen.
        search.typeText("\n")
        assertOnlyCompanySection("Pinecone", taskCount: 5, in: app)
        app.buttons["tasks.search.clear"].tap()
        XCTAssertFalse((search.value as? String ?? "").contains("Pinecone"))

        app.buttons["tasks.filter"].tap()
        app.buttons["[Mock] Pinecone Systems"].tap()
        let chip = app.buttons["tasks.active-company-filter"]
        XCTAssertTrue(chip.waitForExistence(timeout: timeout))
        assertOnlyCompanySection("Pinecone", taskCount: 5, in: app)
        chip.tap()
        XCTAssertFalse(chip.exists)

        search.tap()
        search.typeText("No matching task")
        dismissKeyboard(in: app)
        let clearFilters = app.buttons["tasks.clear-filters"]
        XCTAssertTrue(clearFilters.waitForExistence(timeout: timeout))
        clearFilters.tap()
        XCTAssertTrue(app.buttons["tasks.company-section"].firstMatch.waitForExistence(timeout: timeout))
        XCTAssertFalse(app.staticTexts["No matching tasks"].exists)
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

        let details = expandTaskCapture(app)
        details.tap()
        details.typeText("Improved the onboarding flow.")
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.record"], in: app))
        app.buttons["tasks.record.improve-ai"].tap()

        XCTAssertTrue(app.staticTexts["task.ai-review.error"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["task.ai-review.use"].isEnabled)
        // On iPad both stacked sheets show a Cancel button, so close the review explicitly first.
        let keepOriginal = app.buttons["task.ai-review.keep"]
        XCTAssertTrue(revealBelow(keepOriginal, in: app))
        keepOriginal.tap()
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
        XCTAssertTrue(revealHittable(task, in: app))
        task.tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: timeout))
        app.buttons["Done"].tap()
        // Import tasks is an item in the Task actions menu, not a row in the list.
        let importTasks = app.buttons["tasks.import"]
        XCTAssertFalse(importTasks.exists)
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.actions"], in: app))
        XCTAssertTrue(importTasks.waitForExistence(timeout: timeout))
        capture(app, "tasks-actions-menu-with-tasks")
        importTasks.tap()
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
        XCTAssertTrue(revealHittable(task, in: app))
    }

    func testTaskImportOpensFromActionsMenu() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        // The search card now follows the progress widgets directly, with no Import tasks row between.
        XCTAssertTrue(revealHittable(app.textFields["tasks.search"], in: app))
        let importTasks = app.buttons["tasks.import"]
        XCTAssertFalse(importTasks.exists)
        XCTAssertFalse(app.buttons["Import tasks"].exists)

        let actions = app.buttons["tasks.actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: timeout))
        actions.tap()
        let addManually = app.buttons["Add manually"]
        XCTAssertTrue(addManually.waitForExistence(timeout: timeout))
        XCTAssertTrue(importTasks.waitForExistence(timeout: timeout))
        // Add manually, then Import tasks.
        XCTAssertLessThan(addManually.frame.midY, importTasks.frame.midY)
        capture(app, "tasks-actions-menu")
        importTasks.tap()
        XCTAssertTrue(app.buttons["import.choose-document"].waitForExistence(timeout: timeout))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(waitForDisappearance(app.buttons["import.choose-document"]))
    }

    func testDarkLargeTextTaskLayout() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture", "-ui-testing-dark",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["tasks.actions"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["tasks.actions"].isHittable)
        XCTAssertTrue(app.descendants(matching: .any)["tasks.mascot"].waitForExistence(timeout: timeout))
        capture(app, "tasks-dark-accessibility")
        let companySection = app.buttons["tasks.company-section"].firstMatch
        XCTAssertTrue(revealHittable(companySection, in: app, steps: 10))
        app.buttons["Resume Wizard"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.progress"].waitForExistence(timeout: timeout))
        capture(app, "wizard-dark-accessibility")
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

    func testTaskSearchSpansFullWidthWithoutResultCount() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mock-data"]
        app.launch()

        // The quick capture card nests inside the mascot row, so its frame is the card itself rather
        // than the whole list cell; read its edges before any scrolling can move it off screen.
        let captureCard = app.buttons["tasks.capture-card"]
        XCTAssertTrue(captureCard.waitForExistence(timeout: timeout))
        let cardFrame = captureCard.frame
        let search = app.textFields["tasks.search"]
        XCTAssertTrue(revealHittable(search, in: app))
        capture(app, "tasks-search-under-progress")
        XCTAssertFalse(app.descendants(matching: .any)["tasks.result-count"].exists)
        let searchBar = app.descendants(matching: .any).matching(identifier: "tasks.search-bar").firstMatch
        XCTAssertTrue(searchBar.waitForExistence(timeout: timeout))
        // Same 16-point side margins as the cards above it, so its edges line up with the capture card.
        // On wide displays the list is a centered 760-point column, so the margins start at its edges.
        let window = app.windows.firstMatch.frame
        let sideMargin = max(0, (window.width - 760) / 2) + 16
        XCTAssertEqual(searchBar.frame.minX - window.minX, sideMargin, accuracy: 1)
        XCTAssertEqual(window.maxX - searchBar.frame.maxX, sideMargin, accuracy: 1)
        XCTAssertEqual(searchBar.frame.minX, cardFrame.minX, accuracy: 1)
        XCTAssertEqual(searchBar.frame.maxX, cardFrame.maxX, accuracy: 1)
        // Scroll so the pinned search header and the task list show together.
        app.swipeUp()
        XCTAssertTrue(revealHittable(search, in: app))
        XCTAssertEqual(searchBar.frame.minX - window.minX, sideMargin, accuracy: 1)
        capture(app, "tasks-search-full-width")

        search.tap()
        search.typeText("Pinecone\n")
        assertOnlyCompanySection("Pinecone", taskCount: 5, in: app)
        XCTAssertFalse(app.descendants(matching: .any)["tasks.result-count"].exists)
    }

    func testSavedJobsShowsMascotOutsideSearch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        selectTab("Saved Jobs", in: app)
        let mascot = app.descendants(matching: .any)["jobs.mascot"]
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        XCTAssertTrue(mascot.label.contains("Save a job you want to land"))
        // With no saved jobs there is nothing to search: the mascot leads straight into the empty state.
        XCTAssertTrue(app.buttons["Add job"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.textFields["jobs.search"].exists)
        capture(app, "saved-jobs-mascot-empty")
        app.terminate()

        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        selectTab("Saved Jobs", in: app)
        XCTAssertTrue(mascot.waitForExistence(timeout: timeout))
        XCTAssertTrue(mascot.label.contains("saved job"))

        // The search card sits in the list directly below the mascot, with no pull-down to reveal it.
        let search = app.textFields["jobs.search"]
        let searchBar = app.descendants(matching: .any).matching(identifier: "jobs.search-bar").firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: timeout))
        XCTAssertTrue(searchBar.waitForExistence(timeout: timeout))
        XCTAssertFalse(app.searchFields.firstMatch.exists)
        XCTAssertLessThanOrEqual(mascot.frame.maxY, searchBar.frame.minY + 1)
        // Record where both sit while fully on screen, so typing can be checked for any movement.
        let window = app.windows.firstMatch.frame
        XCTAssertTrue(window.contains(mascot.frame))
        let mascotTop = mascot.frame.minY
        let barTop = searchBar.frame.minY
        capture(app, "saved-jobs-mascot")

        // The mascot stays put and on screen while searching, so the field never jumps under the finger.
        search.tap(); search.typeText("NO_MATCH_SENTINEL")
        XCTAssertTrue(app.staticTexts["No matching jobs"].waitForExistence(timeout: timeout))
        XCTAssertTrue(window.contains(mascot.frame))
        XCTAssertEqual(mascot.frame.minY, mascotTop, accuracy: 1)
        XCTAssertEqual(searchBar.frame.minY, barTop, accuracy: 1)
        XCTAssertLessThanOrEqual(mascot.frame.maxY, searchBar.frame.minY + 1)
        capture(app, "saved-jobs-search-no-match")
    }

    func testSavedJobsFiltersByCompanyAndStatus() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        selectTab("Saved Jobs", in: app)

        // The fixture's one job: Full Stack AI Developer at Accenture Philippines, ready for a resume.
        // Matching both texts finds the row, never a filter menu item or chip.
        let job = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Accenture Philippines' AND label CONTAINS 'Ready for resume'")).firstMatch
        XCTAssertTrue(job.waitForExistence(timeout: timeout))
        let filter = app.buttons["jobs.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: timeout))

        // The fixture job is ready for a resume, so a Needs review filter leaves nothing to show.
        filter.tap()
        let needsReview = app.buttons["Needs review"]
        XCTAssertTrue(needsReview.waitForExistence(timeout: timeout))
        capture(app, "saved-jobs-filter-menu")
        needsReview.tap()
        XCTAssertTrue(app.staticTexts["No matching jobs"].waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForDisappearance(job))
        let statusChip = app.buttons["jobs.active-status-filter"]
        XCTAssertTrue(statusChip.waitForExistence(timeout: timeout))
        XCTAssertTrue((filter.value as? String ?? "").contains("Needs review"))
        capture(app, "saved-jobs-status-filter")
        XCTAssertTrue(tapWhenHittable(app.buttons["jobs.clear-filters"], in: app))
        XCTAssertTrue(job.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForDisappearance(statusChip))
        XCTAssertFalse(app.staticTexts["No matching jobs"].exists)

        // Filtering by the job's own company keeps it; its chip removes the filter.
        filter.tap()
        let company = app.buttons["Accenture Philippines"]
        XCTAssertTrue(company.waitForExistence(timeout: timeout))
        company.tap()
        let companyChip = app.buttons["jobs.active-company-filter"]
        XCTAssertTrue(companyChip.waitForExistence(timeout: timeout))
        XCTAssertTrue(job.waitForExistence(timeout: timeout))
        capture(app, "saved-jobs-company-filter")
        companyChip.tap()
        XCTAssertTrue(waitForDisappearance(companyChip))
        XCTAssertTrue(job.exists)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Quick capture starts as a collapsed action card; open it unless a restored draft already did.
    private func expandTaskCapture(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let details = app.textFields["tasks.capture-details"]
        let card = app.buttons["tasks.capture-card"]
        if !details.exists, card.waitForExistence(timeout: timeout) {
            card.tap()
        }
        XCTAssertTrue(details.waitForExistence(timeout: timeout), file: file, line: line)
        return details
    }

    /// The task list shows one company section, for `company`, holding `taskCount` tasks.
    private func assertOnlyCompanySection(_ company: String, taskCount: Int, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let sections = app.buttons.matching(identifier: "tasks.company-section")
        let match = sections.matching(NSPredicate(format: "label CONTAINS %@", company)).firstMatch
        XCTAssertTrue(match.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(match.label.contains("\(taskCount)"), "Section '\(match.label)' should count \(taskCount) tasks", file: file, line: line)
        XCTAssertEqual(sections.matching(NSPredicate(format: "NOT (label CONTAINS %@)", company)).count, 0, file: file, line: line)
    }

    private func waitForDisappearance(_ element: XCUIElement) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter.wait(for: [gone], timeout: timeout) == .completed
    }

    private func selectTab(_ name: String, in app: XCUIApplication) {
        if name == "Profile", app.frame.width > 600, app.buttons["Next Page"].exists {
            app.buttons["Next Page"].tap()
        } else if app.frame.width > 600, app.buttons["Previous Page"].exists {
            app.buttons["Previous Page"].tap()
        }
        app.buttons[name].firstMatch.tap()
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: timeout))
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
        XCTAssertTrue(requirement.waitForExistence(timeout: timeout))
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
        XCTAssertTrue(saveRequirements.waitForExistence(timeout: timeout))
        XCTAssertGreaterThan(saveRequirements.frame.width, app.frame.width * 0.75, "Save requirements spans its row")
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
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.return-to-draft"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.edit-resume"], in: app))
        XCTAssertTrue((editor.value as? String ?? "").contains("NAVIGATION_SENTINEL"))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.start-over"], in: app))
        dismissConfirmation("Keep working", in: app)
        XCTAssertTrue((editor.value as? String ?? "").contains("NAVIGATION_SENTINEL"))
        dismissKeyboard(in: app)
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.edit-resume"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["wizard.save-resume"], in: app))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Couldn’t save resume'")).firstMatch.waitForExistence(timeout: timeout))
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

    func testProgressWidgetsCanBeAddedAndReset() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        let recent = app.descendants(matching: .any)["tasks.metric.recentTasks"]
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.resumeUsage"].waitForExistence(timeout: timeout))
        XCTAssertFalse(recent.exists)

        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.edit"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.add.recentTasks"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metrics.shown.recentTasks"].waitForExistence(timeout: timeout))
        capture(app, "tasks-widget-editor")
        app.buttons["tasks.metrics.done"].tap()
        XCTAssertTrue(recent.waitForExistence(timeout: timeout))
        XCTAssertTrue((recent.value as? String ?? "").contains("1 task recorded"))

        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.edit"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.reset"], in: app))
        app.buttons["tasks.metrics.done"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.companyMix"].waitForExistence(timeout: timeout))
        XCTAssertFalse(recent.exists)
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

    private func dismissConfirmation(_ label: String, in app: XCUIApplication) {
        if app.buttons[label].firstMatch.waitForExistence(timeout: 1) { app.buttons[label].firstMatch.tap() }
        else {
            let close = app.buttons["Close"].firstMatch
            XCTAssertTrue(close.waitForExistence(timeout: timeout))
            close.tap()
        }
    }

    private func generateFixture(in app: XCUIApplication) {
        selectTab("Resume Wizard", in: app)
        let name = app.textFields["wizard.full-name"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        name.tap(); name.typeText("Test User\n")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(revealBelow(email, in: app))
        email.tap(); email.typeText("test@example.com")
        dismissKeyboard(in: app)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.work-library"].waitForExistence(timeout: timeout))
        selectFirstWizardTask(in: app)
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.job-description"].waitForExistence(timeout: timeout))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wizard.job.'")).firstMatch.tap()
        app.buttons["wizard.next"].tap()
        XCTAssertTrue(app.buttons["wizard.generate"].waitForExistence(timeout: timeout))
        app.buttons["wizard.generate"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wizard.generated.pdf"].waitForExistence(timeout: timeout))
    }

    private func wizardTaskRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wizard.task.'"))
    }

    /// Selects the first Work Library task by tapping its row, the only way to select on Experience.
    private func selectFirstWizardTask(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let task = wizardTaskRows(in: app).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: timeout), file: file, line: line)
        task.tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout), file: file, line: line)
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

    /// Scrolls in short, slow drags until the element exists and can be tapped. Slow drags don't
    /// coast, so the Tasks search header and rows below the mascot and progress widgets aren't
    /// flung past. If an element ends up above the middle of the screen, it drags back down.
    private func revealHittable(_ element: XCUIElement, in app: XCUIApplication, steps: Int = 8) -> Bool {
        let upper = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        let lower = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.68))
        for _ in 0..<steps {
            // A row behind the floating tab bar still reports hittable, but a swipe there lands on the
            // tab bar, so it only counts once its middle sits above the bottom 15% of the screen.
            if element.waitForExistence(timeout: 1), element.isHittable,
               element.frame.midY < app.frame.maxY * 0.85 { return true }
            if element.exists, element.frame.midY < app.frame.midY * 0.5 {
                upper.press(forDuration: 0.1, thenDragTo: lower, withVelocity: .slow, thenHoldForDuration: 0.3)
            } else {
                lower.press(forDuration: 0.1, thenDragTo: upper, withVelocity: .slow, thenHoldForDuration: 0.3)
            }
        }
        return element.waitForExistence(timeout: timeout) && element.isHittable
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
                // Past the first step, content under the wizard's bottom bar is scrolled up first.
                let back = app.buttons["wizard.back"]
                let bar = app.descendants(matching: .any)["wizard.bottom-bar"]
                if back.exists, bar.exists, !["wizard.back", "wizard.next", "wizard.generate", "wizard.save-resume"].contains(element.identifier), element.frame.midY >= bar.frame.minY - 12 {
                    // A short, slow drag: a full swipe can fling a nearby row past the top of the list.
                    let lower = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.68))
                    let upper = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.48))
                    lower.press(forDuration: 0.1, thenDragTo: upper, withVelocity: .slow, thenHoldForDuration: 0.3)
                    continue
                }
                if element.isHittable && element.isEnabled {
                    element.tap()
                    return true
                }
                dismissKeyboard(in: app)
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
        let wizardHide = app.buttons["wizard.hide-keyboard"]
        if wizardHide.exists, wizardHide.isHittable { wizardHide.tap(); return }
        if app.keyboards.element.waitForExistence(timeout: 1) {
            for name in ["Hide keyboard", "Done"] {
                let key = app.keyboards.buttons[name]
                guard key.waitForExistence(timeout: 1) else { continue }
                // The iOS 27 iPad Simulator reports every keyboard key off screen and unhittable
                // even while the keyboard is visible, so leave it up rather than tapping blind.
                if key.isHittable { key.tap() }
                return
            }
        }
        let globalHide = app.buttons["Hide keyboard"]
        if globalHide.waitForExistence(timeout: 1), globalHide.isHittable { globalHide.tap() }
    }
}
