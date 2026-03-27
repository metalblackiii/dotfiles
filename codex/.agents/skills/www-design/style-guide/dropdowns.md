# ChiroTouch Design System — Dropdowns

A dropdown lets users select from a list of options.

## Variants

### Single-Select

Standard dropdown — one option at a time.

- **Closed:** Rounded container with border, placeholder text ("Selection"), chevron-down icon
- **Open:** Chevron rotates up, panel drops below with options list
- **Selected item:** Light blue/Sky background highlight
- **Hover item:** Subtle light background
- **Action item:** Sky-colored text at the bottom of the list (e.g., "Add new" link)

### Multi-Select

Dropdown with inline checkboxes for selecting multiple items.

- Same trigger as single-select
- Each option has a checkbox to its left
- Checked items show Sky/cyan checkbox with white checkmark
- Unchecked items show empty checkbox
- Panel stays open while user selects/deselects

### Searchable

Dropdown with a search field at the top for filtering long lists.

- Same trigger as single-select
- Open panel has a search input (with magnifying glass icon) pinned at top
- Options filter as user types
- Selected/hover highlighting same as single-select
- Scrollable list below the search input

## Anatomy

### Trigger (closed state)

```
+---------------------------+
| Selection              v  |
+---------------------------+
```

- Rounded border (~4px radius)
- Placeholder: "Selection" in Neutral 600 text
- Chevron-down icon on right
- Optional label above: Body 3 (12px Regular) in Neutral 600

### Panel (open state)

```
+---------------------------+
| Selection              ^  |
+---------------------------+
| Label                     |  ← option (hover = light blue bg)
| Label                     |  ← option (selected = light blue bg)
| Label                     |
| Label                     |  ← action item = Sky text
+---------------------------+
```

- White background
- Subtle shadow/elevation (the only place depth via shadow is used in controls)
- Options: Body 2 (14px Regular) text
- Scrollbar appears on long lists
- Panel drops below trigger (never above in standard usage)

## States

| State | Trigger Appearance | Panel |
|-------|-------------------|-------|
| **Default** | Gray border, placeholder text | Hidden |
| **Open** | Slightly emphasized border, chevron up | Visible with shadow |
| **Selected** | Selected value replaces placeholder | Highlighted row |
| **Disabled** | Muted border and text, no chevron interaction | N/A |

## Label Pattern

Dropdowns can have an optional label positioned above:

```
Label
+---------------------------+
| Selection              v  |
+---------------------------+
```

Label uses Body 3 or Body 2 text in Neutral 600/700. The label is outside the control, not inside.

## neb-www Implementation

- Use `neb-select`, `neb-dropdown`, or `neb-md-select` — don't create custom dropdowns
- Multi-select uses checkboxes from the design system (see `controls.md`)
- Searchable variant uses an inline text input — match `neb-text-field` styles for the search box
- Selected highlight color: Sky 100 or Sky 200 background
- Dropdown panel is the one UI control where a subtle `box-shadow` is appropriate (per design system)
- Action links at the bottom of the list use Sky text color, matching tertiary button style
