# Roadmap

Work that is already identified, in three buckets: Now, Next, and Later. There are no release dates on record, so the buckets set an order, not a schedule. Each item says why it matters and links to where it was identified. What CVee does today is in [README.md](README.md); shipped changes are in [CHANGELOG.md](CHANGELOG.md).

## Now

- **Land the documentation cleanup (passes 1 and 2).** Why: the docs described Apple-only AI, which the Sept 5 audit flagged as contradicting the provider workflow, and pasted-only job entry; README.md, AGENTS.md, PRODUCT.md, and PromptSpec.md now match the code, and this file, CHANGELOG.md, and [design-audit/README.md](design-audit/README.md) are new. Source: [audit report](design-audit/2026-09-05-cvee-uiux-audit/REPORT.md) (P2, "Documentation contradicts the implemented provider workflow"); [fix plan](design-audit/2026-09-05-cvee-uiux-audit/FIX-PLAN.md) (batch 4, item 4).
- **Commit the Sept 30 refinement and the Oct 9 mascot and progress widgets.** Why: both exist only as uncommitted changes on `claude/tasks-mascot-widgets`, whose last commit is from Sept 14, and the current tests (24 UI, 25 unit) have no recorded full run; the last recorded full run (iPhone, Sept 30) had 23 UI and 19 unit tests, and that day's iPad run covered 3 UI tests. When the UI/UX thread finishes the Oct 9 work, run `scripts/test-ios.sh` on iPhone and iPad, then commit. Source: [CHANGELOG.md](CHANGELOG.md#unreleased-not-yet-committed); [Sept 30 report](design-audit/2026-09-30-uiux-refinement/REPORT.md) ("Verification").
- **Pass 3, once the UI/UX thread is done with DESIGN.md.** Why: DESIGN.md was left untouched in passes 1 and 2 because that thread owns it, and the dropped redesign spec is still in the folder. Source: [DESIGN.md](DESIGN.md); [CanvaRedesignSpec.md](CanvaRedesignSpec.md).
  - Delete `CanvaRedesignSpec.md` (the TalentEdge redesign is dropped) and every link to it, including the source links under Next and Later below, which then remain the only record of those ideas. Leave `.mcp.json` as it is.
  - Move DESIGN.md's two dated sections, "Workflow Refinement — September 30, 2026" and "Mascot and Progress Widgets — October 9, 2026", into CHANGELOG.md, which already summarizes them under Unreleased. First fold the lasting rules they hold into DESIGN.md's main sections, because most are written down only there: for example empty-state actions, deletion confirmation, the mascot and speech bubble, widget layout, chart colors, and Saved Jobs chevrons.
  - Re-read DESIGN.md against the code. Known mismatches:
    - "monospaced body style for text export previews": there is no text export; monospaced text is used in the wizard's LaTeX editor, the LaTeX import sheet, and a resume's original source.
    - "the full row opens editing": a task row opens a read-only detail sheet, and editing starts from Edit.
    - "Empty libraries offer their next action": the Tasks empty state itself has no action button; quick capture sits above it.
    - "At accessibility sizes, secondary actions stack": the generated-step actions stack whenever they do not fit, at any text size.
    - Step guidance is hidden "while an identity field has keyboard focus": it is hidden while any wizard field has focus, including the generated-resume editor.
    - "Coral primary actions use charcoal labels in both themes": disabled buttons use the adaptive ink color, which is light in dark mode.
    - "provider processing location in separate review rows": the provider and processing location are in their own "AI processing" section with a "Configure AI provider" button, not in a review row.
- **Capture the states the audits left unverified.** Why: the Sept 5 review stays open until the iPad Profile and readable-width captures exist (the earlier iPad "Profile" capture shows Resumes), and the fix plan asks for rendered light and dark checks and annotated provider screens. Needed: iPad Profile; wide iPad reading width; the provider, model picker, key sheet, and error states, and the destructive confirmations (the Sept 30 report has one capture, of a cancelled task deletion); dark mode beyond Tasks and the wizard (dates, empty states, API-key status, coral button ink); and the Oct 9 Tasks layout on iPad, since the Oct 9 set is five iPhone screens. Source: [REVIEW.md](design-audit/REVIEW.md) (disposition); [fix plan](design-audit/2026-09-05-cvee-uiux-audit/FIX-PLAN.md) (batch 4, items 1 and 3); [screenshot index](design-audit/2026-09-05-cvee-uiux-audit/SCREENSHOT-INDEX.md) ("Missing captures").

## Next

