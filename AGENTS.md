# AGENTS.md

## Project overview

CVee is a SwiftUI resume workspace for iPhone and iPad with five tabs. [README.md](README.md) is the home of the feature list, the five tabs, the import and generation limits, and the build and test steps; read it before changing behavior. SwiftData stores work experiences, job targets (the ways to add one are in [README.md](README.md#app-functionality)), and resumes (a structured JSON document, plus RTF sections on wizard saves and older resumes); profile fields use `@AppStorage`. Resume generation, task import splitting, and task enhancement go through one provider router, `AITextGenerationService` in `AIProviders.swift`: Apple Intelligence on the device with Foundation Models, or OpenAI, Gemini, or Claude with the user's API key from the Keychain. The resume report's AI suggestions use Apple Intelligence only.

## Documentation map

Each fact lives in one file; other files link to it.

| File | What it holds |
|---|---|
| [README.md](README.md) | What CVee does today: features and the five tabs, AI providers, the resume report, import and generation limits, data and platform, build and test. |
| [PRODUCT.md](PRODUCT.md) | Purpose, principles (the facts-only rule, privacy and provider choice, accessibility), and non-goals. |
| [AGENTS.md](AGENTS.md) | This file: documentation map, development guardrails, and verification. |
| [DESIGN.md](DESIGN.md) | Design tokens and component rules. |
| [PromptSpec.md](PromptSpec.md) | The prompts CVee sends to AI providers, the generation quality bar, and the AI runtime contract. |
| [ROADMAP.md](ROADMAP.md) | Now / Next / Later, open questions, and housekeeping. |
| [CHANGELOG.md](CHANGELOG.md) | Dated history of shipped changes, newest first. |
| [design-audit/](design-audit/README.md) | Archive of design audits, reviews, and screenshots, indexed in `design-audit/README.md`. Evidence, not current specs. |

Markdown files not listed here are not current references; do not follow or update them.

When a fact changes, update the file that owns it and link to it elsewhere instead of repeating it. Record shipped changes in CHANGELOG.md.

## Project structure

- `CVee-resumebuilder/` — SwiftUI app source and assets.
  - `ContentView.swift` — the tab shell and the screens of all five tabs, including the resume report sheet.
  - `CVeeCore.swift` — SwiftData models, generation, task import and enhancement services, text formatting, and PDF/RTF export.
  - `AIProviders.swift` — provider and model choice, Keychain key storage, and the provider router.
  - `JobCapture.swift` — job and task capture drafts, job capture limits, document and screenshot extraction, share inbox import, duplicate detection, and URL fetching.
  - `StructuredResume.swift`, `StructuredResumeEditor.swift` — the structured resume document, converter, renderer, LaTeX import, and section editor.
  - `ResumeAnalysis.swift` — phrase coverage, document health, and Apple Intelligence suggestions for the resume report.
  - `TaskMetrics.swift` — the Tasks progress widgets.
  - `Mascot.swift` — the dog mascot, its animation, and its speech bubble, used on Tasks (leaning on the quick capture card) and Saved Jobs.
  - `CVeeIntents.swift` — App Shortcuts.
  - `CVee_resumebuilderApp.swift` — app entry, model container, and test launch arguments.
- `ShareExtension/`, `ShareExtension-Info.plist` — the "Save to CVee" share extension.
- `CVee-resumebuilderTests/` — unit tests. `CVee-resumebuilderUITests/` — UI tests.
- `CVee-resumebuilder.xcodeproj/` — Xcode project.
- `scripts/test-ios.sh`, `.github/workflows/ios-tests.yml`, `.swiftlint.yml` — test runner, CI workflow, and lint configuration.

## Development guidance

- Use Xcode and the project's existing build settings; do not add external dependencies without a clear need. ZIPFoundation is currently the only package.
- Keep app UI changes in SwiftUI (the share extension's small UI is UIKit) and preserve accessibility labels and hints for interactive controls.
- Keep persistence changes compatible with the existing SwiftData models and update the model container schema when adding models. The schema is listed in `CVee_resumebuilderApp.swift` and repeated in the `ContentView.swift` previews and `ResumeRenderingTests.swift`. There is no migration plan, and if the on-disk store cannot be opened the app silently falls back to an in-memory store.
- Route generation, task import splitting, and task enhancement through `AITextGenerationService` so the user's provider choice holds. Keep the Foundation Models availability guards for Apple, keep remote providers as explicit choices with no automatic fallback, and keep API keys in the Keychain through `APIKeyStore` (its UserDefaults path is only for `-ui-testing`). The privacy and provider-choice principle is in [PRODUCT.md](PRODUCT.md).
- Generated and suggested content follows the facts-only rule in [PRODUCT.md](PRODUCT.md).
- Follow [PromptSpec.md](PromptSpec.md) when changing generation prompts or resume rendering, and update the matching prompt text there in the same change so it matches the code.
- Describe features in [README.md](README.md) only as the code implements them. Some code is present but unused, for example `LinkedInJobFetcher.fetch` and the `Resume.template` value (always `"jakes"`).

## Verification

- Build the `CVee-resumebuilder` scheme in Xcode after source changes.
- Run `scripts/test-ios.sh`, which runs both the unit and UI test targets (set `IOS_DEVICE_FAMILY=iPad` for iPad), or run the test targets in Xcode. CI also runs `swiftlint lint --config .swiftlint.yml --strict`; see [README.md](README.md#build-and-test). Exit code 70 means `xcodebuild` could not list simulator destinations (for example, CoreSimulator is unavailable); report that instead of treating it as a test result.
- Test work-history editing/import, generation availability messaging, AI provider configuration, saved jobs/resumes, clear-all confirmation, and PDF/RTF export with Xcode tests and Simulator checks when applicable.
- No automated test covers the share extension and inbox import, URL fetching, document and screenshot job import, real AI output from any provider (Apple Intelligence or remote; tests use canned results), real Keychain storage, App Shortcuts, section editor interactions (adding, hiding, reordering, undo), actually clearing all data, or the mascot animation. Check these by hand in the Simulator or on a device when a change touches them.
- UI tests launch with `-ui-testing`: an in-memory store, cleared UserDefaults (unless `-ui-testing-preserve-drafts`), API keys in UserDefaults, and canned generation and task import results in DEBUG builds. The other fixture and failure arguments are defined in `CVee_resumebuilderApp.swift`, `CVeeCore.swift`, and `ContentView.swift`. Only the canned generation and task import results are limited to DEBUG builds; every other test argument, including `-mock-data` (30 sample tasks) and the `-ui-testing-ai*` enhancement stubs, works in any build. Quick capture starts as a collapsed card, so tests that type into it open it first with the `expandTaskCapture` helper.
- Use web search for external research and current documentation; do not use Playwright for general web research.
- Use Playwright only when testing the live website, and capture screenshots of those browser-based test states as artifacts for review.
- For native-only SwiftUI behavior, use XCUITest and Simulator screenshots rather than Playwright.
- Prefer focused changes and avoid modifying generated Xcode user-data files.
