import XCTest
import UIKit

/// The Tasks library: groups, search, filters, sheets, detail, widgets, and the launch loader.
final class TaskLibraryUITests: CVeeUITestCase {
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
        app.buttons["task.back"].tap()
        for tab in ["Saved Jobs", "Resume Wizard", "Resumes", "Profile"] {
            selectTab(tab, in: app)
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: timeout))
            capture(app, tab.replacingOccurrences(of: " ", with: "-").lowercased())
        }
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
        app.buttons["import.back"].tap()
        selectTab("Profile", in: app)
        let clearAll = app.buttons["Clear all data"]
        XCTAssertTrue(revealHittable(clearAll, in: app))
        clearAll.tap()
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
        let choose = app.buttons["import.choose-document"]
        XCTAssertTrue(choose.waitForExistence(timeout: timeout))
        // A button that fills a Form row reports the whole row as its frame, wider than the inset field.
        XCTAssertGreaterThanOrEqual(choose.frame.width, app.textFields["import.job-title"].frame.width - 8, "Choose document spans its row")
        XCTAssertFalse(app.buttons["Cancel"].exists)
        capture(app, "tasks-import-sheet")
        app.buttons["import.back"].tap()
        XCTAssertTrue(waitForDisappearance(choose))
    }

    func testLaunchLoaderShowsMascotThenTasks() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-launch-loader"]
        app.launch()
        // The hopping dog covers launch until the Tasks mascot is ready, then hands over to the tabs.
        let loader = app.descendants(matching: .any)["app.loader"]
        XCTAssertTrue(loader.waitForExistence(timeout: timeout))
        XCTAssertEqual(loader.label, "Loading CVee")
        XCTAssertFalse(app.buttons["tasks.actions"].exists, "Tasks waits behind the loader")
        capture(app, "launch-loader")
        XCTAssertTrue(waitForDisappearance(loader))
        XCTAssertTrue(app.buttons["tasks.capture-card"].waitForExistence(timeout: timeout))
    }

    func testTasksTitleSharesBarWithTaskActions() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        let actions = app.buttons["tasks.actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: timeout))
        // iPad keeps the large title, since its bar shares a row with the tab bar.
        guard isPhone else { return }
        // On iPhone the title leads the bar, level with Task actions on the right.
        // The bar also keeps a 1-point system title with the same label, so match the visible one.
        let title = app.navigationBars["Tasks"].staticTexts["bar.title"]
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.label, "Tasks")
        XCTAssertLessThan(abs(title.frame.midY - actions.frame.midY), 12)
        XCTAssertLessThan(title.frame.maxX, app.frame.midX)
        XCTAssertLessThan(title.frame.maxX, actions.frame.minX)
        capture(app, "tasks-title-in-bar")
    }

    func testAddTaskSheetLeadsWithBackAndTitle() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.buttons["tasks.actions"].tap()
        let addManually = app.buttons["tasks.add-manually"]
        XCTAssertTrue(addManually.waitForExistence(timeout: timeout))
        addManually.tap()

        // Back replaces Cancel, and the title sits beside it in the bar rather than in a row below.
        let back = app.buttons["task.back"]
        XCTAssertTrue(back.waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["Cancel"].exists)
        // The bar also keeps a 1-point system title with the same label, so match the visible one.
        let title = app.navigationBars["Add task"].staticTexts["bar.title"]
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.label, "Add task")
        XCTAssertLessThan(abs(title.frame.midY - back.frame.midY), 12)
        XCTAssertGreaterThan(title.frame.minX, back.frame.maxX)

        let role = app.textFields["task.role"]
        XCTAssertTrue(role.waitForExistence(timeout: timeout))
        let fieldWidth = role.frame.width
        let save = app.buttons["task.save"]
        XCTAssertTrue(revealHittable(save, in: app))
        // A button that fills a Form row reports the whole row as its frame, wider than the inset field.
        XCTAssertGreaterThanOrEqual(save.frame.width, fieldWidth - 8, "Add task spans its row")
        capture(app, "tasks-add-task-sheet")
        back.tap()
        XCTAssertTrue(waitForDisappearance(back))
    }

    func testTaskDetailsKeepOneTitleAndOneLineDeleteMessage() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()
        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reduced manual search time'")).firstMatch
        XCTAssertTrue(revealHittable(task, in: app))
        task.tap()
        let edit = app.buttons["task.edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: timeout))
        // Reading, the sheet's title is the only "Task details": the section no longer repeats it.
        let detailsTitles = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'Task details'"))
        XCTAssertEqual(detailsTitles.count, 1)
        capture(app, "task-detail")

        edit.tap()
        let titleField = app.textFields["Task title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: timeout))
        let fieldWidth = titleField.frame.width
        let save = app.buttons["task.detail.save"]
        XCTAssertTrue(revealHittable(save, in: app))
        XCTAssertGreaterThanOrEqual(save.frame.width, fieldWidth - 8, "Save changes spans its row")
        capture(app, "task-detail-edit")
        app.buttons["Cancel"].tap()

        XCTAssertTrue(tapWhenHittable(app.buttons["task.delete"], in: app))
        let alert = app.alerts["Confirm delete"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
        XCTAssertTrue(alert.staticTexts["This can’t be undone."].exists)
        capture(app, "task-detail-delete-alert")
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(waitForDisappearance(alert))
        XCTAssertTrue(edit.exists, "Cancel keeps the task")
        app.buttons["Done"].tap()
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

    func testProgressWidgetsCanBeAddedAndReset() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-resume-format-fixture"]
        app.launch()

        let recent = app.descendants(matching: .any)["tasks.metric.recentTasks"]
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.resumeUsage"].waitForExistence(timeout: timeout))
        XCTAssertFalse(recent.exists)

        // Back closes the editor without saving, so the added widget doesn't reach Tasks.
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.edit"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.add.recentTasks"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metrics.shown.recentTasks"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["tasks.metrics.done"].exists)
        let back = app.buttons["tasks.metrics.back"]
        XCTAssertTrue(back.exists)
        back.tap()
        XCTAssertTrue(waitForDisappearance(back))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.resumeUsage"].waitForExistence(timeout: timeout))
        XCTAssertFalse(recent.exists)

        // Save sits below Reset to default, at the same full width, and applies the change.
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.edit"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.add.recentTasks"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metrics.shown.recentTasks"].waitForExistence(timeout: timeout))
        let reset = app.buttons["tasks.metrics.reset"]
        let save = app.buttons["tasks.metrics.save"]
        XCTAssertTrue(revealHittable(save, in: app))
        XCTAssertTrue(reset.isEnabled)
        XCTAssertLessThanOrEqual(reset.frame.maxY, save.frame.minY)
        XCTAssertEqual(reset.frame.width, save.frame.width, accuracy: 1)
        XCTAssertGreaterThan(save.frame.width, app.navigationBars["Progress widgets"].frame.width * 0.75, "Save spans the sheet")
        capture(app, "tasks-widget-editor")
        save.tap()
        XCTAssertTrue(recent.waitForExistence(timeout: timeout))
        XCTAssertTrue((recent.value as? String ?? "").contains("1 task recorded"))

        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.edit"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.reset"], in: app))
        XCTAssertTrue(tapWhenHittable(app.buttons["tasks.metrics.save"], in: app))
        XCTAssertTrue(app.descendants(matching: .any)["tasks.metric.companyMix"].waitForExistence(timeout: timeout))
        XCTAssertFalse(recent.exists)
    }
}
