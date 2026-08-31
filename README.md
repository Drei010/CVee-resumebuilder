# CVee Resume Builder

CVee is a SwiftUI iOS app for organizing work history, saving job descriptions, and generating ATS-friendly resumes with on-device Apple Intelligence when available.

## Features

- Five-tab app: Tasks, Saved Jobs, Resume Wizard, Resumes, and Profile
- Typeform-style resume wizard with progress tracking
- PDF resume import and saved-resume baselines
- Task and job-library search, selection, and editing
- Plain-text ATS resume generation with Apple Foundation Models
- PDF and RTF export

## Requirements

- Xcode 26.5 or later
- iOS 26.5 deployment target
- Apple Intelligence-enabled device for AI generation

## Build and test

Open `CVee-resumebuilder.xcodeproj` in Xcode, select the `CVee-resumebuilder` scheme, and run on an iOS Simulator or device. The `CVee-resumebuilderUITests` target contains the Resume Wizard UI tests.

AI generation stays on-device; unsupported devices show an availability message.
