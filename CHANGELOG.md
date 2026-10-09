# Changelog

Dated history of shipped changes, newest first. Dated entries come from the git history (commit dates) and the dated reports in [design-audit/](design-audit/README.md); pull request numbers come from merge commits. What CVee does today is in [README.md](README.md); planned work is in [ROADMAP.md](ROADMAP.md).

## Unreleased (not yet committed)

This work is in the working tree of branch `claude/tasks-mascot-widgets`, after its last commit (2026-09-14). Until pass 3 in [ROADMAP.md](ROADMAP.md), [DESIGN.md](DESIGN.md) also keeps a dated section for each part.

### Mascot and progress widgets (2026-10-09, in progress)

Still being built and tested. Captures: [design-audit/2026-10-09-mascot-widgets/](design-audit/2026-10-09-mascot-widgets/).

- A dog mascot with a speech bubble at the top of Tasks: curious with first-use guidance while the library is empty, joyful for six seconds after a task is recorded with quick capture, and otherwise a wink with the number of tasks ready to reuse. At accessibility text sizes the dog sits above the bubble.
- The mascot animation plays twice, then rests on a still image. Reduce Motion or turning off animated images shows only the still. The mascot is hidden from accessibility, and the bubble is read as one element.
- "Your progress" widgets below quick capture: Tasks by company (a donut chart of the top four companies plus Other) and Used in resumes (the share of tasks linked to a saved resume) by default; Resumes saved, Jobs ready, and Last 30 days can be added. Edit adds, removes, and reorders them, and the layout is saved in `tasks.metricWidgets`.
- Data-only chart colors `chart1` to `chart4` (teal, purple, ochre, magenta).
- Saved Jobs rows end with a chevron.
- New tests: six `TaskMetricsTests` unit tests and a UI test that adds and resets widgets.

### UI/UX refinement (2026-09-30)

Details and test results: [design-audit/2026-09-30-uiux-refinement/REPORT.md](design-audit/2026-09-30-uiux-refinement/REPORT.md).

- The wizard keeps its draft (generated text, LaTeX edits, and selections) across Back and tab navigation, for the current session only.
- Replacing an unsaved draft and Start over ask for confirmation. A failed regeneration keeps the previous draft.
- Saving uses the current edited text, a retry after a failed save reuses the same record instead of creating a duplicate, and success is reported only after the save persists.
- Preview, reopened resumes, and exports use the same document conversion. Exporting from the saved editor saves pending changes first.
- The wizard explains why an action is blocked, opens a job that is not ready in its existing review sheet, gives each review input its own Edit action, and shows the provider and where processing happens. Errors appear first on the review and draft steps, and Return to draft appears before the review fields.
- First-use guidance in Tasks, "Create resume" on an empty Resumes list, and add or clear actions for empty job lists and no-result searches. New profile names start blank.
- Deleting a task, job, or resume asks for confirmation, and save and delete failures are shown. Clear all data resets the wizard after it succeeds.
- Accessibility: persistent field labels, keyboard dismissal in the wizard's navigation bar, wizard actions in the bottom safe area, adaptive status colors, and adaptive ink on disabled buttons.
- Fixed a responder and view-graph cycle by replacing the PDFKit document outside the SwiftUI view update.
- No new dependencies, models, schema migrations, or generation prompt changes.
- UI tests now save through real persistence and cover draft recovery, cancelled replacement and reset, failed regeneration, save retry, job repair, provider configuration, first use, and large text with landscape.
- Final runs: iPhone passed 42 tests (23 UI, 19 unit) and iPad passed 3 UI tests. Manual VoiceOver traversal and narrow iPad windows were not verified.

## 2026-09-14

- Stabilized the iPad task capture tests.

## 2026-09-13

- Tasks tab UX improvements and refined Tasks tab interactions.
- Merged pull request #3 (`codex/resume-wizard-ux-followup`).

## 2026-09-09

- Merged pull request #1 (`codex/resume-wizard-ux`) and pull request #2 (`codex/resume-wizard-ux-followup`).
- Requirement phrase entry: a stable save action, a bounded wait before tapping save, and a stabilized entry test.
- Test and CI stability: resume wizard SwiftData and CI tests, deterministic simulator destinations, waiting for the simulator to be ready, no synchronous fixture persistence in UI tests, and more time for the hosted iPad simulator.

## 2026-09-08

- Kept requirement review responsive.
- The coverage summary UI test finds the summary by its label.

## 2026-09-07

- The selected AI provider persists.
- Accessibility fixes for resume analysis, its coverage display, and export.
- Placed the save action beside job match.
- Refined the resume wizard UX and cleared Xcode warnings.

## 2026-09-06

- Added the structured resume editor.
- Added job capture and the share extension, merged the same day.
- Refined the resume analysis and wizard flows.
- Fixed blank resume previews.
- Stored API keys require device authentication to read. A follow-up commit is titled "Expose Keychain access control to Sonar".
- Added the app icon and launch screen, and shortened the display name to CVee.
- UI test fixes: general iOS test stability, iPad tab navigation, and removal of a flaky email visibility assertion.

## 2026-09-05

- Fixed resume preview editing and export layout.
- AI provider choice, with remote providers alongside Apple Intelligence, was already in the uncommitted working tree that the day's design audit examined. No commit message names when it was added.
- Native finish review ([design-audit/REVIEW.md](design-audit/REVIEW.md)), provisional score 13/20. Its iPhone corrections then passed (the verdict pass is undated): darker wizard prompts and saved-job and resume dates, a required name and email hint above the first field, and new captures confirming the charcoal dark appearance and contained decorative glyphs. The score rose to 15/20.
- Design audit ([design-audit/2026-09-05-cvee-uiux-audit/](design-audit/2026-09-05-cvee-uiux-audit/REPORT.md)), with part of each of its four fix batches implemented the same day (the items still open are in [ROADMAP.md](ROADMAP.md)):
  - Wizard swipes required a mostly horizontal drag. The current code has no wizard swipe.
  - API-key actions stack at accessibility text sizes, with hints for save and delete, and a UI test covers cancelling a provider key.
  - Shared surfaces dismiss the keyboard interactively.
  - The commit actions on Profile, task detail, job detail, Add job, and Add task use the coral primary style.
  - Saved-job detail dates use the secondary color, and the floating Add action has a spoken hint.
  - The fixes were checked only by Swift parsing and `git diff --check`: `scripts/test-ios.sh` exited 70 because CoreSimulator was unavailable in that environment.

## 2026-09-04

- Refined the resume wizard progress states.

## 2026-09-02

- Added the iOS XCUITest GitHub workflow. SwiftLint and CI also run on release tags.
- CI simulator fixes: a compatible iOS 26 simulator, any available iPhone simulator, Xcode-aware destination selection, and a fixed simulator test environment.
- Repaired the UI test target and CI execution, and stabilized the resume wizard UI test identifiers.

## 2026-09-01

- Implemented the Typeform-style resume wizard and ATS-oriented resume generation.
- Added a concise project README.

## 2026-07-22

- Initial commit.
