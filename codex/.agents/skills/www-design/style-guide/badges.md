# ChiroTouch Design System — Badges

Badges are status indicators that communicate state through color and optional icons.

## Semantic Colors

| Color | Background | Text | Usage |
|-------|-----------|------|-------|
| **Green** | Green 100 tint | Green 600 | Success, active, complete, enabled |
| **Yellow** | Gold 100 tint | Gold 600 | Warning, pending, attention needed |
| **Red** | Coral 100 tint | Coral 600 | Error, inactive, expired, critical |
| **Gray** | Neutral 200 tint | Neutral 800 | Neutral, info, default, N/A |

## Variants

### Text Only

Plain text label on a tinted background pill. The most common variant — used in table status columns.

```
[ Green ]   [ Yellow ]   [ Red ]   [ Gray ]
```

### Icon + Text

Leading semantic icon followed by text label on a tinted background pill. Used when the badge needs stronger visual emphasis or when color alone is insufficient for accessibility.

```
[ ✓ Green ]   [ ⚠ Yellow ]   [ ℹ Gray ]   [ ● Red ]
```

**Icons per color:**
- **Green:** Checkmark circle (success)
- **Yellow:** Half-filled circle / warning indicator
- **Gray:** Info circle (ℹ)
- **Red:** Filled circle / alert indicator

## Sizes

Two sizes, both pill-shaped (full border-radius):

| Size | Usage |
|------|-------|
| **Default** | Standard use in tables, lists, detail views |
| **Compact** | Tighter layouts, inline with smaller text |

## Shape

All badges are **pill-shaped** — full border-radius on both ends. Not square, not rounded-rectangle.

## neb-www Implementation

- Use `neb-category` or the existing badge/status component — don't manually style pill badges
- Color mapping uses the semantic color scales from `colors.md` (Green, Gold, Coral, Neutral)
- Badge backgrounds use the lightest tone (100 level), text uses the darkest (500/600 level)
- Don't invent new badge colors — stick to the 4 semantic colors
- For table status columns ("Active", "Inactive", etc.), always use badges, not plain text
- Icon variants: use existing icon registry, not inline SVGs
