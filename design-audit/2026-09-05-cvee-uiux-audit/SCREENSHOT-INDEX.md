# Annotated screenshot index

This audit folder is new; prior binary artifacts remain in `design-audit/` and are linked here rather than overwritten. The annotations identify what each image establishes and what it cannot establish.

| Figure | Image | Annotation / linked finding |
|---|---|---|
| 1 | ![Tasks light](../iphone/4F41482A-9347-4874-933E-C16BAB170C27.png) | Tasks hierarchy, grouped rows, and floating Add action are visible. Supports positive patterns; does not test keyboard or VoiceOver. |
| 2 | ![Tasks dark accessibility](../iphone-reviewed/54900CB5-B40F-4290-9028-4FEDD27852E3.png) | Corrected charcoal canvas and large-text Tasks layout. Supports appearance baseline; does not certify every screen. |
| 3 | ![Wizard dark accessibility](../iphone-reviewed/2F7090E9-01A5-48A3-B26B-C55D687F37FC.png) | Wizard progress and dark large-text hierarchy. Supports P1/P2 evidence boundary; gesture behavior is not visible in a still. |
| 4 | ![Saved jobs](../iphone/23059504-2DEE-4418-8B53-3E2A59658838.png) | Saved Jobs list and date treatment. Supports coverage; populated detail/delete states remain unverified. |
| 5 | ![iPad tasks](../ipad/7D8E95A7-870F-4A9E-96DD-888ED80B780A.png) | Wide iPad reading row and native tab/navigation adaptation. Supports P2 readable-width review. |
| 6 | ![iPad profile artifact](../ipad/B2C0839A-6F47-4665-A798-EEBB4A0C8C25.png) | Manifest labels this Profile, but prior review identifies the rendered screen as Resumes. This is evidence of a coverage gap, not Profile validation. |

## Missing captures to add in the next verification pass

- Profile with About icons, provider selector, model picker, configured key, edit/delete key sheet, and error state.
- Narrow iPhone and accessibility XXXL API-key action row.
- Keyboard-visible Add Task, Add Job, Profile edit, and Wizard fields.
- Landscape iPhone and narrow resizable iPad for all five tabs.
- Reduce Transparency and VoiceOver accessibility hierarchy snapshots.

