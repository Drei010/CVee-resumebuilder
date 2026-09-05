# TalentEdge Mobile Canva Redesign Spec

## Relationship to the current app

This is a future mobile redesign proposal, not a description of the shipped CVee UI. The native
implementation currently uses the five tabs documented in `README.md`, SwiftUI Forms/Lists, a
five-step Resume Wizard, pasted-text job entry, PDF/TXT/DOCX task import, PDF baseline import, and
PDF/RTF export. Proposed items such as DOCX/TXT export, API provider choice, language settings,
Markdown upload, and a separate resume editor/preview mode are not currently implemented.

This proposal is an **append-only** extension to the existing Canva document. Existing pages 1–3 must remain unchanged.

## Visual direction

- Brand: TalentEdge AI
- Typography: SF/system-style sans serif with strong editorial headings
- Light surface: white / near-white with near-black text
- Dark surface: black / charcoal with white text
- Accent: vivid blue for primary actions and active states
- Components: rounded cards and fields, pill buttons, restrained shadows, translucent navigation
- Accessibility: minimum 44 pt touch targets, readable contrast, clear labels, Dynamic Type-friendly hierarchy

## App flow pages to append

1. **Redesign cover + style guide** — explain that the following pages are the website-aligned mobile proposal; show colors, type scale, spacing, radii, and button states.
2. **Welcome** — TalentEdge AI wordmark, value proposition, `Create resume` primary CTA, `Browse saved work` secondary CTA.
3. **Home / library** — saved resumes, saved job descriptions, work-library count, recent activity, empty states.
4. **Start or import** — Start fresh, paste resume or LinkedIn text, upload PDF/DOCX/TXT/Markdown.
5. **Profile** — name, email, phone, location, LinkedIn, GitHub, education, skills, certifications.
6. **Work library** — company and role cards, dates, accomplishment entries, add/edit/delete actions.
7. **Target job** — paste job description, choose saved description, label and save for reuse, validation state.
8. **Generation** — progress indicator, on-device/API provider disclosure, cancel/retry/error states.
9. **Resume preview / editor** — formatted resume, editable sections, preview/source mode, unsaved changes state.
10. **Save and export** — save title, PDF/DOCX/TXT export actions, copy text, share sheet.
11. **Settings** — appearance, language, provider/privacy choice, model availability, about.
12. **State appendix** — loading, empty, validation, offline, API error, unsupported-device, and destructive-confirmation variants.

## Content rules

Use neutral sample content only. Resume copy must follow `PromptSpec.md`: facts-only, action-led bullets, no invented credentials, employers, dates, technologies, or metrics.

## Approval checkpoint

After the new Canva pages are appended, capture screenshots of each page and wait for explicit visual approval before modifying the native SwiftUI app.
