# TypeScript Tooling Ecosystem (March 2026)

## Linting & Formatting

| Tool | Version | Status | When to use |
|------|---------|--------|-------------|
| **Biome** | 2.4.8 | Stable (v2 Jun 2025) | Greenfield — one binary for lint+format, type-informed rules |
| **ESLint** | 9.x stable, 10.1 RC | Stable | Existing repos, need plugin breadth or custom rules |
| **typescript-eslint** | 8.57.2 | Stable (weekly) | Always pair with ESLint for TS projects |
| **Oxlint** | 1.56.0 | Stable (1.0 Jun 2025) | Speed-priority, complement to ESLint |
| **Oxlint type-aware** | alpha | Alpha (tsgolint) | Testing only — not production-ready |

### Decision guide

- **Greenfield:** Biome. One `biome.json`, no Prettier, no separate formatter.
- **Existing ESLint repo:** Migrate to flat config (`eslint.config.js`), use `typescript-eslint` presets. Only migrate to Biome if you can live within its curated rule surface.
- **Custom lint rules:** ESLint is the only option with a mature plugin API.

### Biome setup

```bash
npx @biomejs/biome init
```

```jsonc
// biome.json
{
  "linter": { "enabled": true },
  "formatter": { "enabled": true, "indentStyle": "space", "indentWidth": 2 }
}
```

### ESLint flat config setup

```bash
npm install -D eslint @eslint/js typescript-eslint
```

```javascript
// eslint.config.js
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  { languageOptions: { parserOptions: { projectService: true } } },
);
```

**Key shift:** Use `projectService: true`, not `project: "./tsconfig.json"`. Faster, auto-discovers tsconfigs, handles multi-root workspaces.

## Testing

| Tool | Version | Status | When to use |
|------|---------|--------|-------------|
| **Vitest** | 4.1.1 | Stable (v4 Oct 2025) | New projects, Vite-based apps, browser testing |
| **Jest** | 30.x | Stable | Existing large suites, non-Vite projects |

### Decision guide

- **New project:** Vitest. Zero-config with Vite, first-class browser testing, native ESM.
- **Existing Jest suite:** Stay on Jest 30 unless ESM friction is high. Migration path is smooth (`vitest` is API-compatible).
- **Browser tests in CI:** Vitest Browser Mode + Playwright provider.
- **Type tests:** Vitest has built-in `expectTypeOf` / `assertType` in `*.test-d.ts` files.

### Vitest setup

```bash
npm install -D vitest
```

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
  },
});
```

### Notable Vitest 4.1 features

- Test tags for selective execution
- `aroundAll`/`aroundEach` lifecycle hooks
- Async leak detection
- Inferred `test.extend` types

## Build & Run

| Tool | Version | Status | When to use |
|------|---------|--------|-------------|
| **Vite** | 8.0 | Stable (Mar 2026) | App bundler — uses Rolldown+Oxc by default |
| **tsx** | 4.21.0 | Stable | Dev runner for TS scripts, REPL |
| **tsdown** | 0.21.4 | Pre-1.0 | Library bundling (successor to tsup) |
| **Rolldown** | 1.0 RC | RC (ships in Vite 8) | Via Vite, not standalone yet |
| **tsup** | — | Unmaintained | README points to tsdown — do not start new projects |
| **esbuild** | — | Stable | Underlying Vite/tsx, rarely used directly |

### Decision guide

- **Dev runner:** `tsx` for full TS support. Node's built-in type stripping (24.3+) handles simple cases but ignores `tsconfig`, requires explicit extensions, and doesn't support `.tsx`.
- **Library bundler:** `tsdown`. Add `@arethetypeswrong/cli` to validate published types.
- **App bundler:** Vite (Rolldown+Oxc under the hood in v8).
- **Don't start new projects on tsup** — explicitly unmaintained.

### tsx usage

```bash
tsx src/index.ts         # Run a script
tsx watch src/server.ts  # Watch mode
tsx --interactive        # REPL
```

### tsdown setup

```bash
npm install -D tsdown
```

```typescript
// tsdown.config.ts
import { defineConfig } from "tsdown";

export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
});
```

**Migration from tsup:** `npx tsdown-migrate` automates the conversion.

## Type-Checking

| Tool | Answers | When to use |
|------|---------|-------------|
| **tsc** | "Is my code type-correct?" | Always — primary type checker |
| **tsgo** (TS 7 preview) | Same, ~10x faster | Testing only — not yet GA |
| **type-coverage** | "How much `any` debt?" | CI enforcement with `--at-least` threshold |
| **ATTW** | "Will consumers get correct types?" | Publishing libraries — validates across resolution modes |

### ATTW (Are The Types Wrong)

```bash
npx @arethetypeswrong/cli --pack .    # Check before publishing
npx @arethetypeswrong/cli some-package # Check a published package
```

### type-coverage

```bash
npx type-coverage --at-least 95 --strict
```

## TypeScript 7 (tsgo)

Go-native rewrite of the compiler. Key facts:

- **~10x faster `tsc --noEmit`**
- Extremely close to completion but not yet GA
- Not a breaking change for source code — TS 5.x/6.x code compiles under 7.0
- Deprecations from 6.0 become hard removals
- Oxlint type-aware linting wires to `tsgo` via `tsgolint`

**Action:** Avoid deprecated patterns now (no `moduleResolution: "node"`, no `enum`, no `baseUrl`). No other migration needed yet.

## Schema Validation

| Library | Bundle (tree-shaken) | Perf | Best for |
|---------|---------------------|------|----------|
| **Zod v4** | 12.1 KB | Good (14x faster than v3) | Default choice, broadest ecosystem |
| **Valibot 1.0** | 1.4 KB | Excellent | Bundle-critical (edge, client) |
| **ArkType 2.1** | 39.8 KB | Best raw perf | Performance-critical hot paths |

**Standard Schema 1.0** — all three implement a shared interface. tRPC, TanStack, ts-rest accept any Standard Schema library. Start with Zod, swap later without rewriting consumers.

## Node.js

| Version | Status | TS Support |
|---------|--------|------------|
| **Node 24** (Krypton) | Current LTS | Type stripping enabled by default, warning-free from 24.3 |
| **Node 22** | Maintenance LTS | Type stripping from 22.18 |
| **Node 25** | Current | Type stripping **stable** from 25.2 |

## Quick Reference: 2026 Defaults

| Category | Greenfield App | Greenfield Library | Existing Large Repo |
|----------|---------------|-------------------|-------------------|
| Lint + Format | Biome | Biome or ESLint flat | ESLint flat config |
| Test | Vitest | Vitest | Jest 30 (migrate when ready) |
| Build | Vite 8 (Rolldown) | tsdown | Keep current, evaluate tsdown |
| Dev runner | tsx | tsx | tsx |
| Type check | tsc | tsc + ATTW | tsc + type-coverage |
| Validation | Zod v4 | Zod v4 or Valibot | Zod v4 |
