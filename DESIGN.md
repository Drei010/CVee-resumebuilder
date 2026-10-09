---
name: CVee
description: A calm native resume workspace with coral actions and flat experience lists.
colors:
  coral: "#F06A6A"
  page-light: "#FFFFFF"
  page-dark: "#1E1F21"
  surface-light: "#F9F8F8"
  surface-dark: "#252628"
  divider-light: "#EDEBE9"
  divider-dark: "#35363A"
  ink-light: "#1E1F21"
  ink-dark: "#F5F4F2"
  secondary-light: "#6D6E6F"
  secondary-dark: "#A9A9AA"
  success: "#237A34"
  success-dark: "#62D26F"
  action-ink-light: "#B33946"
  action-ink-dark: "#FF9494"
  object-ink-light: "#2855A2"
  object-ink-dark: "#A8C5FF"
  object-tint: "#4573D2"
  chart-1-light: "#0F7C8A"
  chart-1-dark: "#4FC3CF"
  chart-2-light: "#7A4FC9"
  chart-2-dark: "#B79CF0"
  chart-3-light: "#A86A00"
  chart-3-dark: "#F0AE4A"
  chart-4-light: "#B2457F"
  chart-4-dark: "#F08FC0"
typography:
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontWeight: 400
  row:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontWeight: 500
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontWeight: 600
rounded:
  button: "8px"
  card: "12px"
  capsule: "999px"
spacing:
  metadata-x: "9px"
  metadata-y: "3px"
  row-y: "11px"
  content-gap: "12px"
  stack-gap: "8px"
  button-x: "26px"
  button-y: "13px"
components:
  button-primary:
    backgroundColor: "{colors.coral}"
    textColor: "{colors.ink-light}"
    rounded: "{rounded.button}"
    padding: "13px 26px"
  metadata-pill:
    textColor: "{colors.object-ink-light}"
    rounded: "{rounded.capsule}"
    padding: "3px 9px"
---

# Design System: CVee

## Overview

**Creative North Star: "The Reusable Experience Library"**

A calm, structured library of reusable experience: warm coral actions sit on white or charcoal, while flat rows and quiet metadata keep work history easy to scan. The supplied Asana reference sets the visual language; CVee keeps its own resume workflows.

Native SF typography, native navigation, and adaptive semantic colors make the system feel at home on iOS. Small object tints support recognition without competing with the content.

**Key Characteristics:**
- Coral actions on white and charcoal.
- Flat lists with company grouping and tinted metadata.
- Native typography, navigation, and accessible selection.

## Colors

Warm coral marks actions; restrained blue metadata and green selection provide supporting meaning; a separate chart palette carries data. Frontmatter contains the extracted primitive values; light/dark pairs resolve through `CVeeColors` in `ContentView.swift`.

### Primary
- **Warm Coral:** primary buttons, the quick capture card, and the current wizard step. Stable across themes.
- **Action Ink:** deeper coral text in light appearance and lighter coral text in dark appearance, for native links, controls, selected navigation, and an active filter.

### Secondary
- **Object Blue:** a soft tint at 16% opacity behind metadata capsules and the active company-filter chip; separate deeper light-mode and lighter dark-mode foregrounds keep text legible.
- **Selection Green:** selected circles, completed wizard progress segments, ready-status labels, the saved API key status, and the add icons in the widget editor. Darker green in light appearance keeps small text readable. It does not introduce task completion behavior.

### Chart Series
- **Chart 1–4:** teal, purple, ochre, and magenta (`CVeeColors.chart1`–`chart4`), each a light/dark pair that holds at least 4:1 on the card surface in both themes. Secondary ink marks the Other slice. The Used in resumes bar uses Chart 1.

### Neutral
- **Canvas White / Canvas Charcoal:** primary screen backgrounds.
- **Quiet Surface:** grouped form rows, and the card surface for progress widgets, the task search field, the Import tasks row, and the speech bubble.
- **Hairline Divider:** list separators, upcoming wizard segments, the speech bubble outline, and the empty donut ring.
- **Primary Ink:** adaptive body text. Its light-mode charcoal stays fixed in both themes for enabled coral button labels and for the quick capture card's icon, title, and white-field text.
- **Secondary Ink:** descriptions, date ranges, counts, Saved Jobs row chevrons, and the Other chart slice.

