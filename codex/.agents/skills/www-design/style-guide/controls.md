# ChiroTouch Design System — Controls

A control is used to switch between an enabled or disabled state.

## Toggle (Switch)

A binary on/off control. Two sizes: default and small.

### Anatomy

- **Track:** Rounded pill shape
- **Thumb:** White circle that slides left (off) or right (on)
- Off: light gray track, white thumb on left
- On: Sky/cyan track, white thumb on right

### States

| State | Off | On |
|-------|-----|----|
| **Default** | Gray track, white thumb | Sky track, white thumb |
| **Hover** | Slightly darker gray track | Slightly darker Sky track |
| **Focus** | Teal outline ring around track | Teal outline ring around track |
| **Disabled** | Muted gray track + thumb | Muted gray track + thumb |

### Label Placement

Labels can appear before or after the toggle. Both orientations are valid — match the layout of adjacent controls.

```
[  ] Label     ← label after (default)
Label [  ]     ← label before
```

## Text Toggle (Segmented Control)

A group of mutually exclusive options displayed as a segmented pill.

### Anatomy

- **Container:** Rounded pill with light background
- **Selected segment:** White background with subtle border/shadow
- **Unselected segments:** Transparent background, plain text
- Supports 2 or 3 options

### Variants

- **Horizontal 2-option:** `[Option 1 | Option 2]`
- **Horizontal 3-option:** `[Option 1 | Option 2 | Option 3]`
- **Vertical stacked:** Options stacked, one selected with white background

## Checkbox

A square control for selecting one or more items from a set.

### Anatomy

- **Box:** Rounded square (small border-radius ~4px)
- **Checkmark:** White checkmark on Sky/cyan fill when checked
- Unchecked: light border, white/transparent fill
- Checked: Sky/cyan fill with white checkmark

### States

| State | Unchecked | Checked |
|-------|-----------|---------|
| **Default** | Gray border, white fill | Sky fill, white checkmark |
| **Hover** | Teal border | Darker Sky fill |
| **Focus** | Subtle focus ring | Subtle focus ring |
| **Disabled** | Gray fill, no border | Gray fill, muted checkmark |

### With Label

Labels can appear before or after the checkbox. States also apply to the label text:

| State | Label Appearance |
|-------|-----------------|
| **Default** | Neutral 900 text |
| **Hover** | Neutral 900 text |
| **Focus** | Light background highlight |
| **Selected** | Sky-colored text (checked state) |
| **Disabled** | Neutral 500 text |

## Radio Button

A circular control for selecting exactly one item from a set.

### Anatomy

- **Circle:** Round border
- **Dot:** Filled Sky/cyan circle inside when selected
- Unselected: gray border, empty
- Selected: Teal border with Sky/cyan filled dot

### States

| State | Unselected | Selected |
|-------|------------|----------|
| **Default** | Gray border, empty | Teal border, Sky dot |
| **Hover** | Teal border | Darker teal border |
| **Focus** | Teal border | Teal border |
| **Disabled** | Gray fill | Gray fill, muted dot |

### With Label

Same label placement rules as checkbox — label before or after.

## Controls + Labels Layout

All three control types (checkbox, radio, toggle) support consistent label pairing:

```
[control] Label     ← control before label (default)
Label [control]     ← label before control
```

Spacing between control and label is consistent across types. Use the same orientation within a group — don't mix label-before and label-after in the same form section.

## neb-www Implementation

- **Checkboxes:** Use `neb-checkbox` — don't create custom checkbox elements
- **Radio buttons:** Use radio group patterns from existing form components
- **Toggles:** Use `neb-toggle` or `neb-switch` wrapper
- **Text toggles:** Use segmented control patterns from existing components
- Accent color for all active/checked states is Sky (`#0caadc` in code, ~Sky 400 in design system)
- Disabled state uses Neutral 500 (`#909BA6`) tones
