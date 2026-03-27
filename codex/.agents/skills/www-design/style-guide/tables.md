# ChiroTouch Design System — Tables

Tables display structured data in rows and columns.

## Container Variants

### Bordered Container

Table wrapped in a rounded-corner card with a visible border. Used when the table is the primary content area on a page.

```
+-----------------------------------------------+
| Header    | Header    | Header    | Header     |
|-----------|-----------|-----------|------------|
| Text      | Text      | Active    |     v      |
|-----------|-----------|-----------|------------|
| Text      | Text      | Active    |     v      |
+-----------------------------------------------+
```

- Rounded outer border (card container)
- Light border color (Neutral 300/400)
- No outer shadow — flat with border

### Borderless

Table without an outer container — rows separated by horizontal dividers only. Used when the table is embedded within a larger layout.

```
  Header    | Header    | Header    | Header
 -----------|-----------|-----------|----------
  Text      | Text      | Active    |     v
 -----------|-----------|-----------|----------
  Text      | Text      | Active    |     v
```

- No outer border or card wrapper
- Horizontal row dividers only (light gray, Neutral 300)

### Compact Borderless

Same as borderless but at a reduced density — tighter row height and spacing. Used for data-dense views with many rows.

## Cell Types

Tables are composed from standardized cell parts. Each cell type exists at multiple density levels (compact, default, comfortable).

### Header Cell

- **Text:** Bold (Header 9/10 — 14px Bold or Semibold)
- **Background:** White or very light gray (Neutral 100/200) depending on variant
- **Border:** Bottom border (Neutral 300) separating header from data rows

### Data Cell (Text)

- **Text:** Body 2 (14px Regular), Neutral 900
- **Border:** Bottom border (light horizontal divider)

### Status Badge Cell

- **Badge:** "Active" pill with Green 100 background and Green 500/600 text
- **Shape:** Small rounded pill (full border-radius)
- Badge is inline within the cell, not full-width

### Action Cell (Chevron)

- **Icon:** Chevron-down icon for row expansion or dropdown action
- **Size:** Standard icon size, vertically centered in cell

### Toggle Cell

- **Control:** Toggle/switch (see `controls.md`) inline in the cell
- Uses Sky for on state, gray for off

### Icon Action Cells

- **Edit:** Pencil/edit icon for row editing
- **More:** Three-dot (ellipsis) menu for additional actions
- Icons are right-aligned, typically the last columns

## Row Patterns

### Standard Data Row

```
| Text data | Text data | Status badge | Text data | Action chevron |
```

### Settings/Admin Row

```
| Text name | Text category | Number | Date | Toggle | Edit icon | More menu |
```

### Row Separation

- Horizontal dividers between rows (Neutral 300 border)
- **No alternating row colors** — all rows have the same white background
- Hover state: subtle background highlight (Neutral 100/200)

## Leading Column Variants

Tables can have a leading column that is:
- **Blank/spacer** — visual padding for indented tables
- **Checkbox** — for bulk selection (uses checkboxes from `controls.md`)
- **None** — data starts in the first column (most common)

## Table Page Layout Pattern

From the AI Scribe Templates example — the standard collection/list page:

### Structure

```
+--sidebar--+--main content area--------------------------+
|           | Page Title                    [+ Action btn] |
| Nav       | Description text                             |
| sections  |                                              |
|           | Search field    | Filter dropdown | Checkbox |
|           |                                              |
|           | +-table header------------------------------+|
|           | | Col 1 | Col 2 | Col 3 | Col 4 | Col 5    ||
|           | |--------|-------|-------|-------|----------||
|           | | row 1                                     ||
|           | | row 2                                     ||
|           | | ...                                       ||
|           | +-------------------------------------------+|
+-----------+----------------------------------------------+
```

### Key Details

- **Page title:** Header 4 (24px Bold)
- **Description:** Body 2 (14px Regular), below title
- **Primary action button:** Top-right, Sky filled pill ("+ Create Template")
- **Filter bar:** Above table — search field + category dropdown + checkbox filter, horizontally aligned
- **Table:** Full-width within the content area
- **Sidebar:** Dark Ocean background, collapsible sections with chevrons
  - Active section: Sky-colored text
  - Active sub-item: Sky left border highlight with Sky background tint

### Sidebar Navigation

- **Background:** Ocean 600 (`#192F49`)
- **Section headers:** White text, bold, with chevron-down for expansion
- **Active section:** Sky-colored text
- **Sub-items:** Regular weight white text, indented
- **Active sub-item:** Sky left-border accent bar + light Sky background tint
- **Logo area:** Top of sidebar, "chirotouch | rheo" branding

## neb-www Implementation

- Use `baseTableStyles` from `neb-styles/neb-table-styles.js` — don't create custom table styles
- Use `CollectionPage` base class for table + filter + action button page patterns
- Status badges use `neb-category` or semantic badge component — don't manually style pill badges
- Row actions (edit, more menu) should use `neb-icon` for icons
- Toggles in table cells use the same `neb-toggle`/`neb-switch` as standalone toggles
- For bulk selection, add checkbox column using `neb-checkbox` per row
- No zebra striping — all rows are white, hover adds Neutral 100/200 background