**The Accent Rule.** Keep coral focused on actions and active state; use object tint only for compact metadata and the active filter chip.

**The Data Color Rule.** Use chart colors only for data, and keep coral, green, and object blue out of charts. Give every slice a labeled legend row so color is never the only cue.

## Typography

**Display Font:** native SF through SwiftUI semantic styles.
**Body Font:** native SF through SwiftUI semantic styles.
**Label/Mono Font:** SF; monospaced digits for dates, counts, and widget values; the native monospaced body style for the wizard's LaTeX editor and the LaTeX import sheet, and a monospaced caption for a resume's original source.

Native SF is explicitly permitted by the supplied reference; no bundled font is required. Frontmatter weights capture recurring roles, while semantic SwiftUI styles own size, leading, and Dynamic Type behavior. CSS lengths in portable tokens correspond to iOS points at the default content size, not a fixed type-scale contract.

### Hierarchy
- **Display:** native navigation titles; detail screens may use inline titles.
- **Card title:** bold `.title3` for the quick capture card's title.
- **Headline:** `.headline` for wizard steps, saved content titles, and the speech bubble title.
- **Row:** `.subheadline.weight(.medium)` for the achievement that leads each task row.
- **Body:** native body text and subheadline descriptions, including the speech bubble message.
- **Widget value:** bold rounded `.largeTitle` with monospaced digits.
- **Label:** semibold caption metadata and widget titles, bold caption company headers, and semibold subheadline primary buttons and the "Your progress" heading.

## Layout

Plain, vertically scrolling lists establish the main spatial rhythm. Work history groups by company with collapsible headers. Task rows lead with the achievement, followed by role and dates; tapping a row opens a read-only detail sheet, and editing starts from its Edit action. Wizard experience rows also show company metadata. The observed row stack and gap tokens are in frontmatter.

Tasks opens with the dog mascot leaning on the quick capture card, its speech bubble beside it, then the progress widgets, the Import tasks row, and the task search, which heads the grouped task list. Each of these sits on the canvas with 16-point side margins and 12 points below it. A native toolbar menu holds manual entry and, while an unfinished capture draft exists, Discard draft. Saved Jobs shows the mascot and its speech bubble above the list, hidden while searching, then its Captured jobs and Saved jobs sections.

Native navigation, forms, keyboard behavior, and safe areas govern supporting screens. Wizard progress uses 18-point horizontal and 12-point vertical padding, with 2-point segments separated by 4 points.

Primary plain lists and WorkspaceSurface content are centered with a maximum width of 760 points. Keep this readable single-column limit on wide displays; no custom breakpoint or multi-pane iPad contract is implemented.

## Elevation & Depth

Ordinary rows stay flat, separated by hairlines. Grouped forms, widget tiles, the task search field, and the speech bubble use tonal surface contrast, never shadows. The mascot is the one layered element: it draws over the quick capture card's top edge. System sheets, menus, and bars retain native presentation.

**The Flat List Rule.** Use separators and spacing for list hierarchy; retain native elevation for sheets and bars.

## Shapes

Primary buttons use gently rounded 8-point rectangles. Cards on Tasks (progress widgets, the Import tasks row, the task search field) use a 12-point radius; the quick capture card uses 16 points and its white input field 8 points. The speech bubble has 14-point corners and a tail pointing at the mascot. Metadata and the filter chip use capsules. List rows remain rectangular and edge-aligned. Native form grouping retains platform shape behavior. Selection uses SF Symbols circles rather than custom illustration; the mascot is the only illustration.

## Components

### Buttons
Coral primary actions use the frontmatter padding, an 8-point radius, and a minimum 44-point height. Enabled labels are charcoal in both themes. Pressing reduces coral opacity to 80%; disabled buttons drop it to 40% and switch the label to adaptive ink, so it stays readable on the dimmed coral in dark appearance. Compact placements reduce the padding: the API key Save, the wizard's compact Save, and quick capture's Record task, which keeps a 40-point minimum height. Task detail uses action ink for the affirmative Edit action and semantic red for the destructive Delete action, with the native confirmation alert retained. Secondary toolbar and navigation actions use native controls. Avoid importing the reference's white-on-coral small text where the implementation deliberately uses darker ink.

