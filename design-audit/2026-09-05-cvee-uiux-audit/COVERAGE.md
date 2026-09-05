# Audit coverage

Legend: **Passed** = evidence inspected; **Failed** = reproducible issue; **Unverified** = no reliable evidence in this audit. Unverified states are not counted as passes.

| Area | Portrait iPhone | Dark / large text | iPad | Keyboard / landscape / narrow | Result |
|---|---|---|---|---|---|
| Tasks list, grouping, search/filter, add | Passed (existing light capture + UI test) | Passed for Tasks capture | Passed (Tasks capture) | Unverified | Partial; see P2 adaptivity |
| Task detail/edit/delete | Passed for basic edit path | Unverified | Unverified | Unverified | Partial |
| Task import and enhancement | Entry/cancel passed; remote/fixture result unverified | Unverified | Unverified | Unverified | Partial |
| Saved Jobs list/add/edit/detail/delete | Passed for list capture | Unverified | Passed for list capture | Unverified | Partial; populated detail states incomplete |
| Resume Wizard steps/progress/back | Passed (UI test) | Passed (Wizard capture) | Passed (Wizard capture) | Failed risk: whole-page swipe | Partial; P1 gesture finding |
| Wizard validation/generate/preview/edit/save | Passed with deterministic fixture | Unverified beyond captured states | Unverified | Unverified | Partial |
| Resumes empty/populated/editor/export | Empty/list and export path covered by UI test | Unverified | Empty/list capture | Unverified | Partial |
| Profile identity/about/edit | Profile capture and edit path present | Unverified | **Unverified**: prior “Profile” artifact is Resumes | Unverified | Partial |
| AI provider/model/API-key sheet | Provider UI test covers select/save/edit/delete | Unverified | Unverified | Large-text action row unverified; see P2 | Partial |
| Clear all confirmation | Cancel path covered; source clears models/keys | Unverified | Unverified | Unverified | Partial |
| VoiceOver labels/order/state | Source labels/values inspected | Unverified | Unverified | Unverified | Unverified |
| Materials, Reduce Motion/Transparency | Reduce Motion guard found; native sheets/bars used | Dark screenshots exist | iPad screenshots exist | Reduce Transparency unverified | Partial |

## Device and tooling record

- Intended evidence device: iPhone 17 and iPad Pro 11-inch (M5), as recorded in existing manifests.
- Existing artifacts: `design-audit/iphone/`, `iphone-reviewed/`, `iphone-corrected/`, and `ipad/`.
- Xcode evidence in this session: **unverified**. `xcodebuild` cannot run because `xcode-select` points to `/Library/Developer/CommandLineTools`, not an Xcode developer directory; prior project artifacts also record CoreSimulator/cache permission failures.
- No live or paid AI request was made. Existing provider UI tests use a dummy key and do not validate remote billing behavior.
- No real user data was deleted.

## Acceptance gate

The audit is complete as a source/evidence report, but the app is not certified complete. Before closing the findings, rerun the matrix with Xcode selected, capture the missing states, and attach pass/fail evidence rather than converting unverified rows into passes.

