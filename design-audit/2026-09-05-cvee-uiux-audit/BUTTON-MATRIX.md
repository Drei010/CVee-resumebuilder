# Button and interaction matrix

Observed from `CVee-resumebuilder/ContentView.swift` and the existing UI tests. “Unverified” means source inspection found the control but no deterministic runtime capture established the state.

| Action class | Current examples | Current treatment | Placement/result | Verdict | Rule |
|---|---|---|---|---|---|
| Primary commit | Save API key, Add task, Save changes, Next, Generate Resume | `CoralButtonStyle` in some flows; native Form button in others | Usually bottom/action row; triggers save or step advance | P2 inconsistency | One coral primary per surface; label uses sentence case; minimum 44pt; disabled and loading states preserve layout. |
| Secondary | Edit resume, Formatted/LaTeX, Select All/Clear | `.bordered`, native Form, or plain | Adjacent to affected content | P2 inconsistency | Use native bordered/automatic secondary treatment; group with the content it changes. |
| Navigation | Cancel, Back, NavigationLink rows, tab items | Native toolbar/navigation/tab styles | System chrome or full row | Pass by source inspection | Keep system placement and labels; do not imitate toolbar chrome in content. |
| Destructive | Delete task/job/resume/key, Clear all data | Semantic `.destructive`, alerts/dialogs, swipe action | Near affected content or confirmation | Pass with coverage gap | Keep semantic role and require confirmation for irreversible/data-wide actions. |
| Icon-only | Export, floating Add | SF Symbol with explicit label/identifier; FAB is custom circular | Toolbar or bottom trailing overlay | P2 verification | Provide accessibility label/hint, 44pt hit area, and no overlap with keyboard/safe area. |
| Selection | Company filter, experience/job selection, provider/model picker | Plain buttons, `Picker`, `SelectionCircle` | Inline with list/form | Pass by source inspection | Expose selected state as text; use `Picker` for mutually exclusive choices. |

## Required interaction checks

1. Adjacent API-key Delete and Save controls must trigger only their own actions.
2. Cancel in key/profile/clear-all sheets must preserve data and provider selection.
3. Saving a key must refresh the parent “API key saved” state after dismissal.
4. Disabled Next/Generate must explain why they are disabled without requiring a blind tap.
5. Loading labels (for example `Generating…` and `Analyzing tasks…`) must retain a stable hit target and not move neighboring controls.
6. Destructive swipe actions and menu actions must have a confirmation policy consistent with their equivalent detail-screen buttons.

## Proposed consistency rules

- Use one emphasized coral action per visible surface; never place a second emphasized action beside it.
- Keep destructive actions semantic red and visually separated from commit actions.
- Prefer native toolbar placement for Cancel/Back/Export; avoid content-level imitations.
- Keep all custom actions at 44×44 points minimum and give icon-only controls a spoken label, value, and hint where state changes.
- For large text, allow action rows to stack rather than forcing horizontal one-line labels.
- Use stable identifiers that describe the result (`ai-provider.save-key`, `wizard.generate`) rather than implementation details.

