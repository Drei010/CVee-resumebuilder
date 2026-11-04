import XCTest
import UIKit
import Vision

/// The shared timeout and helpers for CVee's UI tests. Each subclass covers one area of the app,
/// because xcodebuild shards and parallelizes tests by class.
class CVeeUITestCase: XCTestCase {
    let timeout: TimeInterval = 10

    /// The app element reports no size class to XCUITest, so tell iPhone from iPad by the device idiom.
    var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }

    func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Quick capture starts as a collapsed action card; open it unless a restored draft already did.
    func expandTaskCapture(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let details = app.textFields["tasks.capture-details"]
        let card = app.buttons["tasks.capture-card"]
        if !details.exists, card.waitForExistence(timeout: timeout) {
            card.tap()
        }
        XCTAssertTrue(details.waitForExistence(timeout: timeout), file: file, line: line)
        return details
    }

    /// The task list shows one company section, for `company`, holding `taskCount` tasks.
    func assertOnlyCompanySection(_ company: String, taskCount: Int, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let sections = app.buttons.matching(identifier: "tasks.company-section")
        let match = sections.matching(NSPredicate(format: "label CONTAINS %@", company)).firstMatch
        XCTAssertTrue(match.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(match.label.contains("\(taskCount)"), "Section '\(match.label)' should count \(taskCount) tasks", file: file, line: line)
        XCTAssertEqual(sections.matching(NSPredicate(format: "NOT (label CONTAINS %@)", company)).count, 0, file: file, line: line)
    }

    func waitForDisappearance(_ element: XCUIElement) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter.wait(for: [gone], timeout: timeout) == .completed
    }

    func selectTab(_ name: String, in app: XCUIApplication) {
        if name == "Profile", app.frame.width > 600, app.buttons["Next Page"].exists {
            app.buttons["Next Page"].tap()
        } else if app.frame.width > 600, app.buttons["Previous Page"].exists {
            app.buttons["Previous Page"].tap()
        }
        app.buttons[name].firstMatch.tap()
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: timeout))
    }

    func fillWizardProfile(in app: XCUIApplication) {
        selectTab("Resume Wizard", in: app)
        let name = app.textFields["wizard.full-name"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        name.tap(); name.typeText("Test User\n")
        let email = app.textFields["wizard.email"]
        XCTAssertTrue(revealBelow(email, in: app))
        email.tap(); email.typeText("test@example.com")
        dismissKeyboard(in: app)
    }

    func dismissConfirmation(_ label: String, in app: XCUIApplication) {
        if app.buttons[label].firstMatch.waitForExistence(timeout: 1) { app.buttons[label].firstMatch.tap() }
        else {
            let close = app.buttons["Close"].firstMatch
            XCTAssertTrue(close.waitForExistence(timeout: timeout))
            close.tap()
        }
    }

    func generateFixture(in app: XCUIApplication) {
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

    func wizardTaskRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wizard.task.'"))
    }

    /// Selects the first Work Library task by tapping its row, the only way to select on Experience.
    func selectFirstWizardTask(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let task = wizardTaskRows(in: app).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: timeout), file: file, line: line)
        task.tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: timeout), file: file, line: line)
    }

    func assertPreviewContainsText(_ app: XCUIApplication, _ preview: XCUIElement, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
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

    func reveal(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<5 {
            if element.waitForExistence(timeout: 2) { return true }
            app.swipeDown()
        }
        return element.waitForExistence(timeout: timeout)
    }

    /// Scrolls in short, slow drags until the element exists and can be tapped. Slow drags don't
    /// coast, so the Tasks search header and rows below the mascot and progress widgets aren't
    /// flung past. If an element ends up above the middle of the screen, it drags back down.
    func revealHittable(_ element: XCUIElement, in app: XCUIApplication, steps: Int = 8) -> Bool {
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

    func revealBelow(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<5 {
            if element.waitForExistence(timeout: 2) { return true }
            app.swipeUp()
        }
        return element.waitForExistence(timeout: timeout)
    }

    func tapWhenHittable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
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

    func tapAction(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if app.frame.width < 700 {
            guard element.waitForExistence(timeout: timeout) else { return false }
            element.tap()
            return true
        }
        return tapWhenHittable(element, in: app)
    }

    func dismissKeyboard(in app: XCUIApplication) {
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
