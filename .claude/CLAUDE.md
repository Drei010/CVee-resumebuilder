# CLAUDE.md

Read [AGENTS.md](../AGENTS.md) before changing code. It holds the documentation map, project structure, development guardrails, and verification rules. This file only adds what Claude Code needs on top of it. Behavior facts live in [README.md](../README.md), product principles in [PRODUCT.md](../PRODUCT.md), and prompts in [PromptSpec.md](../PromptSpec.md); link to them rather than copying.

## Navigate with the graph first

`graphify-out/` holds a knowledge graph of the code and docs (built by `/graphify`; `.graphifyignore` excludes `design-audit/` and the asset catalogs). Use it to save tokens:

- For "where is X", "what calls Y", "how does Z flow", or "what depends on W", start with `graphify query "<question>" --budget 1500`. Use `graphify path "A" "B"` for a link between two things and `graphify explain "X"` for one node's neighbors. If a name matches more than one node, the command says so and lists the paths; retry with `"path/File.swift::X"`. Check `graphify-out/GRAPH_REPORT.md` for the main hubs and communities.
- Read a source file only after the graph points you to it, and read just the lines in `source_location`. Do not open whole files or grep the repo to answer a question the graph can answer.
- If `graphify-out/graph.json` is missing, skip this section and use Grep and Read.
- After you edit Swift source, run `graphify update .`. It re-extracts code without an LLM. After you edit a doc, run `/graphify . --update`. Otherwise the graph goes stale.
- Treat graph results as leads. Confirm an edge in the source before you rely on it, and report any edge marked AMBIGUOUS as uncertain.

## Commands

- Build: Xcode scheme `CVee-resumebuilder`, after any source change.
- Tests: `scripts/test-ios.sh` runs unit and UI tests. Use `IOS_DEVICE_FAMILY=iPad` for iPad.
- Lint: `swiftlint lint --config .swiftlint.yml --strict` (same check as the CI lint job).

## Environment limits

- Cloud sessions run on Linux without Xcode. There you can run SwiftLint only. Build and tests run in CI or on a Mac, so verify other changes by reading the code and say so in the final message.
- `.derivedData/`, `build/`, `TestResults-*.xcresult/`, and `ci-diagnostics/` are generated output. Do not edit or commit them.
- Do not edit `.xcodeproj` user-data files.

## Working rules

- Route all generation, task import, and enhancement through `AITextGenerationService`. Keep API keys in the Keychain through `APIKeyStore`.
- Keep SwiftData changes compatible with the existing models. When you add a model, update the schema in `CVee_resumebuilderApp.swift`, the `ContentView.swift` previews, and `ResumeRenderingTests.swift`.
- When you change a generation prompt or resume rendering, update [PromptSpec.md](../PromptSpec.md) in the same change.
- Record shipped changes in [CHANGELOG.md](../CHANGELOG.md), newest first.
- Treat `design-audit/` as archive evidence, not a spec. Ignore Markdown files that AGENTS.md does not list.
- Do not add a package dependency for a few lines of code. ZIPFoundation is the only one.
- Start from `main` on a new branch. Commit or push only when asked.

## Checks by hand

Automated tests do not cover these. Check them in the Simulator or on a device when a change touches them: the share extension and inbox import, URL fetching, document and screenshot import, real AI output, real Keychain storage, App Shortcuts, section editor interactions, clearing all data, and mascot animation.
