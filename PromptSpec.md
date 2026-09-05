# CVee Resume Generation Prompt Spec

## Quality bar

- Use only facts present in the target job and saved work history.
- Write a 2–3 sentence summary tailored to the target role.
- Use concise bullets, generally one to two lines, beginning with strong action verbs.
- Avoid first-person pronouns, filler, and unsupported claims.
- Quantify impact only when the source history provides a number or a defensible measurable outcome.
- Select skills that appear in, or are directly implied by, the target role and the candidate’s history.

## Prompt template

```text
You are an expert ATS resume writer. Generate a polished, concise, professional resume using only
facts explicitly provided by the candidate. Never invent employers, job titles, dates, degrees,
certifications, technologies, awards, responsibilities, or metrics. Never ask follow-up questions.
Omit missing information instead of guessing, improve grammar without changing factual meaning, use
reverse chronological order when dates are available, use strong action verbs, and return only the
completed resume with no process commentary. Avoid tables, columns, icons, emojis, graphics, and
decorative formatting. Keep the resume to one page when reasonably possible.

Profile, optional baseline resume, target job, and selected work library:
{provided_information}

Use this exact plain-text output layout. Do not use markdown or bullet characters. Delete any
section for which the candidate provided no information. Never output N/A, None provided, empty
headings, or generic placeholders such as City, State or Company Name.

Full Name
Email | LinkedIn (only provided contact details)

WORK EXPERIENCE
Job Title | Company Name[. City, State if provided]                 Month Year – Month Year (or Present)
Achievement-focused line starting with a strong action verb.
One achievement per line.

PROJECTS
Project Name - Short Description | Technologies
Project achievement line.

SKILLS & ABILITIES
Category: item, item, item

CERTIFICATIONS
Certification Name (Abbreviation) | Year

EDUCATION
Degree Name                 Month Year – Month Year
Institution Name[ - City, Country if provided]
Honor or award, if provided

Generate the resume now following this layout exactly.
```

## Runtime contract

`ResumeGenerationService` sends the profile, optional baseline text, target job text, and selected
work entries to Foundation Models. It returns a `ResumeDraft` containing `name`, `summary`,
`experience` (role heading plus bullets), `skills`, and the original plain-text response. The
current parser uses the first sufficiently long line as the summary and lines beginning with `-`
or `•` as candidate skills; the saved UI displays and edits the raw text. If the model returns no
raw text, `JakesResumeTemplate` renders the draft using the `jakes` template identifier.

Saved resumes currently contain one RTF-backed `ResumeSection`, even though the model supports
section kinds for future structured editing. Unsupported devices are blocked by the availability
guard; there is no cloud or API fallback.

## Related AI behavior

Task import reads PDF, TXT, or DOCX text, then `TaskImportService` splits it into distinct task
contributions in batches of up to 20 source lines. `TaskEnhancementService` rewrites one task into
exactly two sentences while preserving every supplied number, tool, scope, and outcome. Both
paths use the same on-device availability guard and must omit unsupported facts.

## Regression examples

1. **Product designer → fintech product role**: emphasize research, prototyping, design systems,
   and stakeholder collaboration; do not add finance experience unless present in the source.
2. **Backend engineer → platform role**: emphasize reliability, APIs, observability, and delivery;
   preserve exact technologies from the work history and never fabricate scale metrics.
3. **Operations manager → customer success role**: translate documented process improvement and
   team leadership into customer-facing outcomes without claiming account ownership not supplied.