### Chips
Metadata capsules use the object tint at 16% with adaptive object ink and semibold caption text. They describe content and are not controls. The one capsule control is the Tasks company-filter chip: the same tint, ink, and type plus an xmark, a 44-point minimum height, and the accessibility label "Remove company filter". Tapping it clears the filter.

### Cards / Containers
Grouped forms use the quiet adaptive surface through `WorkspaceSurface`. Primary lists use the canvas, not a stack of floating cards; on Tasks only the controls above the list are cards: the coral quick capture card and card-surface tiles for the widgets, Import tasks, and the search field. No custom card-shadow vocabulary exists.

### Quick Capture Card
Quick capture starts as a coral action card: a white circle with the compose icon, "What is your task today", and a down chevron, all in charcoal, with the whole card as the tap target. Tapping it opens the recorder and focuses the field; an up chevron with a 44-point hit region folds it again. Open, it adds a short caption, a white multi-line field with charcoal text and prompt in both themes, and a compact Record task button that stays disabled until there is text. Record task opens a sheet to confirm the details, role, and company. A restored draft opens the card; recording a task folds it. Opening and folding use a 200ms ease-out, which Reduce Motion removes. The card's top padding keeps its title and chevron clear of the leaning mascot.

### Task Search
The task search is one card-surface field with a 12-point radius and the same 16-point side margins as the cards above it. It holds a search icon, a clear button while text is entered, and a company filter menu whose icon turns action ink while a filter is active. It shows no result count. An active company filter appears below the field as the removable chip described under Chips.

### Mascot and Speech Bubble
The dog mascot appears on Tasks and Saved Jobs at 112 points. On Tasks it leans on the quick capture card: it sits on the card's top edge at the trailing side with its lower part over the card, and the bubble sits to its leading side. On Saved Jobs the bubble and dog sit above the list. The mascot is decorative: it never takes taps and is hidden from accessibility, and the bubble's title and message are read as one element.
- **Moods follow state.** Curious for first-use guidance (no tasks, or no saved jobs); joyful for six seconds after quick capture records a task; wink otherwise.
- **Messages stay short and factual.** Tasks shows first-use guidance until experience exists, then a count of reusable tasks. Saved Jobs nudges the first save, then says how many saved jobs are ready for a resume, using the same rule as each row's status. With no saved jobs, the empty state below keeps only its title and Add job, so the message is not repeated.
- **Motion.** Each mood has a still image and an animated WebP in the asset catalog (`Mascot/cvee-<mood>` and `Mascot/cvee-<mood>-animated`). The animation plays twice when a mood appears, then rests on the still; frames decode off the main thread. Reduce Motion or turning off Auto-Play Animated Images shows the still only.
- **Bubble.** Card surface with a divider hairline and a tail pointing at the mascot. The title uses `.headline` in primary ink; the message uses `.subheadline` in secondary ink.
- **Accessibility sizes.** The dog shrinks to 72 points and sits above the bubble, whose tail points up; on Tasks the card follows below without overlap.

### Progress Widgets
A "Your progress" row sits below quick capture, with Edit (Add widgets when none are shown) in action ink. Widgets are card-surface tiles with a 12-point radius and no shadow, laid out two per row with equal heights within a row; a lone widget stays half width, and accessibility sizes use one per row. The default pair is Tasks by company (a donut of the top four companies plus Other, with the total in the center and a legend row for every slice) and Used in resumes (the percent of tasks linked to a saved resume, with a Chart 1 bar). Resumes saved, Jobs ready, and Last 30 days can be added. Edit opens a full-height native list in edit mode to add, remove, reorder, or reset to the default; the layout persists in `tasks.metricWidgets`. Each tile is read as one element: its title and a spoken summary.

**Coverage is descriptive only.** Widgets count what is stored on the device. They never score a resume or imply hiring outcomes.

### Inputs / Fields
Use native TextField, TextEditor, and form rows with persistent field labels where present. Saved Jobs and the wizard's experience and job steps use native `searchable`; Tasks uses the custom search field above. Native focus and keyboard behavior remain authoritative. Wizard prompts explicitly use adaptive secondary ink, as do saved-job and resume dates. Required identity-field guidance appears before the fields. Preserve these contrast treatments instead of inheriting pale default prompts. Keep error and availability messages explicit in text. Profile, provider-key, and structured resume inputs retain persistent labels. Required wizard fields are marked, and disabled Continue actions explain the missing prerequisite. Use keyboard dismissal controls and native focus progression.

