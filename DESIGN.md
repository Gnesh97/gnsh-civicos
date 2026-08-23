---
name: CivicOS Civic Ledger
description: A Swiss-grid municipal operations surface with restrained liquid-glass controls.
colors:
  primary: "#8ca9ff"
  primary-strong: "#6d8dff"
  page: "#0b0e13"
  surface: "rgba(22, 28, 37, 0.72)"
  surface-strong: "rgba(28, 35, 46, 0.9)"
  ink: "#f2f4f7"
  ink-dim: "rgba(242, 244, 247, 0.68)"
  ink-muted: "rgba(242, 244, 247, 0.42)"
  line: "rgba(242, 244, 247, 0.12)"
  line-strong: "rgba(242, 244, 247, 0.22)"
  danger: "#ffb1b1"
typography:
  display:
    fontFamily: "IBM Plex Sans, Hanken Grotesk, Barlow, Host Grotesk, DM Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(1.32rem, 2vw, 1.7rem)"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "-0.025em"
  body:
    fontFamily: "IBM Plex Sans, Hanken Grotesk, Barlow, Host Grotesk, DM Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.83rem"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "IBM Plex Mono, ui-monospace, monospace"
    fontSize: "0.65rem"
    fontWeight: 400
    lineHeight: 1.2
    letterSpacing: "0.1em"
rounded:
  sm: "8px"
  md: "9px"
  lg: "14px"
  pill: "999px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "30px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#10131a"
    rounded: "{rounded.md}"
    padding: "10px 16px"
    height: "44px"
  button-secondary:
    backgroundColor: "rgba(255, 255, 255, 0.045)"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "10px 16px"
    height: "44px"
  glass-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "clamp(20px, 3vw, 30px)"
  state-chip:
    backgroundColor: "rgba(140, 169, 255, 0.14)"
    textColor: "{colors.primary}"
    rounded: "{rounded.pill}"
    padding: "4px 9px"
---

# Design System: CivicOS Civic Ledger

## Overview

**Creative North Star: “The Civic Ledger”**

CivicOS presents municipal work as a living service ledger. A strict Swiss grid keeps role, queue, status, and action legible; a restrained liquid-glass layer gives the active surface depth without turning every container into decoration. The world is dark because the NUI runs inside a game session, where a low-luminance canvas keeps the workbench quiet and the cobalt accent marks only attention and action.

The interface is desktop-first and operational. It preserves the existing citizen and staff workflows while replacing the generic dashboard treatment with clear columns, tabular numerics, thin rules, and a small set of tactile controls.

**Key Characteristics:**

- Swiss grid and generous whitespace.
- Cobalt as the single visual accent.
- IBM Plex Sans for interface copy, IBM Plex Mono for data labels.
- Glass reserved for surfaces and controls that need depth.

## Colors

Deep graphite surfaces carry neutral text; cobalt is the one accent used for focus, primary actions, and state chips. Error copy uses a dedicated semantic danger token only when recovery information must stand out.

### Primary

- **Cobalt signal** (`#8ca9ff`): primary actions, focus rings, active rules, and status chips.
- **Cobalt press** (`#6d8dff`): pressed/strong accent states.

### Neutral

- **Night canvas** (`#0b0e13`): page background.
- **Glass surface** (`rgba(22, 28, 37, 0.72)`): primary cards and work areas.
- **Raised glass** (`rgba(28, 35, 46, 0.9)`): stronger surface contexts.
- **Ink** (`#f2f4f7`): primary text.
- **Ink dim** (`rgba(242, 244, 247, 0.68)`): supporting text and values.
- **Ink muted** (`rgba(242, 244, 247, 0.42)`): labels and quiet metadata.
- **Hairline** (`rgba(242, 244, 247, 0.12)`): separators and table rules.

### Named Rules

**The One Accent Rule.** Cobalt is the only visual accent; hierarchy comes from opacity, weight, and placement.

## Typography

