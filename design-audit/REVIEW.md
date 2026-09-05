# CVee native finish review

## persistence

Reviewed 2026-09-05 against `PRODUCT.md`, the contract at the start of `ContentView.swift`, `design-audit/DesignReference.md`, and Impeccable's craft floor and native iOS audit references. Scope is the existing five-tab resume workspace. The supplied reference is textual; there is no approved image composition against which to claim pixel fidelity. This review changes no app code.

All seven images in `iphone/manifest.json` were inspected. Evidence names below use that manifest's human-readable screen names. The two images labeled dark are visibly light and cannot establish dark-mode correctness. The five images in `ipad/manifest.json` were also inspected. The image labeled Profile (`B2C0839A-6F47-4665-A798-EEBB4A0C8C25.png`) actually shows Resumes, so Profile on iPad remains unverified. Source already contains fixed 20pt decorative task and 24pt FAB glyphs, but the old accessibility screenshot predates those fixes.

## fidelity

The direction holds: white list canvas, charcoal text, coral creation anchor, blue tinted company metadata, restrained dividers, native large titles, and a compact five-segment wizard indicator. Tasks visibly reads as a reusable work-history library. Existing Saved Jobs, Resume Wizard, Resumes, and Profile remain recognizable native workflows. No Asana board, assignee, due-date, or task-completion product semantics have been added.

Using a work-history symbol instead of a fake completion checkbox is appropriate. Green selection belongs to actual selection controls. SF typography and the platform tab bar honor the native contract, including iOS's material treatment; replacing them with a copied four-tab Asana bar would reduce fidelity to CVee's approved scope. Charcoal text on coral is a justified contrast correction to the reference's white button text.

## ceiling

The light Tasks image (`iphone/4F41482A-9347-4874-933E-C16BAB170C27.png`) has clear hierarchy and a discoverable add control. Profile's native rows and the Resumes empty state are coherent. The known glyph overflow is visible in `iphone/05CBED4D-4916-4ED3-98CC-08CD03B1A5E9.png`; source fixes need a fresh capture before closing it. The large wizard title truncates in `iphone/44DF4030-D095-481A-8335-48CD16A8684E.png`, but the visible current-step heading and selected tab retain orientation; this alone is not a blocker.

Native strengths in source include labeled icon actions, selected/collapsed accessibility values, a combined spoken wizard-progress label, minimum 44pt custom action targets, scalable text styles, List/Form controls, and Reduce Motion guards on authored selection/group animation. Actual VoiceOver traversal, keyboard access, landscape, Split View, increased contrast, and populated resume editing/export were not exercised by this reviewer. List recycling is positive; no runtime performance measurements were collected. The iPad Tasks capture shows a roughly 110-character summary line extending across the canvas. Native top tab navigation adapts correctly, but list reading width is broad; no clipping is visible. The wizard fits its initial fields and recovery text in the iPad viewport.

## material_fixes

1. **P1 — Verify the corrected appearance and accessibility captures before claiming finish.** Replace or clearly supersede the mislabeled light captures with genuine charcoal dark-mode images and fresh large-text Tasks/Wizard images. Confirm the fixed glyph stays inside its 22pt column and the FAB plus remains 24pt. This is an evidence gate, not a claim that current source still has the old overflow. Command: `$impeccable audit`.
2. **P2 — Improve visible field guidance and date contrast (existing issue, not established as a redesign regression).** In `iphone/23A84E91-4D2D-47CA-AB99-01FD29AE5D36.png`, empty Email/Phone/Location labels are very pale against white. In `iphone/23059504-2DEE-4418-8B53-3E2A59658838.png`, the saved date is similarly faint. Source locations: wizard fields around `ContentView.swift:1047`, saved-job date at `:567`, and analogous saved-resume date at `:1182`. Use the existing secondary foreground token for informative dates; give required fields persistent readable labels or explicit contrasting prompts. Check rendered contrast against 4.5:1 for ordinary-size text. Exact pixel ratios were not measured. Command: `$impeccable colorize`.
3. **P2 — Keep required-field recovery visible (existing issue).** The disabled Next button is visible on the initial wizard image, while “Full name and email are required” is placed after all nine fields and lies below the first viewport. Show this short explanation near the navigation action or required inputs so a user immediately knows how to continue, including at accessibility sizes. Source: `startPage` and `navigationBar`. Command: `$impeccable clarify`.

4. **P2 — Correct iPad Profile verification.** `ipad/B2C0839A-6F47-4665-A798-EEBB4A0C8C25.png` is labeled Profile but shows the Resumes empty state. Select Profile through the native tab overflow and assert its title before capture. This corrects the test evidence; it does not justify replacing native navigation. Command: `$impeccable audit`.
5. **P2 — Limit long reading rows on wide iPad windows.** `ipad/7D8E95A7-870F-4A9E-96DD-888ED80B780A.png` spreads the task summary nearly across the display. Consider a centered readable-width content area for long task/detail copy while keeping native chrome full-width. This is a minor adaptivity refinement, not a task-completion blocker or a requirement to add master-detail navigation. Command: `$impeccable adapt`.

