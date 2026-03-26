# ChiroTouch Design System — Typography

Primary header style for most modules is **Header 4**. Primary body copy is **Body Medium** (Body 2).

## Font

**Open Sans** — the only production font.

Available weights: Bold (700), Semibold (600), Medium (500), Regular (400).

## Header Scale

All headers use Color: Midnight `#080808`.

| Token | Size | Line Height | Weight |
|-------|------|-------------|--------|
| Header 1 | 48px | 64px | Bold |
| Header 2 | 32px | 40px | Bold |
| Header 3 | 28px | 36px | Bold |
| Header 4 | 24px | 32px | Bold |
| Header 5 | 20px | 28px | Bold |
| Header 6 | 18px | 24px | Bold |
| Header 7 | 16px | 22px | Bold |
| Header 8 | 16px | 22px | Semibold |
| Header 9 | 14px | 20px | Bold |
| Header 10 | 14px | 20px | Semibold |

**neb-www mapping:** Header 7/8 (16px) → `CSS_FONT_SIZE_HEADER`, Header 4 (24px) → `CSS_FONT_SIZE_HEADLINE`.

## Body Scale

All body text uses Color: Charcoal `#333333`.

| Token | Size | Line Height | Weight | Usage |
|-------|------|-------------|--------|-------|
| Body 1 | 16px | 24px | Regular | Large body text, descriptions |
| **Body 2** | **14px** | **20px** | **Regular** | **Default body copy** |
| Body 3 | 12px | 16px | Regular | Captions, fine print |
| Body Bold 1 | 16px | 24px | Bold | Emphasized large text |
| Body Bold 2 | 14px | 20px | Bold | Emphasized body copy |
| Body Bold 3 | 12px | 16px | Bold | Emphasized captions |

**neb-www mapping:** Body 2 (14px) → `CSS_FONT_SIZE_BODY`, Body 3 (12px) → `CSS_FONT_SIZE_CAPTION`.

## Field Text

| Token | Size | Weight |
|-------|------|--------|
| Standard | 14px | Regular |

## Button / Link Text

| Token | Size | Weight |
|-------|------|--------|
| Button Large | 16px | Medium |
| Button Medium | 14px | Medium |
| Button Small | 12px | Medium |

## Usage Patterns (from examples)

### Module pages
- Page title: Header 4 (24px Bold)
- Section headers: Header 7 (16px Bold) or Header 8 (16px Semibold)
- Body text: Body 2 (14px Regular)
- Labels/captions: Body 3 (12px Regular)

### Hero / marketing sections
- Headline: Header 2 (32px Bold) or Header 3 (28px Bold)
- Description: Body 1 (16px Regular)
- CTA buttons: primary filled (Sky) + secondary outlined (Sky)

### List items
- Item title: Header 9 (14px Bold)
- Item subtext: Body 2 (14px Regular)
