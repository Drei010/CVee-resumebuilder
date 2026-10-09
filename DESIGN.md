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

Warm coral marks actions; restrained blue metadata and green selection provide supporting meaning. Frontmatter contains the extracted primitive values; light/dark pairs resolve through `CVeeColors` in `ContentView.swift`.

### Primary
- **Warm Coral:** primary button and quick-capture surfaces, and the current wizard step. Stable across themes.
- **Action Ink:** deeper coral text in light appearance and lighter coral text in dark appearance, for native links, controls, and selected navigation.

### Secondary
- **Object Blue:** a soft tint at 16% opacity behind metadata capsules; separate deeper light-mode and lighter dark-mode foregrounds keep text legible.
- **Selection Green:** selected circles, completed wizard progress segments, and ready-status labels. Darker green in light appearance keeps small text readable. It does not introduce task completion behavior.

### Neutral
- **Canvas White / Canvas Charcoal:** primary screen backgrounds.
- **Quiet Surface:** grouped form backgrounds.
- **Hairline Divider:** list separators and future wizard segments.
- **Primary Ink:** adaptive body text; the light-mode charcoal also stays on coral button surfaces in both themes.
- **Secondary Ink:** descriptions, date ranges, and counts.

**The Accent Rule.** Keep coral focused on actions and active state; use object tint only for compact metadata.

## Typography

**Display Font:** native SF through SwiftUI semantic styles.
**Body Font:** native SF through SwiftUI semantic styles.
**Label/Mono Font:** SF; monospaced digits for dates/counts and the native monospaced body style for text export previews.

Native SF is explicitly permitted by the supplied reference; no bundled font is required. Frontmatter weights capture recurring roles, while semantic SwiftUI styles own size, leading, and Dynamic Type behavior. CSS lengths in portable tokens correspond to iOS points at the default content size, not a fixed type-scale contract.

### Hierarchy
- **Display:** native navigation titles; detail screens may use inline titles.
- **Headline:** `.headline` for wizard steps and saved content titles.
- **Row:** `.subheadline.weight(.medium)` for work experience titles.
- **Body:** native body text and subheadline descriptions.
- **Label:** semibold caption metadata, bold caption company headers, and semibold subheadline primary buttons.

## Layout

Plain, vertically scrolling lists establish the main spatial rhythm. Work history groups by company with collapsible headers. Rows lead with the achievement, followed by role and dates; the full row opens editing. Wizard selection rows also show company metadata. The observed row stack and gap tokens are in frontmatter.

Tasks opens with the dog mascot leaning on the quick capture card, its speech bubble beside it, then editable progress widgets, document import, the task search, and a native toolbar menu for manual entry. Quick capture starts as a coral action card (icon, "What is your task today", chevron); tapping it opens the recorder and focuses the field, and its chevron folds it again. A restored draft opens it on launch; recording a task folds it. The task search is one card-surface field with the same 16-point side margins and 12-point radius as the cards above and no result count; an active company filter appears as a removable chip below it. The bubble carries first-use guidance until experience exists, then a short count of reusable tasks. Native navigation, forms, keyboard behavior, and safe areas govern supporting screens. Wizard progress uses 18-point horizontal and 12-point vertical padding, with 2-point segments separated by 4 points.

Primary plain lists and WorkspaceSurface content are centered with a maximum width of 760 points. Keep this readable single-column limit on wide displays; no custom breakpoint or multi-pane iPad contract is implemented.

## Elevation & Depth

Ordinary rows stay flat, separated by hairlines. Grouped forms use tonal surface contrast. System sheets, menus, and bars retain native presentation.

**The Flat List Rule.** Use separators and spacing for list hierarchy; retain native elevation for sheets and bars.

## Shapes

Primary buttons use gently rounded rectangles. Metadata uses capsules. List rows remain rectangular and edge-aligned. Native form grouping retains platform shape behavior. Selection uses SF Symbols circles rather than custom illustration.

## Components

### Buttons
Coral primary actions use charcoal labels in both themes, the frontmatter padding, and a minimum 44-point height. Pressing reduces coral opacity to 80%; disabled surfaces use 40%. Task detail uses action ink for the affirmative Edit action and semantic red for the destructive Delete action, with the native confirmation alert retained. Secondary toolbar and navigation actions use native controls. Avoid importing the reference's white-on-coral small text where the implementation deliberately uses darker ink.

### Chips
Metadata capsules use the object tint at 16% with adaptive object ink and semibold caption text. They describe content and are not standalone filter controls.

### Cards / Containers
Grouped forms use the quiet adaptive surface through `WorkspaceSurface`. Primary lists use the canvas, not a stack of floating cards. No custom card-shadow vocabulary exists.

### Inputs / Fields
Use native TextField, TextEditor, searchable, and form rows with persistent field labels where present. Native focus and keyboard behavior remain authoritative. Wizard prompts explicitly use adaptive secondary ink, as do saved-job and resume dates. Required identity-field guidance appears before the fields. Preserve these contrast treatments instead of inheriting pale default prompts. Keep error and availability messages explicit in text. Profile, provider-key, and structured resume inputs retain persistent labels. Required wizard fields are marked, and disabled Continue actions explain the missing prerequisite. Use keyboard dismissal controls and native focus progression. In the wizard, keyboard dismissal lives in the top navigation bar while a field is focused, keeping the bottom action clear at accessibility text sizes.