- **Keep the wizard draft across an app relaunch.** Why: wizard recovery is limited to the current session, so a generated resume that has not been saved is lost on relaunch, while the Tasks quick-capture draft and the Add job draft already survive one. Source: [Sept 30 report](design-audit/2026-09-30-uiux-refinement/REPORT.md) ("Recovery remains limited to the current session").
- **Accessibility and adaptivity pass on every tab.** Why: manual VoiceOver traversal, Reduce Transparency, and narrow iPad windows are still unverified, and the UI tests check landscape, and large text with the keyboard shown, only in the wizard, plus one dark large-text Tasks layout. Source: [fix plan](design-audit/2026-09-05-cvee-uiux-audit/FIX-PLAN.md) (batch 2, item 1); [Sept 30 report](design-audit/2026-09-30-uiux-refinement/REPORT.md) ("Visual evidence"); [REVIEW.md](design-audit/REVIEW.md) (VoiceOver, landscape, and Split View "not exercised"); [coverage](design-audit/2026-09-05-cvee-uiux-audit/COVERAGE.md) (Reduce Transparency unverified).
- **Review the navigation and tab bar materials, including Liquid Glass.** Why: both bars still use a page-colored background (`.toolbarBackground` in `ContentView.swift`), and the fix plan asks to review that against current system materials, adopting Liquid Glass only where it improves hierarchy without replacing CVee's identity. Source: [fix plan](design-audit/2026-09-05-cvee-uiux-audit/FIX-PLAN.md) (batch 4, item 2); [audit report](design-audit/2026-09-05-cvee-uiux-audit/REPORT.md) (P2, "custom page-colored bars").
- **DOCX and TXT export.** Why: Resumes exports PDF and RTF only, and the dropped redesign proposal listed DOCX and TXT export as not yet implemented. Source: [CanvaRedesignSpec.md](CanvaRedesignSpec.md) ("Relationship to the current app").

## Later

- **Markdown upload.** Why: no import reads Markdown (task import takes PDF, TXT, or DOCX; resume baselines take a PDF or a saved resume; job capture takes PDF, DOCX, TXT, or images). Source: [CanvaRedesignSpec.md](CanvaRedesignSpec.md) ("Start or import").
- **Language settings.** Why: the app has no language setting, the Xcode project lists English as its only language, and the interface text is written in English in the code. Source: [CanvaRedesignSpec.md](CanvaRedesignSpec.md) ("Settings").
- **A SwiftData migration plan.** Why: there is none, and if the on-disk store cannot be opened the app silently falls back to an empty in-memory store; a code comment defers the plan "when schema history stabilizes". Source: [CVee_resumebuilderApp.swift](CVee-resumebuilder/CVee_resumebuilderApp.swift).

The redesign proposal also listed API provider choice and a separate resume editor and preview. Both exist today (see [README.md](README.md)), so they are not on this list.

## Open questions

- **Release target.** No release date, version plan, or App Store plan is on record. The app is version 1.0 (build 1), and CI already runs on `v*` tags. Source: [ios-tests.yml](.github/workflows/ios-tests.yml); [project.pbxproj](CVee-resumebuilder.xcodeproj/project.pbxproj) (`MARKETING_VERSION`).
- **Should "Check job match" on a saved resume read the structured document?** It reads the text from the last wizard save, so later edits in the section editor are not checked, and editable copies and LaTeX imports have no text to check. Source: [README.md](README.md#resume-report).
- **Should the App Shortcuts open a specific tab?** "Create a New Resume" and "Open Work History" both only open the app, so a cold launch shows Tasks, not the wizard. Source: [CVeeIntents.swift](CVee-resumebuilder/CVeeIntents.swift).

## Housekeeping

- **Ignore or remove local build output.** The project folder holds `build/`, `.derivedData/`, `ci-diagnostics/`, and `TestResults-*.xcresult`. [.gitignore](.gitignore) covers `.derivedData/`, `TestResults.xcresult/`, `TestResults-*.xcresult/`, and `ci-diagnostics/`, but not `build/` or `.playwright-cli/`.
- **Correct the test script's messages.** `scripts/test-ios.sh` prints "Building UI tests" and "Running UI tests" although it runs both the unit and UI test targets. No other defect is on record: the exit code 70 in the Sept 5 fix plan came from CoreSimulator being unavailable in that environment, and REVIEW.md records a passing run of the script on iPhone 17. Source: [test-ios.sh](scripts/test-ios.sh); [fix plan](design-audit/2026-09-05-cvee-uiux-audit/FIX-PLAN.md) ("Implementation status"); [REVIEW.md](design-audit/REVIEW.md) ("Final verification update").
- **Remove or use dead code.** `LinkedInJobFetcher.fetch`, the `.linkedInURL` job source type, the `Resume.template` value (always `"jakes"`), and the `ResumePrompt.parseResumeSystem` and `ResumePrompt.tailorSystem` prompts are never used. Source: [CVeeCore.swift](CVee-resumebuilder/CVeeCore.swift).
