# ChiroTouch Design System — Iconography

Icons communicate actions, status, and navigation. The design system defines three icon sets.

## Icon Sets

### Essential Lined

The primary icon set — outlined/stroked icons used throughout the UI. This is the default set for most interface elements.

**Categories include:**
- **Navigation:** chevrons (down, left, right, up), arrows (up, down, left, right), expand
- **Actions:** check, plus, minus, close (X), edit (pencil), delete (trash), copy, external link, share
- **Status:** checkmark circle, info circle, warning triangle, error circle, question circle, clock
- **Communication:** phone, location pin, bell, person, email, printer, eye (visibility), audio/waveform
- **Content:** calendar, settings/gear, filter/sliders, sort, microphone, thumbs up
- **People:** person, people/group, user settings
- **Documents:** attachment/clip, file, copy, clipboard, bookmark, image, star
- **Media:** volume on, volume off, speaker, mute
- **UI:** hamburger menu, search (magnifying glass), lock, more dots (horizontal/vertical), barcode
- **Editing:** edit/pencil, compose, crop, layers

### Essentials Filled

Solid/filled versions of key icons — used for emphasis, active states, or status indicators.

**Includes:**
- Star (filled), pin (filled)
- Alert icons: error (filled circle !), info (filled circle i), question (filled circle ?), check (filled circle), warning (filled triangle)
- Media controls: record (filled circle), pause, play
- Close (filled X), clock (filled)

### Rheo Icons

Product-specific icons for the Rheo/AI features — colored icons using Sky/brand tones.

- Circular icons with Sky/teal backgrounds
- Used for AI Scribe, Rheo-specific features
- Colored (not monochrome) — the only icon set where color is part of the icon itself

## Usage Rules

1. **Default to Essential Lined** — use outlined icons for all standard UI
2. **Use Essentials Filled sparingly** — only for active states, status indicators, or when a filled icon provides necessary visual weight (e.g., filled star for "favorited")
3. **Rheo Icons are product-scoped** — only use for Rheo/AI Scribe features, not for general UI
4. **Monochrome by default** — Essential Lined and Filled icons inherit their color from the current text color or a semantic color. Don't colorize individual icons unless they're status indicators.
5. **Consistent sizing** — icons should match the text size they appear alongside (14px body text = 14-16px icon)

## neb-www Implementation

- All icons go through `neb-icon` with the `RENDERER_SVGS` registry in `packages/neb-styles/icons.js`
- **Do not** use inline SVG, external icon libraries (Lucide, Heroicons, Font Awesome, Material Icons), or icon fonts
- **Do not** import icons from CDNs or external packages
- Register new icons in the existing `RENDERER_SVGS` registry pattern
- If the icon you need isn't in the registry, check the design system catalog first — it may exist under a different name
- For filled variants, use the filled version from the registry (not a CSS hack on the lined version)