### Navigation
Retain five native tabs: Tasks, Saved Jobs, Resume Wizard, Resumes, Profile. Each owns a NavigationStack. Adaptive action ink marks the active tint; page-colored toolbar backgrounds integrate with the canvas. Native dimensions and adaptations remain system-owned.

### Experience Row and Selection
Company headers expose expanded/collapsed accessibility state and a minimum 44-point hit region. Selection circles appear in import and wizard choice flows, expose state on their owning control, and hide the decorative symbol from accessibility. Selection animates with 200ms ease-out and a 1.05 selected scale; Reduce Motion disables that animation. Company collapse uses the same duration and Reduce Motion guard.

### Wizard Progress
A textual step name and count accompany thin segments: green for prior steps, coral for current, divider tone for upcoming. Accessibility reads the step and title together. Native safe-area bottom actions carry Back, Continue, or Generate Resume as applicable. On the generated step, Edit/Preview, Match, and Save remain in that bar rather than below the PDF. At accessibility sizes, secondary actions stack and the navigation title becomes inline. Step guidance wraps and is read with the step name; it is hidden visually while an identity field has keyboard focus.

## Do's and Don'ts

### Do:
- Do reuse the shared adaptive colors and existing SwiftUI components.
- Do use native semantic type styles and allow content to grow with Dynamic Type.
- Do keep selection state available as text to assistive technology.
- Do preserve readable foregrounds on coral and pale object tints.

### Don't:
- Don't add boards, inboxes, assignees, completion workflows, or other Asana features from the visual reference.
- Don't replace the charcoal dark canvas with pure black.
- Don't add shadows to ordinary list rows or turn metadata into heavy color slabs.
- Don't replace adaptive secondary wizard prompts with pale defaults or exceed the centered 760-point content limit.

## Workflow Refinement — September 30, 2026

Empty libraries offer their next action; no-result searches offer Clear search. Resumes can open the wizard directly. Unfinished jobs open existing review sheets inside the wizard.

The generation summary shows profile, experience, job, and provider processing location in separate review rows. Drafts remain available across Back and tab navigation. Start over and replacement require confirmation; failed replacement retains the current draft. Return to draft appears before the review fields, and errors appear first on the summary or draft page. Wizard recovery is limited to the current session.

Generated preview, saved structured content, and export use the current edited text. Saved editor export flushes pending changes. Task, job, and resume deletion require confirmation; failed persistence is surfaced. Resume phrase coverage remains advisory.

## Mascot and Progress Widgets — October 9, 2026

- **Mascot:** on Tasks the dog (112 points) sits on the quick capture card's top edge at its trailing side, its lower part over the card, with the speech bubble to its leading side. It never takes taps, and the card's top padding keeps its title and chevron clear of it. Saved Jobs shows the same bubble and dog above its list (hidden while searching): a nudge to save a first job, then how many saved jobs are ready for a resume. With no jobs, the empty state below it keeps only its title and Add job, so the message is not repeated. Moods map to state: curious for first-use guidance, joyful for six seconds after a task is recorded, wink otherwise. Each mood ships as a still image and an animated WebP in `Assets.xcassets/Mascot`. The animation plays twice when the mood appears, then rests on the still; frames decode off the main thread. Reduce Motion or turning off Auto-Play Animated Images shows the still only. The mascot is decorative and hidden from accessibility; the bubble text is read as one element. At accessibility text sizes the dog sits above the bubble, and on Tasks the card follows without overlap.
- **Speech bubble:** card surface with a divider hairline and a tail pointing at the mascot. Title uses `.headline` in primary ink; the message uses `.subheadline` in secondary ink.
- **Progress widgets:** a "Your progress" row sits below quick capture. Widgets are small card-surface tiles (12-point radius, no shadow) laid out two per row (a lone widget stays half width), one per row at accessibility sizes, with equal heights within a row. The default pair is Tasks by company (donut chart, top four companies plus Other, with a legend row for every slice) and Used in resumes (percent of tasks linked to a saved resume). Resumes saved, Jobs ready and Last 30 days can be added. Edit opens a full-height native list in edit mode to add, remove and reorder; the layout persists in `tasks.metricWidgets`.
- **Chart colors:** `CVeeColors.chart1`–`chart4` (teal, purple, ochre, magenta) plus secondary ink for Other. They are data-only and stay clear of coral (actions), green (selection) and object blue (metadata). Each holds at least 4:1 on the card surface in both themes. The Used in resumes bar uses `chart1`.
- **Coverage is descriptive only.** Widgets count what is stored on the device. They never score a resume or imply hiring outcomes.
- **Saved Jobs rows** end with a secondary-ink chevron so the whole row reads as tappable, matching Import tasks and Resumes.

