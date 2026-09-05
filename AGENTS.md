# AGENTS.md

## Project overview

CVee is a SwiftUI iOS resume workspace with five tabs: Tasks, Saved Jobs, Resume Wizard, Resumes,
and Profile. SwiftData stores work experiences, pasted-text job targets, resumes, and RTF-backed
resume sections; profile fields use `@AppStorage`. The core layer includes a LinkedIn HTML fetcher,
but the current job-entry UI exposes pasted descriptions only. Foundation Models provide on-device
resume generation, task import splitting, and task enhancement on supported iOS 26 devices.

## Project structure

- `CVee-resumebuilder/` — SwiftUI app source and assets.
- `CVee-resumebuilder.xcodeproj/` — Xcode project.
- `PromptSpec.md` — resume-generation and task-AI quality bar plus runtime contract.
- `CanvaRedesignSpec.md` — append-only future redesign proposal; it is not the native app contract.

## Development guidance

- Use Xcode and the project’s existing build settings; do not add external dependencies without a clear need.
- Keep UI changes in SwiftUI and preserve accessibility labels and hints for interactive controls.
- Keep persistence changes compatible with the existing SwiftData models and update the model container schema when adding models.
- Preserve the on-device-only generation, task analysis, and task enhancement behavior and their availability guards for Foundation Models.
- Resume content must use only facts supplied by the user’s work history and target job; never fabricate metrics, employers, dates, technologies, or credentials.
- Follow `PromptSpec.md` when changing generation prompts or resume rendering.

## Canva MCP audit

- The project-level Canva MCP configuration is in `.mcp.json` and uses Canva’s official endpoint: `https://mcp.canva.com/mcp`.
- Use Claude Code’s MCP flow to authenticate/approve the Canva connector before auditing or editing the shared prototype: `claude mcp list`, then run `claude` and approve the pending Canva server when prompted.
- Preserve existing Canva pages when auditing or editing; append new prototype pages unless the user explicitly requests otherwise.
- Use the Canva MCP for structured design inspection where available, and Playwright only for visual/layout verification of Canva and the live website.

## Verification

- Build the `CVee-resumebuilder` scheme in Xcode after source changes.
- Run `scripts/test-ios.sh` or the `CVee-resumebuilderUITests` target for wizard navigation and validation coverage.
- Test work-history editing/import, generation availability messaging, saved jobs/resumes, clear-all confirmation, and PDF/RTF export with Xcode tests and Simulator checks when applicable.
- Use web search for external research and current documentation; do not use Playwright for general web research.
- Use Playwright only when testing Canva or the live website, and capture screenshots of those browser-based test states as artifacts for review.
- For native-only SwiftUI behavior, use XCUITest and Simulator screenshots rather than Playwright.
- Prefer focused changes and avoid modifying generated Xcode user-data files.
