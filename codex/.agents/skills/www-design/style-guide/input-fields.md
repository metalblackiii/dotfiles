# ChiroTouch Design System — Input Fields

Input fields collect text and selections from users.

## Field Types

### Input (Standard Text)

Plain text input with no icons. Used for names, emails, addresses, and general text entry.

### Search

Text input with a magnifying glass icon on the left. Used for filtering and searching within lists or pages.

### Dropdown

Selection field with chevron icon on the right. See `dropdowns.md` for full dropdown specs — this section covers the field/trigger styling in the context of input field states.

### Password

Text input with a visibility toggle (eye/slash-eye) icon on the right. Shows dots when masked, plain text when revealed.

### Text Area

Multiline free-form text input with a resize handle in the bottom-right corner. Used for notes, descriptions, and longer text entry ("Reason for Visit", etc.).

## States

All 5 field types support the same 7 states:

| State | Border | Fill | Text | Notes |
|-------|--------|------|------|-------|
| **Default** | Light gray | White | None | Empty, ready for input |
| **Hover** | Slightly darker gray | White | None | Subtle border emphasis on mouseover |
| **Focus** | Emphasized (teal/Sky) | White | Cursor visible | Active input, ready to type |
| **Typing** | Emphasized | White | User text + cursor | Text being entered |
| **Disabled** | Muted | Gray fill | None or muted | No interaction allowed |
| **Placeholder** | Light gray | White | Gray placeholder text | Hint text (Neutral 600) |
| **Error** | Coral/red | Light coral tint | Text or cursor | Red-tinted background + border |

## Corner Radius

- **Input fields:** 6px
- **Text areas:** 6px

## Label Patterns

### Label Above (default)

```
Label
+---------------------------+
|                           |
+---------------------------+
```

Label is positioned above the field. This is the standard layout for forms.

### Label Inline (beside)

```
Label  +---------------------------+
       |                           |
       +---------------------------+
```

Label appears to the left of the field. Used in compact/horizontal layouts.

### Required Fields

Required fields append an asterisk to the label: `Label *`

### Error State with Message

```
Label
+---------------------------+
|                           |  ← coral tint + red border
+---------------------------+
⚠ Error message here          ← coral text + error icon
```

Error messages appear below the field with a circle-exclamation icon and coral/red text.

### Success State with Message

```
✓ Success message              ← green text + check icon
```

Success messages use green text with a checkmark icon.

## Form Layout Patterns

### Two-Column Grid

Side-by-side fields for related short inputs (e.g., First Name / Last Name):

```
First Name          Last Name
+---------------+   +---------------+
|               |   |               |
+---------------+   +---------------+
```

### Full-Width

Single field spanning the form width for longer inputs (e.g., Email Address):

```
Email Address
+-------------------------------------+
|                                     |
+-------------------------------------+
```

### Textarea

Full-width with taller height and resize handle:

```
Reason for Visit
+-------------------------------------+
|                                     |
|                                     |
|                                  ⌟  |
+-------------------------------------+
```

## neb-www Implementation

- Use `neb-text-field` — don't create custom input elements
- Use `neb-textarea` for multiline fields
- Password fields: use the built-in visibility toggle — don't implement your own show/hide
- Search fields: use the component's built-in search icon — don't prepend icons manually
- Error messages use semantic error colors from `neb-variables.js` (coral tones)
- Corner radius is 6px — not 4px, not 8px
- Placeholder text uses Neutral 600 (`#778991`)
- Labels use Body 2 (14px) or Body Bold 2 (14px Bold) above the field
