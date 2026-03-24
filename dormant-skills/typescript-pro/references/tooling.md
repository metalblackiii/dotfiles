# TypeScript Tooling Ecosystem (2026)

## Linting & Formatting

| Tool | Use When | Key Trait |
|------|----------|-----------|
| **Biome** | Greenfield projects, want one binary for lint + format | Fastest, zero-config, type-informed rules via `.d.ts` scanning (v2+) |
| **ESLint flat config** | Existing repos, need plugin breadth or custom rules | Ecosystem depth, `typescript-eslint` ships `strictTypeChecked` preset |
| **Oxlint + Oxfmt** | Betting on the Rust/Oxc stack, want bleeding-edge speed | Part of the Oxc compiler stack, type-aware linting via `tsgo` (TS 7+) |

### Decision guide

- **Greenfield:** default to Biome. One `biome.json`, no Prettier, no separate formatter config.
- **Existing ESLint repo:** migrate to flat config (`eslint.config.js`), use `typescript-eslint` presets. Only migrate to Biome if you can live within its curated rule surface.
- **Need custom lint rules:** ESLint is still the only option with a mature plugin API.

### Biome setup

```bash
npx @biomejs/biome init
```

```jsonc
// biome.json — minimal TS config
{
  "linter": { "enabled": true },
  "formatter": { "enabled": true, "indentStyle": "space", "indentWidth": 2 }
}
```

### ESLint flat config setup

```bash
npm install -D eslint @eslint/js typescript-eslint
```

```js
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

## Testing

| Tool | Use When | Key Trait |
|------|----------|-----------|
| **Vitest** | New projects, Vite-based apps, browser testing | Jest-compatible API, stable Browser Mode (v4), native ESM |
| **Jest 30** | Large incumbent suites, non-Vite projects | Improved TS/ESM in v30, but ESM still marked experimental |

### Decision guide

- **New project:** Vitest. Zero-config with Vite, first-class browser testing with Playwright provider.
- **Existing Jest suite:** stay on Jest 30 unless ESM friction is high. Migration path is smooth when ready (`vitest` is API-compatible).
- **Browser tests in CI:** Vitest Browser Mode + Playwright provider.

### Vitest setup

```bash
npm install -D vitest
```

```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true, // jest-like global API
  },
});
```

## Build & Run

| Tool | Use When | Status |
|------|----------|--------|
| **esbuild** | Fast bundling primitive, underlying Vite/tsx | Stable foundation, not going anywhere |
| **tsx** | Dev scripts, REPL, running `.ts` files in Node | Drop-in `node` replacement with full TS support |
| **tsdown** | Library bundling (successor to tsup) | Powered by Rolldown + Oxc, smooth tsup migration |
| **tsup** | Legacy — migrate to tsdown | Unmaintained, README points to tsdown |
| **Rolldown** | Vite's next bundler, replaces Rollup | Rust-based, powers tsdown and Vite |
| **Oxc** | Full compiler stack: parser, linter, formatter, minifier | Rising Rust-based toolchain, used by Rolldown |

### Decision guide

- **Dev runner:** `tsx` for full TypeScript support. Node's built-in type stripping (22.6+) handles simple cases but ignores `tsconfig`, requires explicit extensions, and doesn't support `.tsx`.
- **Library bundler:** `tsdown`. Add `@arethetypeswrong/cli` to validate published types.
- **App bundler:** Vite (uses esbuild/Rolldown under the hood).
- **Don't start new projects on tsup** — it is explicitly unmaintained.

### tsx usage

```bash
# Run a script
tsx src/index.ts

# Watch mode
tsx watch src/server.ts

# REPL
tsx --interactive
```

### tsdown setup

```bash
npm install -D tsdown
```

```ts
// tsdown.config.ts
import { defineConfig } from "tsdown";

export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
});
```

## Type-Checking Adjuncts

| Tool | Answers | Use When |
|------|---------|----------|
| **tsc / tsgo** | "Is my code type-correct?" | Always — primary type checker |
| **type-coverage** | "How much `any` debt do I have?" | CI enforcement with `--at-least` threshold |
| **ATTW** (`@arethetypeswrong/cli`) | "Will consumers get correct types?" | Publishing libraries — validates across resolution modes |

### type-coverage setup

```bash
npx type-coverage --at-least 95 --strict
```

### ATTW setup

```bash
# Check current package before publishing
npx @arethetypeswrong/cli --pack .

# Check a published package
npx @arethetypeswrong/cli some-package
```

## TypeScript 7 (Native Compiler)

TypeScript 7 is a Go-based rewrite of the compiler (`tsgo`), shipping as the successor to the JS-based `tsc`. Key implications:

- **~10x faster `tsc --noEmit`** — build pipelines get significantly faster
- **Oxc type-aware linting** already wires to `tsgo` via `tsgolint`
- **Deprecations:** old `node`/`node10` resolution is deprecated in favor of `node16`, `nodenext`, `bundler`
- **Not a breaking change for source code** — existing TS 5.x code compiles under 7.0

No action required yet, but avoid `moduleResolution: "node"` in new projects — it's on the deprecation path.

## Quick Reference: 2026 Defaults

| Category | Greenfield App | Greenfield Library | Existing Large Repo |
|----------|---------------|-------------------|-------------------|
| Lint + Format | Biome | Biome or ESLint flat | ESLint flat config |
| Test | Vitest | Vitest | Jest 30 (migrate when ready) |
| Build | Vite (esbuild/Rolldown) | tsdown | Keep current, evaluate tsdown |
| Dev runner | tsx | tsx | tsx |
| Type check | tsc | tsc + ATTW | tsc + type-coverage |
