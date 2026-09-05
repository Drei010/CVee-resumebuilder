# Prioritized correction plan

Application fixes are intentionally separate from this audit. Implement in these batches, preserving the current coral/charcoal direction and user data.

## Implementation status — 2026-09-05

- **Batch 1 — implemented:** Wizard swipes now require horizontal dominance; provider-key cancellation is covered in the UI test path.
- **Batch 2 — implemented:** API-key actions stack at accessibility Dynamic Type sizes; hints clarify delete/save outcomes; shared surfaces dismiss the keyboard interactively.
- **Batch 3 — implemented:** Profile, Task, Job, Add Job, and Add Task commit actions use the shared coral primary style.
- **Batch 4 — implemented:** saved-job detail dates use the shared secondary token and the floating Add action includes a spoken hint.
- **Verification:** Swift parsing and `git diff --check` pass. `scripts/test-ios.sh` was attempted after each batch with Xcode 26.6 selected and exits 70 before tests because CoreSimulator is unavailable and SwiftPM/Clang cache paths return `Operation not permitted`.

## Batch 1 — interaction defects (P1)

1. Constrain or remove the Wizard whole-page `DragGesture`; require horizontal dominance or move swipe handling to a dedicated progress/action surface.
   - Acceptance: diagonal scrolls, text editing, and keyboard gestures never change steps; Back/Next remain discoverable.
2. Add deterministic tests for API-key Save/Delete independence, cancel preservation, parent saved-state refresh, and clear-all cancellation.
   - Acceptance: each action has a unique identifier and test assertion; no adjacent action invokes the other.

## Batch 2 — accessibility and layout (P1/P2)

1. Exercise VoiceOver, Dynamic Type through accessibility XXXL, keyboard-visible forms, landscape, and narrow iPad windows for every tab.
2. Add a large-text fallback for the API-key action row so “Delete API key” and “Save API key” remain readable and independently hittable.
3. Keep required-field recovery adjacent to the Wizard action area and verify disabled actions have an actionable explanation.
4. Validate readable-width behavior on iPad without obscuring navigation, sheets, safe areas, or the keyboard.

## Batch 3 — interaction consistency (P2)

1. Adopt the button rules in `BUTTON-MATRIX.md`: one coral primary per surface, native secondary/navigation controls, semantic destructive actions.
2. Normalize action labels and loading/disabled states across Tasks, Saved Jobs, Wizard, Resumes, Profile, and provider sheets.
3. Ensure icon-only Export/Add controls expose labels, hints, state, and 44×44 hit areas.

## Batch 4 — visual polish and platform fit (P2/P3)

1. Recheck light/dark contrast for secondary dates, empty-state guidance, API-key status, and coral button ink using rendered screenshots.
2. Review custom page-colored navigation/tab backgrounds against current system materials; adopt Liquid Glass only for navigation/control surfaces where it improves hierarchy without replacing CVee’s identity.
3. Refresh the iPad Profile capture and add annotated screenshots for provider, model picker, key sheet, error, and destructive-confirmation states.
4. Update stale `AGENTS.md`/`PRODUCT.md` AI wording to match the selected-provider workflow.

## Verification

Run the focused XCUITests and `scripts/test-ios.sh` with Xcode selected, then capture iPhone light/dark, accessibility text, landscape, narrow iPad, iPad full width, keyboard-visible, and provider/error states. Re-score the five audit dimensions only after previously unverified rows have evidence.
