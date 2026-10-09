# CVee UI/UX refinement — 30 September 2026

## Implemented

- Session-local wizard recovery retains generated text, LaTeX edits and selections across Back and tab navigation. Replacement and reset require confirmation; regeneration failures retain the previous draft.
- Saving converts the current edited content, reuses an inserted record on retry and reports success after persistence. Structured preview, reopened documents and exports use the same document conversion pipeline.
- Wizard prerequisites explain blocked actions. Unreviewed jobs open their existing review sheet. Summary rows expose individual Edit actions and disclose the selected provider and processing location.
- Tasks explain reusable achievements for first use; empty Resumes opens the wizard. Empty job libraries and searches expose appropriate add/clear actions. New profile names start blank.
- Task, job and resume deletion require confirmation. Save/deletion failures are surfaced. Clear All retains its confirmation and resets the active wizard after successful persistence.
- Persistent input labels, keyboard controls, safe-area wizard actions, adaptive status colors and shared native surfaces improve accessibility while retaining the coral/charcoal identity, five tabs and 760-point content limit.
- PDF previews retain rendered data until content changes. PDFKit document replacement is deferred outside SwiftUI's view update to avoid a responder/view-graph cycle discovered during live testing.

No dependencies, models, schema migrations or generation prompt changes were introduced. Recovery remains limited to the current session. Provider choices remain explicit; job analysis remains advisory phrase coverage.

## Verification

The final iPhone regression passed **42 tests: 23 XCUITests and 19 unit tests, zero failures**. The iPad run passed **3 XCUITests, zero failures**. Builds succeeded for both devices. Static Swift parsing with the project's bare-slash regex support and `git diff --check` passed.

The expanded task/job/resume deletion-cancellation check also passed after the full run; [task cancellation capture](task-delete-cancelled.png).

Result summaries: [iPhone](iphone-test-summary.json), [iPad](ipad-test-summary.json). Full result bundles remain at `/private/tmp/cvee-ux-regression.xcresult` and `/private/tmp/cvee-ux-ipad-final.xcresult`. Verification used the project's existing scheme and test targets with serial Simulator execution and `CODE_SIGNING_ALLOWED=NO`; no browser tests or new testing dependencies were added.

Earlier runs passed all 19 unit tests, including actual SwiftData persistence and PDF/RTF content assertions. An earlier full UI run passed 18 of 23 tests; five failures drove keyboard, confirmation dismissal, navigation synchronization and PDFKit fixes. The final full run above supersedes those failures.

New deterministic UI coverage exercises navigation recovery, cancelled replacement/reset, failed regeneration, failed-save retry without duplicate records, edited content after reopening, job repair, provider configuration, first-use navigation and large-text/landscape layouts. The generated-resume save shortcut was removed so these flows use real persistence.

Focused reruns passed all affected flows: draft recovery and save retry, generated preview/save/reopen/export, job repair/provider configuration, first use, large Dynamic Type, deletion cancellation and task recording. The final recovery test completed in 72 seconds without duplicate records or lost edits. Three iPad tests passed: first-use navigation/accessibility audit, large-text keyboard/landscape and wizard Back navigation. All 19 unit tests also passed after the content/persistence changes.

Automated accessibility audits cover hit regions and element detection. Token contrast calculations give 5.38:1 for light green status text, 8.61:1 for dark green, 5.85:1/7.79:1 for light/dark action ink, and 5.48:1 for enabled primary-button text. Disabled buttons use adaptive ink rather than dark text on a dim dark-theme background.

## Visual evidence

Archived before-change references are in `../2026-09-05-cvee-uiux-audit/` and `../iphone-reviewed/`. The `initial-*.png` images here are intermediate captures from the first validation run, before its keyboard/action-layout fixes; they are deliberately not labelled final screenshots.

Passing-flow captures:

- [First-use guidance](first-use-tasks.png) and [required-field guidance](first-use-wizard-validation.png).
- [Draft after editing](resume-preview-after-edit.png) and [saved/reopened recovery](draft-recovered-saved-reopened.png).
- [Dark large-text keyboard](wizard-dark-large-text-keyboard.png) and [landscape](wizard-dark-large-text-landscape.png).
- [Repaired job with selection retained](wizard-job-repaired-selection-retained.png).
- [iPad required fields](ipad-first-use-wizard-validation.png), [keyboard](ipad-wizard-dark-large-text-keyboard.png) and [landscape](ipad-wizard-dark-large-text-landscape.png).

The intermediate [keyboard capture](initial-keyboard-dark-large.png) shows the toolbar/action overlap fixed by moving keyboard dismissal to the top navigation bar. The intermediate [draft capture](initial-draft-actions.png) shows actions below the document before they moved into the safe-area bar. Captures taken immediately after repeated Edit/Preview toggles can contain native transition frames; the saved/reopened capture is stable.

Narrow iPad window resizing remains unverified: the runtime UI snapshot exposed no interaction targets, and the native Simulator frontend control timed out. Manual VoiceOver traversal remains unverified. Automated accessibility checks do not substitute for either check. No additional iPad layout was introduced.

## Acceptance measures

- The first-resume journey completes with capture, reviewed job, generation, edit, save, reopen and PDF/RTF export.
- Edited sentinel text remains present after navigation, failed replacement, save/reopen and document export assertions.
- A save retry creates one generated resume, rather than duplicate records.
- Missing prerequisites always expose the required next action; repair/settings sheets preserve wizard selections.
- Actions remain reachable with the keyboard, large Dynamic Type and landscape, with readable light/dark labels.

Measure product improvement through first-resume completion rate, time to first saved resume and prerequisite-related abandonment. No analytics or backend was added as part of this refinement.
