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
        group.tap()
        XCTAssertFalse(task.exists)
        group.tap()
        XCTAssertTrue(task.waitForExistence(timeout: timeout))
        let add = app.buttons["tasks.add"]
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

    func testTaskCreationImportAndClearConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.buttons["tasks.add"].tap()
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
        app.buttons["tasks.add"].tap()
        app.buttons["Import Tasks List"].tap()
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
        XCTAssertTrue(app.buttons["tasks.add"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["tasks.add"].isHittable)
        XCTAssertTrue(app.buttons["tasks.company-section"].firstMatch.isHittable)
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
        let saveRequirements = app.buttons["analysis.save-requirements"]
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
        return element.waitForExistence(timeout: timeout) && element.isHittable && element.isEnabled
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