### Navigation
Retain five native tabs: Tasks, Saved Jobs, Resume Wizard, Resumes, Profile. Each owns a NavigationStack. Adaptive action ink marks the active tint; page-colored toolbar backgrounds integrate with the canvas. Native dimensions and adaptations remain system-owned.

### Rows and Selection
Company headers expose expanded/collapsed accessibility state and a minimum 44-point hit region. Selection circles appear in import and wizard choice flows, expose state on their owning control, and hide the decorative symbol from accessibility. Selection animates with 200ms ease-out and a 1.05 selected scale; Reduce Motion disables that animation. Company collapse uses the same duration and Reduce Motion guard.

Saved Jobs rows show the title, a company capsule, a status (green when ready for a resume, secondary otherwise), and the date, and end with a secondary-ink chevron so the whole row reads as tappable, like the Import tasks row and the Resumes list. Each Saved Jobs row is read as one element.

### Empty States, Confirmation, and Failures
- Empty libraries offer their next action: Saved Jobs offers Add job, Resumes offers Create resume (which opens the wizard), and the wizard's experience and job steps offer Add experience and Add job. The Tasks empty state has no button; quick capture sits above it.
- Searches with no results offer a way back: Clear search, or Clear search and filters on Tasks.
- Deleting a task, job, resume, resume section, or API key, and discarding an unfinished capture draft, require confirmation. Clear all data requires typing CLEAR.
- Failed saves and deletions are reported in an alert or inline message, and the current content is kept.

### Resume Wizard
A textual step name and count accompany thin segments: green for prior steps, coral for current, divider tone for upcoming. Accessibility reads the step count, title, and guidance as one element. Step guidance wraps and is hidden visually while any wizard field has keyboard focus, including the generated-resume editor. Keyboard dismissal lives in the top navigation bar while a field is focused, keeping the bottom action clear at accessibility text sizes. At accessibility sizes the navigation title becomes inline.

Native safe-area bottom actions carry Back, Continue, or Generate Resume (Generate replacement once a draft exists) as applicable, with a line above them explaining any missing prerequisite. On the generated step, Edit/Preview, Match, and Save stay in that bar rather than below the PDF; when they do not fit in one row, at any text size, they stack with full labels (Edit resume, Check job match, Save Resume).
- **Review before generating.** The summary shows Profile, Experience, and Target job as separate review rows, each with its own Edit action. The provider and processing location have their own AI processing section with a Configure AI provider button.
- **Errors and recovery come first.** Errors appear at the top of the summary and the draft page, and Return to draft appears before the review rows.
- **Drafts survive navigation.** The generated draft and selections stay available across Back and tab switches for the current session only. Start over requires confirmation, replacing an unsaved draft requires confirmation, and a failed replacement keeps the current draft.
- **Unfinished jobs are repaired in place.** Choosing a job that needs a description or review opens its existing review sheet inside the wizard.
- **Edited text is the source of truth.** The preview, the saved structured content, and export use the current edited text; the saved-resume editor flushes pending changes before export.
- **Phrase coverage is advisory.** The resume report says which reviewed phrases are mentioned and does not verify proficiency or eligibility.

## Do's and Don'ts

### Do:
- Do reuse the shared adaptive colors and existing SwiftUI components.
- Do use native semantic type styles and allow content to grow with Dynamic Type.
- Do keep selection state available as text to assistive technology.
- Do preserve readable foregrounds on coral and pale object tints.
- Do keep generated actions reachable in the safe-area bar and retain draft content during navigation.
- Do place draft recovery and errors before review content, with wizard keyboard dismissal in the top navigation bar.

### Don't:
- Don't add boards, inboxes, assignees, completion workflows, or other Asana features from the visual reference.
- Don't replace the charcoal dark canvas with pure black.
- Don't add shadows to ordinary list rows or turn metadata into heavy color slabs.
- Don't replace adaptive secondary wizard prompts with pale defaults or exceed the centered 760-point content limit.
- Don't let the mascot take taps, cover text, or carry information that the bubble text does not.
