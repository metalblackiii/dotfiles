# ChiroTouch Design System — Buttons

A button triggers an event or action. They let users know what will happen next.

## Button Types

### Primary Button
- **Fill:** Solid Sky background, white text
- **Shape:** Pill (full border-radius)
- **Usage:** Primary CTA, the single most important action on screen

### Secondary Button Blue
- **Fill:** Transparent background, Sky border, Sky text
- **Shape:** Pill (full border-radius)
- **Usage:** Secondary actions alongside a primary button, or standalone when primary is too strong

### Tertiary Button
- **Fill:** No background, no border, Sky text
- **Shape:** Text-only (underline on hover/focus)
- **Usage:** Low-emphasis actions, inline with content, navigation-style actions

### Link Buttons
- **Fill:** No background, no border, Sky/Ocean text with underline
- **Shape:** Text-only
- **Usage:** Inline text links, navigation. Three sizes matching body text scale.

### Secondary Button Gray
- **Fill:** Transparent background, gray border, gray text
- **Shape:** Pill (full border-radius)
- **Usage:** Neutral/dismissive actions (cancel, close), actions that shouldn't draw attention

## States

Every button type supports all 6 states:

| State | Visual Change |
|-------|---------------|
| **Rest** | Default appearance |
| **Hover** | Darker fill (primary) or darker border/text (secondary) |
| **Focus** | Visible focus ring — outline around the button |
| **Active** | Darkest fill/pressed state |
| **Loading** | Spinner icon replaces trailing icon or appears inline |
| **Disabled** | Gray fill (primary) or gray border/text (secondary), no interaction |

## Content Variants

Each button type supports 4 content layouts:

| Variant | Layout | Usage |
|---------|--------|-------|
| **Text only** | `Button` | Standard — most common |
| **Text + trailing icon** | `Button +` | Action with supplementary icon (dropdown arrow, external link) |
| **Leading icon + text** | `+ Button` | Add/create actions |
| **Icon only** | `+` | Compact actions in toolbars, tight spaces. Must have aria-label. |

## Sizes

Three text sizes (matching the typography scale in `typography.md`):
- **Large** (16px Medium) — page-level actions, forms, CTAs
- **Medium** (14px Medium) — default for most UI buttons
- **Small** (12px Medium) — inline actions, table rows, compact UI

## Button Pairing Patterns (from examples)

### Primary + Secondary (most common)
Left-aligned, primary first:
```
[Buy now (filled Sky)] [Learn more (outlined Sky)]
```

### Centered layout
Secondary before primary (reversed reading order):
```
          [Learn more (outlined)] [Buy now (filled)]
```

### Single secondary
When no strong CTA is needed:
```
[Learn more (outlined)]
```

## neb-www Implementation

- Use `neb-button` or `neb-md-button` — never create custom button elements
- Primary = default button role
- Secondary = outline variant
- Always pair primary + secondary for action groups — don't use two primaries side by side
- Loading state must disable the button and show spinner — don't allow double-submit
