# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Product Purpose

CVee organizes work history and target jobs into tailored, editable resumes. The user records work experience once, saves the jobs they are aiming for, selects the facts that matter for one job, generates a draft, reviews and edits it, then saves and exports it. What each tab does today is described in [README.md](README.md).

## Capabilities and Constraints

Preserve the existing Tasks, Saved Jobs, Resume Wizard, Resumes, and Profile workflows, confirmed by the user. SwiftUI and SwiftData provide native UI and local persistence. Preserve PDF/RTF export.

### Facts only

Every AI feature and every prompt follows this rule. Other docs link here instead of restating it.

- A resume contains only facts the user supplied: their profile, their work library, and an optional baseline resume. The user chooses which work entries to include. The target job guides which of the supplied facts to emphasize; it is never a source of facts about the candidate.
- AI may reword, reorder, select, and leave out. It never fabricates employers, job titles, dates, degrees, certifications, technologies, awards, responsibilities, or metrics.
- Information the user did not supply is left out, not guessed and not filled with a placeholder.
- Numbers are kept exactly as supplied. A metric appears only when the user stated it.
- The rule covers resume generation, task import splitting, task enhancement, and resume-report suggestions. The prompts in [PromptSpec.md](PromptSpec.md) carry it. Only the report suggestions are checked in code (a suggestion is kept only when the text it quotes appears verbatim in the job description or in the work-library entry it names); generated resumes, imported tasks, and enhanced tasks are not machine-checked. Every AI result therefore reaches the user as a proposal they review before it is saved, and generated text must still be reviewed before use.

### Privacy and provider choice

- Apple Intelligence processes content on the device, behind Foundation Models availability checks. It is the default when the device is eligible.
- OpenAI, Gemini, and Claude are explicit choices. The user selects one and adds their own API key in Profile → Advanced settings → AI Provider. When an AI feature runs, the relevant resume, profile, job, or task text goes to that provider under the user's key and its terms, and the provider may charge for it. The AI Provider screen and the wizard's review step state where content is processed.
- Generation, task import splitting, and task enhancement all use the selected provider. CVee never switches providers on its own: a missing key or an unavailable model is reported, not rerouted.
- Resume-report suggestions always run on the device with Apple Intelligence, whichever provider is selected.
- API keys stay in the Keychain on this device and need device authentication to read. Clear all data removes them too.
- Saved tasks, jobs, resumes, and profile information are stored in the app's local data store. No account is required. Apart from the selected AI provider, CVee's only network request fetches a job page from a link the user saved, when they ask for it.

### Accessibility

Preserve accessibility. Give interactive controls accessibility labels, with hints where they help. Let text grow with Dynamic Type and keep layouts usable at accessibility sizes. Respect Reduce Motion in authored animations. Announce saves and errors to VoiceOver. Visual and component rules are in [DESIGN.md](DESIGN.md).

### Resume reports are advisory

Resume reports provide transparent, local phrase coverage against a user-confirmed job checklist, related work-library evidence, and document-health findings checked on the resume text and a PDF rendered from it. Coverage is not an ATS score and does not verify proficiency, years of experience, certification validity, eligibility, or hiring outcomes. Findings never modify resume text or block saving/exporting. Apple Intelligence suggestions are optional and validated against their supplied text.

### Non-goals

- A hiring score. The resume report shows phrase coverage and document health; it computes no ATS score or match percentage and does not promise interviews or job outcomes.
- Silent changes to the user's content. AI results and fetched job descriptions are proposals that change saved content only when the user accepts or saves them, and report findings never change it.
- Project-management features. The Asana-inspired reference sets the visual language only; CVee adds no boards, inboxes, assignees, due dates, or task-completion workflows ([DESIGN.md](DESIGN.md), [design-audit/REVIEW.md](design-audit/REVIEW.md)).

## Brand Commitments

Apply the supplied Asana-inspired coral-and-charcoal design reference to the existing CVee workflows.
