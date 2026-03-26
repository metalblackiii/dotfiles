---
name: www-design
description: ALWAYS invoke when building new UI components, pages, or significant visual additions in neb-www. Triggers on new Lit components, page layouts, form views, table views, or any user-facing interface work. Not for backend-only changes, test-only changes, or minor text/copy edits.
---

# neb-www Design System

## Overview

neb-www uses Lit web components with a centralized but undocumented design system. This skill is the design contract — it anchors new UI work to the existing visual vocabulary so first-pass implementations look consistent with the rest of the app.

AI-generated UI converges to the same mediocre aesthetic (Inter font, purple gradients, card-everything, missing states) due to distributional convergence — the model samples from training data's statistical center. This skill overrides that prior with neb-www's actual design values.

## Before You Build

1. **Read the base class** you'll extend (`NebLayout`, `NebForm`, `CollectionPage`, or plain `LitElement`)
2. **Read an adjacent component** — find something similar in the same feature area and match its patterns
3. **Import `baseStyles`** — every component's `static styles` array starts with shared styles

## Design Vocabulary

### Colors

**Brand palette:** `style-guide/colors.md` (relative to this skill) — full ChiroTouch Design System color scales (Sky, Ocean, Green, Gold, Coral, Neutrals). Read this when choosing colors for new UI.

**Implementation constants** (source: `packages/neb-styles/neb-styles.js`, `neb-variables.js`, `src/styles/index.js`).
These are the actual values in code — they predate the design system and don't match brand tokens exactly. Always use these constants in code; the brand palette is for design decisions, not literal hex substitution.

| Role | Code Value | Constant | Nearest Brand Token |
|------|-----------|----------|---------------------|
| Highlight / Action | `#0caadc` | `CSS_COLOR_HIGHLIGHT` | ~Sky 400 (`#0C9FCB`) |
| Error / Danger | `#bf3131` | `CSS_COLOR_ERROR` | ~Coral 500 (`#D65D51`) |
| Border | `#dedede` | `CSS_COLOR_BORDER` | ~Neutral 300 (`#E0E5EB`) |
| Disabled text | `#959595` | `CSS_COLOR_DISABLED` | ~Neutral 500 (`#909BA6`) |
| Light background | `#fafafa` | — | ~Neutral 100 (`#FAFBFC`) |
| White surface | `#ffffff` | — | White |
| Black text | `#000000` | — | ~Neutral 900 (`#333333`) |

Semantic alerts (success, info, warning, error) have foreground/border/background triples in `neb-variables.js`. These map to the design system's Green, Gold, and Coral scales.

Use `fauxpaque()` and `colorFlip()` from `src/styles/index.js` for opacity and state variants — don't invent new color manipulation. When picking new colors, stay within the brand palette scales — don't invent shades.

### Typography

**Full type scale:** `style-guide/typography.md` (relative to this skill) — 10 header levels, 6 body styles, field/button text specs. Read this when building new UI.

**Font: Open Sans** — Bold (700), Semibold (600), Medium (500), Regular (400). No other fonts.

**Default module styles:** Header 4 (24px Bold) for page titles, Body 2 (14px Regular) for body copy.

**Implementation constants** (source: `packages/neb-styles/neb-typography.js`):

| Constant | Design System Token | Size |
|----------|---------------------|------|
| `CSS_FONT_SIZE_CAPTION` | Body 3 | 12px |
| `CSS_FONT_SIZE_BODY` | Body 2 | 14px |
| `CSS_FONT_SIZE_HEADER` | Header 7/8 | 16px |
| — (24px) | Header 4 | 24px |

- Header text color: Midnight `#080808`. Body text color: Charcoal `#333333`.
- Button text uses Medium (500) weight at 12/14/16px sizes.
- Use the full weight range (400–700) — don't flatten to 400/500.

### Spacing

Source: `src/styles/index.js`, `packages/neb-styles/neb-variables.js`

| Value | Usage | Constant |
|-------|-------|----------|
| 20px | Default container/page padding | `CSS_SPACING` |
| 16px | Field margins | — |
| 12px | Compact gaps | — |
| 8px | Row gaps, tight spacing | `CSS_SPACING_ROW` |
| 10px | Small padding | — |
| 5px | Minimal gaps | — |

Stick to these values. If a spacing value isn't in this table, it probably shouldn't be in your component.

### Layout

- **Flexbox is default.** Use `display: flex` for most layouts.
- **Grid for forms and dense layouts.** See `src/styles/index.js:125` for grid conventions.
- Layout helpers: `layoutStyles` from `src/styles/index.js`.

### Icons

- Use `neb-icon` component with the `RENDERER_SVGS` registry from `packages/neb-styles/icons.js`.
- Do NOT use inline SVG, external icon libraries (Lucide, Heroicons), or icon fonts.
- Register new icons in the existing registry pattern — see `packages/neb-styles/icons.js`.

