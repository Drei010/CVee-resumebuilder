# CVee Application Design Audit

Audit date: 2026-09-05  
Revision: working tree at audit time (uncommitted UI/provider changes preserved)  
Scope: native SwiftUI iPhone/iPad application, all five tabs and supporting flows

Baseline references: [Apple buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [layout](https://developer.apple.com/design/human-interface-guidelines/layout), [accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), and [materials](https://developer.apple.com/design/human-interface-guidelines/materials).

## Executive summary

CVee has a coherent coral/charcoal identity and uses native `TabView`, `NavigationStack`, `Form`, `List`, sheets, confirmation dialogs, SF Symbols, Dynamic Type fonts, and accessibility state values. The existing evidence shows the primary Tasks and Wizard flows are understandable in light and dark accessibility-size captures. This is a good native baseline, not a finished 2026-quality audit pass.

The highest-risk gaps are verification and interaction consistency rather than a broken visual direction: VoiceOver traversal, keyboard-visible forms, landscape, narrow iPad windows, and several populated/destructive states are not covered by the current XCUITest evidence. The Wizard's whole-page horizontal gesture can compete with vertical scrolling and text editing. Primary actions also mix a custom coral style, native bordered buttons, plain row buttons, toolbar actions, and unstyled Form buttons without a documented rule for when each emphasis is used.

### Provisional score

| Dimension | Score | Evidence limit |
|---|---:|---|
| Accessibility | 2/4 | Labels, values, scalable styles, 44-point controls, and motion guards exist; VoiceOver, contrast automation, and keyboard obstruction were not exercised. |
| Performance | 3/4 | Native lists and no new dependencies reduce risk; no launch, frame-time, memory, or export profiling was collected. |
| Appearance & theming | 3/4 | Palette and corrected dark captures are coherent; full state-by-state contrast and material review remains incomplete. |
| Platform conformance | 3/4 | Native navigation/forms/sheets are appropriate; custom page swipe and custom toolbar backgrounds need interaction/material verification. |
| Adaptivity | 2/4 | Portrait iPhone and iPad captures exist; landscape, narrow Split View, keyboard, and maximum text sizes across every screen are unverified. |
| **Total** | **13/20** | **Acceptable baseline; remediation and evidence expansion required.** |

## Findings

### P1 — Core accessibility and device-state evidence is incomplete

- **Affected screens:** all five tabs; especially Profile/API-key sheet, Wizard, Resume editor, and destructive confirmations.
- **Source:** `CVee-resumebuilderUITests/ResumeWizardUITests.swift:69-81,128-152`; no VoiceOver, keyboard, landscape, or narrow-iPad test exists.
- **Reproduction:** run the existing UI suite with VoiceOver, an accessibility text size, keyboard visible, landscape orientation, and a narrow iPad window; compare focus order, clipped labels, sheet/action reachability, and confirmation cancellation.
- **Evidence:** existing tests cover dark/large text and provider configuration, but the captured suites do not establish the states above. The existing iPad Profile artifact is mislabeled: `../ipad/B2C0839A-6F47-4665-A798-EEBB4A0C8C25.png` shows the Resumes empty state per the prior review.
- **User impact:** users relying on assistive technology or smaller/narrower layouts may be unable to discover or reach actions even when the normal portrait path works.
- **Correction:** add deterministic XCUITest coverage for VoiceOver-accessible labels/order/state, keyboard-visible fields, landscape, narrow iPad, and destructive cancellation. Acceptance: every inventoried screen has a recorded pass or explicit unverified result, with no clipped actionable label and all custom controls at least 44×44 points.

### P1 — Wizard swipe navigation competes with native scrolling and editing

- **Affected screen:** Resume Wizard.
- **Source:** `CVee-resumebuilder/ContentView.swift:1197` attaches a whole-page `DragGesture`; `:1360` interprets horizontal translation as Back/Next without comparing vertical translation.
- **Reproduction:** on a form with a long description or keyboard visible, drag diagonally or horizontally across a text-editing area.
- **User impact:** a scroll or text-edit gesture can unexpectedly change wizard steps, lose orientation, or move focus.
- **Correction:** constrain the gesture to a dedicated progress/action surface or require horizontal dominance before changing steps; keep Back/Next as the authoritative controls. Acceptance: vertical scroll and text editing never change steps; horizontal navigation is deterministic and accessible.

### P2 — Action emphasis is inconsistent across equivalent operations

- **Affected screens:** Profile, provider key sheet, Tasks, Saved Jobs, Wizard, Resume editor.
- **Source:** `ContentView.swift:35-45,302-330,441-482,666-707,1032-1054,1333-1351,1400-1405` mixes `CoralButtonStyle`, `.bordered`, `.plain`, native Form buttons, toolbar buttons, and destructive roles.
- **Reproduction:** compare Save/Add/Next/Generate/Edit/Delete/Cancel across tabs at normal and accessibility text sizes.
- **User impact:** users must relearn which action is primary; adjacent API-key actions are especially easy to misread because the destructive control and emphasized save control use different alignment and styles.
- **Correction:** apply the matrix rules in `BUTTON-MATRIX.md`: one coral primary per surface, native secondary/navigation controls, semantic destructive roles, and consistent loading/disabled treatment. Acceptance: equivalent actions share label casing, minimum height, alignment, and state feedback.

### P2 — Fixed-width content and custom page-colored bars need an adaptivity/material pass

- **Affected screens:** every list/form; especially iPad and narrow windows.
- **Source:** `ContentView.swift:48-55,111,573-574,772-773,1378-1383`; `DESIGN.md:115,142` intentionally specifies a 760-point single-column limit and page-colored toolbar backgrounds.
- **Reproduction:** inspect a narrow iPad resizable window, landscape iPhone, and large text with long titles/descriptions.
- **Evidence:** existing iPad Tasks capture `../ipad/7D8E95A7-870F-4A9E-96DD-888ED80B780A.png` shows a very wide reading row; the app does not implement a split-view contract. Existing screenshots show the native tab/navigation structure, but not all material/keyboard states.
- **User impact:** wide layouts can become sparse while narrow layouts can crowd action rows; overriding system bar backgrounds can reduce expected material/translucency behavior.
- **Correction:** preserve the readable-width intent but validate each screen in narrow/landscape/iPad windows; use system materials for navigation/control surfaces where they improve hierarchy, while retaining the coral identity. Acceptance: no clipped labels, no obscured bottom action, and intentional documented behavior at each supported size.

### P2 — API-key actions can overflow at large text sizes

- **Affected screen:** API-key sheet.
- **Source:** `ContentView.swift:302-330` uses `fixedSize(horizontal: true, vertical: false)` for “Delete API key” and “Save API key”.
- **Reproduction:** open a saved provider key at accessibility XXXL text size on a narrow iPhone.
- **User impact:** preserving one-line labels can force truncation or horizontal crowding in the action row.
- **Correction:** retain the requested one-line normal-size layout, but add a large-text fallback (stacked actions or a menu) and verify both actions remain independently hittable. Acceptance: both labels remain readable and at least 44 points tall without overlap at supported text sizes.

### P2 — Documentation contradicts the implemented provider workflow

- **Affected surface:** project documentation and maintenance decisions.
- **Source:** `AGENTS.md:8,23`, `PRODUCT.md:15` still describe exclusively on-device Foundation Models; `PromptSpec.md:59-67` now describes selected remote providers.
- **Reproduction:** read the project overview and development guidance before changing AI UI or routing.
- **User impact:** future changes may restore Apple-only guards or omit remote-processing privacy language despite the implemented provider selector.
- **Correction:** update stale documentation in a separate product/documentation change; do not use it as evidence that the current UI is compliant. Acceptance: all project contracts describe Apple on-device plus explicitly user-selected remote processing consistently.

## Positive patterns

- `CVeeColors` centralizes light/dark tokens and keeps the coral/charcoal identity coherent.
- Native `ContentUnavailableView`, `Form`, `List`, `NavigationStack`, sheets, alerts, and confirmation dialogs reduce platform surprise.
- Selection controls expose spoken values (`Selected`/`Not selected`) and custom selection animation respects Reduce Motion (`ContentView.swift:70-80`).
- Custom coral actions have a 44-point minimum height (`ContentView.swift:35-45`); the floating add control and selection circles use explicit hit-area sizing.
- Provider API keys are edited in a focused sheet, masked by `SecureField`, stored in Keychain, and deleted through a confirmation dialog.
- Existing screenshots show a recognizable Tasks hierarchy, restrained metadata tinting, and a clear Wizard progress indicator.

## Technical conclusion

The source is structurally sound for a native SwiftUI app. No performance certification is claimed: no Instruments trace, memory graph, frame-time capture, or export benchmark was run. The local environment currently has CommandLineTools selected instead of Xcode, so a fresh build/test run could not be reproduced in this audit session.

## Visual conclusion

The design direction is accepted: the app reads as CVee rather than a web port, and the existing corrected dark/large-text captures support the palette and hierarchy. The remaining work is a focused consistency/accessibility/adaptivity pass, not a wholesale redesign. See `FIX-PLAN.md` for the implementation order.

## Evidence index

See `SCREENSHOT-INDEX.md` for annotated links to the prior iPhone/iPad captures and explicit unverified states. Existing audit artifacts were not overwritten.
