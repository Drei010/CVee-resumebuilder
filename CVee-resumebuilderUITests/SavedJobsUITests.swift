import XCTest
import UIKit

/// Saved Jobs: its mascot, search, filters, and screenshot import.
final class SavedJobsUITests: CVeeUITestCase {
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

    func testAddJobScreenshotsOfferPhotosAndFiles() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        selectTab("Saved Jobs", in: app)
        let add = app.buttons["Add saved job"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: timeout))
        add.tap()
        let screenshots = app.buttons["Import screenshots"]
        XCTAssertTrue(screenshots.waitForExistence(timeout: timeout))
        let tip = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Show more under About the job'")).firstMatch
        XCTAssertFalse(tip.exists, "Only screenshot capture explains how to take LinkedIn screenshots")
        screenshots.tap()
        // Screenshots come from Photos, in the order they're picked, or from Files, with a tip on taking them in LinkedIn.
        XCTAssertTrue(app.buttons["Choose from Photos"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Choose from Files"].exists)
        XCTAssertTrue(tip.waitForExistence(timeout: timeout))
        capture(app, "add-job-screenshots")
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
}