### Component Structure

Standard Lit component pattern:
```js
import { baseStyles } from '../../styles';
// or from packages: import { baseStyles } from '@neb/neb-styles';

class MyComponent extends LitElement {
  static styles = [baseStyles, css`
    :host { display: block; }
    /* component styles */
  `];

  static properties = { /* ... */ };

  render() { return html`...`; }
}
```

Base classes and when to use them:
- `NebLayout` — page-level structural containers
- `NebForm` — form views with validation
- `CollectionPage` — table/list CRUD pages
- Plain `LitElement` — everything else

## Anti-Patterns

These are the specific defaults Claude reaches for that clash with neb-www. Do not use them.

### Typography
- **Do not use Inter, Roboto, Space Grotesk, or system-ui.** neb-www uses Open Sans.
- **Do not flatten weight to 400-500.** Use the full range: 400, 600, 700.
- **Do not use arbitrary font sizes.** Use the design system scale: 12/14/16/18/20/24/28/32/48. Module UI typically uses 12/14/16/24; larger sizes are for headers and hero sections (see `style-guide/typography.md`).

### Color
- **Do not use purple, indigo, or blue-to-purple gradients.** neb-www's accent is cyan `#0caadc`.
- **Do not hardcode hex values.** Import from `neb-styles` or `src/styles/index.js`.
- **Do not invent new grays.** Use the existing gray ramp from `neb-variables.js`.
- **Do not use shadows as the primary hierarchy tool.** neb-www is flat with borders. Depth comes from background color contrast (`#fff` vs `#fafafa`) and borders (`#dedede`), not box-shadow.

### Layout
- **Do not center-align body text.** Left-align is the default. Center is reserved for empty states and login.
- **Do not create three-equal-column grids** for feature sections. Match the layout pattern of adjacent pages.
- **Do not use `rounded-lg` or heavy border-radius.** neb-www uses subtle radius — 4px on form fields, minimal elsewhere.
- **Do not add excessive padding.** neb-www is information-dense. 20px container padding, 8px row gaps.

### Buttons
- **Do not create custom button elements.** Use `neb-button` or `neb-md-button`.
- **Do not use two primary buttons side by side.** Pair primary (filled) + secondary (outlined).
- **Do not skip loading/disabled states.** Buttons must prevent double-submit.
- **Filled and outlined buttons are pill-shaped** (full border-radius). Tertiary and link buttons are text-only — no background or border.
- See `style-guide/buttons.md` (relative to this skill) for the full button system (5 types, 6 states, 4 content variants, 3 sizes).

### Components
- **Do not create new shared style modules.** Use `baseStyles`, `layoutStyles`, `baseTableStyles`.
- **Do not bypass `neb-icon`.** No inline SVG, no external icon libraries.
- **Do not use Material Design components directly.** Use neb's wrapped versions (`neb-md-button`, etc.).

## Completion Checklist

Before marking a new component or page complete, verify:

### Structure
- [ ] Extends the appropriate base class
- [ ] `static styles` array starts with `baseStyles` or relevant shared styles
- [ ] All colors imported from neb-styles constants — no hardcoded hex
- [ ] All spacing from the established scale (5/8/10/12/16/20px)
- [ ] Typography uses the design system scale (12/14/16/18/20/24/28/32/48px) with Open Sans

### States (where applicable)
- [ ] **Hover** — subtle feedback, not dramatic transforms
- [ ] **Focus-visible** — visible keyboard focus ring (not `outline: none`)
- [ ] **Active** — press feedback
- [ ] **Disabled** — visually muted, removed from tab order
- [ ] **Error** — inline validation with semantic error colors, not just red text
- [ ] **Empty / No data** — messaging when tables/lists have no content
- [ ] **Loading** — skeleton or spinner appropriate to context

### Consistency
- [ ] Layout matches adjacent pages in the same feature area
- [ ] Icons use `neb-icon` with `RENDERER_SVGS`
- [ ] Follows the same component structure pattern (imports, styles, properties, render)

## Reference Components

Read these before building new UI in their category:

| Category | Reference |
|----------|-----------|
| Buttons | `packages/neb-lit-components/src/components/neb-button.js` |
| Page layout | `packages/neb-lit-components/src/components/neb-layout.js` |
| Forms | `packages/neb-lit-components/src/components/forms/neb-form.js` |
| Tables | `packages/neb-styles/neb-table-styles.js` |
| Collection pages | `packages/neb-lit-components/src/components/neb-page-collection.js` |
| Icons | `src/components/misc/neb-icon.js` |
| Alerts/categories | `packages/neb-lit-components/src/components/controls/neb-category.js` |