Source-only follow-up: the wizard's whole-page `DragGesture` at `:1005` interprets left as Back and right as Next (`:1168`), and does not compare horizontal against vertical translation. This is a pre-existing interaction risk, not a screenshot-proven regression. Verify diagonal scrolling and text editing before changing it; native Back/Next controls already provide an alternative. Avoid expanding this visual pass into speculative navigation work.

Finish fixes with `$impeccable polish`, then repeat the focused native checks. No web detector applies.

## keep

Keep the shared palette, flat lists, soft metadata tints, restrained coral FAB shadow, standard navigation, five existing tabs, accessible textual selection states, and on-device generation boundaries. Keep scope focused; no new navigation architecture, font dependency, illustration, or completion celebration is needed.

**Disposition: fix.** The design direction is accepted; no rebuild is warranted. Close the appearance/accessibility evidence gate and the visible contrast/recovery issues before describing the redesign as fully verified. iPad Profile and untested interaction states remain explicitly outside this screenshot verdict.

Audit score appendix (provisional source/screenshot assessment, not a runtime certification):

| Dimension | Score | Evidence and limit |
|---|---:|---|
| Accessibility | 2/4 | Labels, states, scalable styles and motion guards exist; old AX overflow needs fresh verification and pale field guidance remains. VoiceOver not exercised. |
| Performance | 3/4 | Native Lists and no new heavy media/dependencies; no launch, frame-time or memory profiling, so 4/4 is not established. |
| Appearance & Theming | 3/4 | Cohesive adaptive tokens; light-mode contrast issues and genuine dark capture pending. |
| Platform Conformance | 3/4 | Native tabs, stacks, forms, sheets and SF Symbols; existing page swipe warrants interaction testing. |
| Adaptivity | 2/4 | Portrait iPhone and iPad inspected; wide row measure, old AX overflow, and no landscape/Split View evidence. |
| **Total** | **13/20** | **Acceptable; focused fixes and verification required.** |

Platform verdict: this reads as a native application, not a website port. Scores are intentionally limited by the inspected first-pass artifacts; re-score after the final captures.

Final verification update: the corrected iPhone suite ran 5 tests with 0 failures via `scripts/test-ios.sh` on iPhone 17. This covers task creation/import entry and clear cancellation, grouped-task collapse and add flow, dark mode at accessibility text size, wizard back navigation, and generated resume preview/save/reopen/export. The iPad task-flow run passed before the final centered-width adjustment; native tab overflow prevented a reliable Profile assertion in the later evidence pass.

### Verdict pass — iPhone corrections 1–3

Inspected the four relevant captures in `iphone-reviewed/manifest.json` and the corresponding prompt/date/hint source changes. This pass is limited to the named corrections; it does not introduce new findings.

| Fix | Verdict | Evidence |
|---|---|---|
| 1: true dark appearance and fixed glyphs | **Pass** | `54900CB5-B40F-4290-9028-4FEDD27852E3.png` shows a charcoal Tasks canvas, the small decorative glyph contained in its leading column, and the normal-size plus within the coral FAB at accessibility text size. `2F7090E9-01A5-48A3-B26B-C55D687F37FC.png` shows the matching charcoal wizard. These supersede the mislabeled initial dark captures. |
| 2: prompt/date contrast | **Pass for named correction** | `D8AE43DD-0304-4D6A-8035-77E349F6B40D.png` shows clearly darker wizard prompts; `41E8CC9A-2AE9-4F7C-A0AF-09D3CB6B8605.png` shows a readable saved-job date. Source uses the secondary token for wizard prompts and both saved-job/resume dates. Token-level contrast is approximately 5.11:1 for #6D6E6F on white, 7.02:1 for #A9A9AA on #1E1F21, and 6.45:1 on #252628. These are sRGB color calculations, not antialiased screenshot pixel measurements; no populated saved-resume image was supplied in this pass. |
| 3: required-field recovery | **Pass** | The required-name/email hint is visible directly above the first identity input in both normal light and dark accessibility wizard captures, while disabled Next remains visible. A user can now identify the missing requirement without reaching the end of the form. |

Updated provisional score: **15/20 — Good**. Accessibility **3/4**, Performance **3/4**, Appearance & Theming **4/4**, Platform Conformance **3/4**, Adaptivity **2/4**. The appearance score covers the named direction and corrected rendered states, not exhaustive dark-mode certification of every screen. VoiceOver and broader runtime limits from the initial review remain unchanged.

**Disposition: fix, pending only review items 4–5.** No further correction is requested for items 1–3. The revised iPad Profile capture and readable-width captures remain pending. The manifest also contains an unrelated test failure attachment; this visual verdict does not claim the complete test run passed.