**Display Font:** IBM Plex Sans (with Hanken Grotesk, Barlow, Host Grotesk, DM Sans, and system sans fallbacks)
**Body Font:** IBM Plex Sans (with Hanken Grotesk, Barlow, Host Grotesk, DM Sans, and system sans fallbacks)
**Label/Mono Font:** IBM Plex Mono (with ui-monospace fallback)

**Character:** IBM Plex Sans keeps headings rational and calm; IBM Plex Mono turns references, labels, and status values into aligned operational data.

### Hierarchy

- **Display** (400, `clamp(1.32rem, 2vw, 1.7rem)`, line-height 1): CivicOS identity.
- **Headline** (400, `clamp(1.14rem, 1.6vw, 1.38rem)`, line-height 1.15): section titles.
- **Body** (400, `0.83rem`, line-height 1.4): form controls and table values.
- **Label** (400, `0.65rem`, `0.1em` tracking, uppercase): roles, table headings, and metadata.

### Named Rules

**The Tabular Truth Rule.** IDs, counts, and status values use IBM Plex Mono and tabular numerals so operations can be scanned without visual drift.

## Layout

The desktop surface uses a two-column workbench inside a capped 1440px canvas. The request queue owns the wide column; new-request intake stays visible in the narrower column; staff operations span the full width below when authorized. The header and three overview measures span both columns. Spacing follows an 8px base with 12px, 16px, 24px, and 30px working steps. Tables keep a minimum readable width and scroll inside their own panel rather than reflowing the operational columns.

## Elevation & Depth

Depth is a hybrid of tonal layering, a soft neutral shadow, and backdrop blur. Cards remain readable as dark translucent slabs; the glass effect is reserved for surfaces and secondary controls. The cobalt accent never becomes a diffuse shadow.

### Shadow Vocabulary

- **Ambient surface** (`0 24px 80px rgba(0, 0, 0, 0.34)`): primary cards only.
- **Overview flat:** overview cards omit the ambient shadow and rely on tonal contrast.

### Named Rules

**The Material Rule.** Blur and translucency must explain a surface or control state; never add glass to empty decoration.

## Shapes

Cards use a gentle 14px radius; inputs and buttons use 9px; status chips use a pill silhouette. Borders stay 1px and low-contrast. Structural containers remain rectilinear enough to read as a ledger, while controls may soften for touch and focus.

## Components

### Buttons

- **Shape:** compact 9px radius (`9px`), minimum height 44px.
- **Primary:** cobalt background, dark text, 10px 16px padding.
- **Hover / Focus:** slight lift and visible cobalt focus ring; transitions are limited to color, border, shadow, and transform.
- **Secondary:** translucent glass fill, hairline border, light text.

### Chips

- **Style:** cobalt wash, cobalt text, 1px cobalt border, pill radius.
- **State:** communicates request/work-order status without relying on color alone; the status word remains visible.

### Cards / Containers

- **Corner Style:** 14px radius.
- **Background:** translucent graphite gradient over the dark canvas.
- **Shadow Strategy:** ambient neutral shadow on work areas; flat overview cards.
- **Border:** 1px hairline with a restrained top reflection.
- **Internal Padding:** 20–30px by viewport width.

### Inputs / Fields

- **Style:** 46px minimum height, dark translucent fill, 1px raised hairline, 9px radius.
- **Focus:** cobalt border plus a visible 2px focus outline.
- **Error / Disabled:** danger surface for recoverable errors; disabled controls reduce opacity and stop motion.

### Navigation

The existing Close button and Escape behavior remain the navigation boundary. The header presents identity and session context without adding a new navigation hierarchy.

## Do's and Don'ts

### Do:

- **Do** keep the request queue and the new-request form in the first desktop viewport.
- **Do** use opacity and spacing for hierarchy before adding color.
- **Do** keep IDs, references, statuses, and counts tabular and aligned.
- **Do** preserve keyboard focus, readable labels, and reduced-motion behavior.

### Don't:

- **Don't** introduce a second brand accent for ordinary state changes.
- **Don't** hide operational status behind color-only chips.
- **Don't** turn every element into a floating glass pill.
- **Don't** add mobile-specific stacking or change existing NUI/API behavior without a new brief.
