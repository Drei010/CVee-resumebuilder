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
  success: "#62D26F"
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
  add-action:
    backgroundColor: "{colors.coral}"
    textColor: "{colors.ink-light}"
    rounded: "{rounded.capsule}"
    width: "56px"
    height: "56px"
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
- **Warm Coral:** primary button surfaces, add action, active navigation tint, and current wizard step. Stable across themes.

### Secondary
- **Object Blue:** a soft tint at 16% opacity behind metadata capsules; separate deeper light-mode and lighter dark-mode foregrounds keep text legible.
- **Selection Green:** selected circles and completed wizard progress segments. It does not introduce task completion behavior.

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

Plain, vertically scrolling lists establish the main spatial rhythm. Work history groups by company with collapsible headers. Rows use a leading document symbol, a content stack, small metadata capsule, and date range; the full row opens editing. The observed row stack and gap tokens are in frontmatter.

The add action sits at the trailing bottom edge, inset 18 points horizontally and 16 vertically, with 80 points of list bottom clearance. Native navigation, forms, keyboard behavior, and safe areas govern supporting screens. Wizard progress uses 18-point horizontal and 12-point vertical padding, with 2-point segments separated by 4 points.

Primary plain lists and WorkspaceSurface content are centered with a maximum width of 760 points. Keep this readable single-column limit on wide displays; no custom breakpoint or multi-pane iPad contract is implemented.

## Elevation & Depth

Ordinary rows stay flat, separated by hairlines. Grouped forms use tonal surface contrast. The single custom elevation treatment belongs to the floating add action: coral at 45% opacity, radius 10 points, offset 0 horizontally and 8 vertically. System sheets, menus, and bars retain native presentation.

**The Flat List Rule.** Use separators and spacing for list hierarchy; reserve the custom shadow for the floating add action.

## Shapes

Primary buttons use gently rounded rectangles. Metadata uses capsules; the add action is circular. List rows remain rectangular and edge-aligned. Native form grouping retains platform shape behavior. Selection uses SF Symbols circles rather than custom illustration.

## Components

### Buttons
Coral primary actions use charcoal labels in both themes, the frontmatter padding, and a minimum 44-point height. Pressing reduces coral opacity to 80%; disabled surfaces use 40%. Task detail uses coral for the affirmative Edit action and semantic red for the destructive Delete action, with the native confirmation alert retained. Secondary toolbar and navigation actions use native controls. Avoid importing the reference's white-on-coral small text where the implementation deliberately uses darker ink.

### Chips
Metadata capsules use the object tint at 16% with adaptive object ink and semibold caption text. They describe content and are not standalone filter controls.

### Cards / Containers
Grouped forms use the quiet adaptive surface through `WorkspaceSurface`. Primary lists use the canvas, not a stack of floating cards. No custom card-shadow vocabulary exists.

### Inputs / Fields
Use native TextField, TextEditor, searchable, and form rows with persistent field labels where present. Native focus and keyboard behavior remain authoritative. Wizard prompts explicitly use adaptive secondary ink, as do saved-job and resume dates. Required identity-field guidance appears before the fields. Preserve these contrast treatments instead of inheriting pale default prompts. Keep error and availability messages explicit in text.

### Navigation
Retain five native tabs: Tasks, Saved Jobs, Resume Wizard, Resumes, Profile. Each owns a NavigationStack. Coral marks the active tint; page-colored toolbar backgrounds integrate with the canvas. Native dimensions and adaptations remain system-owned.

### Experience Row and Selection
Company headers expose expanded/collapsed accessibility state and a minimum 44-point hit region. Selection circles appear in import and wizard choice flows, expose state on their owning control, and hide the decorative symbol from accessibility. Selection animates with 200ms ease-out and a 1.05 selected scale; Reduce Motion disables that animation. Company collapse uses the same duration and Reduce Motion guard.

### Wizard Progress
A textual step name and count accompany thin segments: green for prior steps, coral for current, divider tone for upcoming. Accessibility reads the step and title together. Native bottom actions carry Back, Next, or Generate Resume as applicable.

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
