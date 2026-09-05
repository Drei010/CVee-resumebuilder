# CVee Resume Builder

CVee is a SwiftUI iOS resume workspace. It stores reusable work history, saved target jobs, profile details, and generated resumes locally with SwiftData. Resume generation and task rewriting use Apple Foundation Models on supported devices; there is no cloud or API fallback.

## App functionality

The five tabs are:

- Tasks — add, edit, delete, search, and filter work experiences by company. Each entry stores a role, company, dates, and task/achievement lines. Existing tasks can be rewritten into two concise sentences with on-device AI.
- Saved Jobs — add pasted job descriptions with a title and company, then search, edit, delete, and inspect resumes linked to a job. The core layer also contains a LinkedIn fetcher, but the current UI only creates pasted-text jobs.
- Resume Wizard — start fresh with profile information or use a saved/uploaded text-based PDF as a baseline; select work entries; choose a saved job; review a summary; generate; edit the plain text; and save the result.
- Resumes — browse saved drafts, open an editable resume, preview it, delete it, and share PDF or RTF exports. Saved content currently uses one RTF-backed resume section and the `jakes` template identifier.
- Profile — edit name, contact links, education, skills, and certifications; read terms; contact support; and permanently clear local tasks, jobs, resumes, and profile data after typing `CLEAR`.

## Import and generation limits

- Task import accepts PDF, TXT, and DOCX files up to 10 MB and 100,000 characters. Text is previewed, split into selectable task drafts with Apple Intelligence, and saved under one role/company.
- Resume baselines accept readable PDFs or previously saved resumes.
- Full name and email are required for a fresh wizard run; at least one work entry and one saved job are also required.
- AI availability is checked before generation or task analysis. The UI reports unsupported devices, disabled Apple Intelligence, and a model that is still preparing.
- Prompts require facts-only, ATS-oriented output and prohibit invented employers, dates, credentials, technologies, responsibilities, and metrics. Generated text must still be reviewed before use.

## Data and platform

- SwiftData models: `WorkExperience`, `JobTarget`, `Resume`, and cascading `ResumeSection`.
- Profile fields use `@AppStorage`; test launches use an in-memory SwiftData container.
- Minimum platform/build settings are defined by the Xcode project (currently iOS 26.0; the project uses Swift 5).
- ZIPFoundation is used only for DOCX text extraction.

## Build and test

Open `CVee-resumebuilder.xcodeproj`, select the `CVee-resumebuilder` scheme, and run on an iOS Simulator or device. The `CVee-resumebuilderUITests` target covers wizard progress, required fields, forward navigation, and back navigation. The repository helper is `scripts/test-ios.sh`; it discovers an iPhone Simulator, builds for testing, and runs the UI test target.
