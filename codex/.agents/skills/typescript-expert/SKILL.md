---
name: typescript-expert
description: ALWAYS invoke when writing, reviewing, or modifying TypeScript code
---

# TypeScript Expert

Anti-hallucination skill for modern TypeScript (TS 5.8–6.0, March 2026). Focuses on what models get wrong and what's changed since training — not what Claude already knows.

## Iron Rules

1. **No `enum`** — use `as const` objects. Enums generate runtime JS; blocked by `erasableSyntaxOnly`.
2. **No `any` on contracts** — use `unknown`. AI agents are 9x more prone to use `any` than humans.
3. **No `as` on external data** — use schema validation (Zod, Valibot). `as` is a lie with zero runtime safety.
4. **No `namespace`** — use ES modules. Non-`declare` namespaces are non-erasable syntax, incompatible with `erasableSyntaxOnly` and Node type-stripping.
5. **No barrel exports** — import directly from source files. Barrels break tree-shaking and create circular deps.
6. **Use `import type`** for type-only imports. Required by `verbatimModuleSyntax`.
7. **Use `satisfies` not `as`** for shape validation. `satisfies` preserves literal types; `as` widens.
8. **Guard indexed access** — `noUncheckedIndexedAccess` adds `| undefined`. Always check before accessing.
9. **Use explicit extensions** in NodeNext imports — `.js` is the safe default. `.ts` imports work when using `rewriteRelativeImportExtensions` (TS 5.7+) or Node's built-in type stripping. Extensionless imports are always wrong.
10. **Check diagnostics after every edit** — LSP/`tsc` catches hallucinated APIs and impossible types immediately.

## Top 5 Anti-Patterns

### 1. `as` on API responses (the most dangerous)

```typescript
// BAD — compiles, crashes at runtime
const user = response.data as User;
user.name.toUpperCase(); // runtime: Cannot read property of undefined

// GOOD — fails fast with a structured error
import { z } from "zod";
const UserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
});
const user = UserSchema.parse(response.data);
```

### 2. Annotation (`:`) where `satisfies` is needed

```typescript
// BAD — widens to Record<string, string>, loses literal keys
const routes: Record<string, string> = {
  home: "/",
  about: "/about",
};
// typeof routes = Record<string, string> — keyof is just string

// GOOD — validates shape AND preserves literal types
const routes = {
  home: "/",
  about: "/about",
} satisfies Record<string, string>;
// typeof routes = { home: "/"; about: "/about" }
// keyof typeof routes = "home" | "about"
```

### 3. Unguarded array/object indexing

```typescript
// BAD — assumes element exists (undefined at runtime)
const first = items[0];
console.log(first.name); // runtime error if items is empty

// GOOD — guard the access
const first = items[0];
if (first) {
  console.log(first.name);
}

// GOOD — for maps/records
const value = record[key];
if (value !== undefined) {
  process(value);
}
```

### 4. `enum` instead of `as const`

```typescript
// BAD — generates runtime JS, blocked by erasableSyntaxOnly
enum Status { Active = "active", Inactive = "inactive" }

// GOOD — zero runtime cost, works with type stripping
const Status = { Active: "active", Inactive: "inactive" } as const;
type Status = (typeof Status)[keyof typeof Status]; // "active" | "inactive"
```

### 5. Legacy ESLint config

```javascript
// BAD — .eslintrc.json (removed in ESLint 10)
{ "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"] }

// GOOD — eslint.config.js with imported presets
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  { languageOptions: { parserOptions: { projectService: true } } },
);
```

## `as` vs `satisfies` vs `:` Decision Guide

| Operator | Effect | Use when |
|----------|--------|----------|
| `: Type` | Annotation — widens to declared type | Function params, return types, intentional widening |
| `satisfies Type` | Validates shape, preserves literal type | Config objects, route maps, constants |
| `as Type` | Assertion — "trust me" | Branded types (`id as UserId`), post-validation narrowing, DOM elements after null check |
| `as const` | Narrowest literal type | Enum-like objects, tuples, values that should never widen |
| `as const satisfies T` | Literal type + shape validation | The gold standard for typed constants |

**Default choice:** `satisfies`. Reach for `as` only after validation or for branded types.

## Module Resolution Decision Tree

Pick based on where your code **runs**:

```
Where does the code run?
├── Node.js (server, CLI, scripts)
│   ├── module: "NodeNext"
│   ├── moduleResolution: "NodeNext"
│   └── Explicit extensions: .js (default) or .ts (with rewrite or Node type-stripping)
├── Bundler (Vite, webpack, Next.js, esbuild)
│   ├── module: "Preserve"
│   ├── moduleResolution: "bundler"
│   └── noEmit: true, allowImportingTsExtensions: true
└── Library (consumed by both Node + bundlers)
    ├── module: "NodeNext"  (strictest = most portable)
    ├── moduleResolution: "NodeNext"
    └── Validate with: npx @arethetypeswrong/cli --pack .
```

**Banned:** `"node"` / `"node10"` / `"classic"` — deprecated in TS 6.0, hard-removed in TS 7.

## tsconfig Baselines (TS 6.0)

TS 6.0 changed defaults: `strict: true`, `module: "esnext"`, `target: "es2025"`, `types: []`, `esModuleInterop: true` (cannot be false). Many flags you used to set explicitly are now defaults.

### Node app / library

```jsonc
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "moduleDetection": "force",
    "verbatimModuleSyntax": true,
    "erasableSyntaxOnly": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedSideEffectImports": true,
    "isolatedModules": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "skipLibCheck": true
    // strict: true is the TS 6.0 default — explicit only if targeting <6.0
  }
}
```

### Bundled app (Vite, Next.js, webpack)

```jsonc
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "Preserve",
    "moduleResolution": "bundler",
    "lib": ["ES2024", "DOM", "DOM.Iterable"],
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "isolatedModules": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "skipLibCheck": true
    // jsx: "react-jsx" — add for React projects
  }
}
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Anti-Patterns | `references/anti-patterns.md` | Full top-10 with detailed before/after code |
| Configuration | `references/configuration.md` | tsconfig deep dive, TS 6.0 migration, ESLint flat config, project refs |
| Tooling | `references/tooling.md` | 2026 ecosystem decisions — lint, test, build, run, type-check |
| Patterns | `references/patterns.md` | Schema validation (Zod v4, Valibot, Standard Schema), error handling, modules |

## Constraints

### MUST DO
- Validate external data with a Standard Schema-compatible library at trust boundaries
- Use `import type` for type-only imports
- Use `satisfies` for config/constant validation
- Guard every indexed access (`arr[i]`, `obj[key]`)
- Use flat config (`eslint.config.js`) for ESLint — never `.eslintrc`
- Use `projectService` for typed ESLint rules — never `project` globs
- Default to `type` over `interface` (avoids declaration merging footgun)
- Use `as const` objects instead of `enum`
- Check diagnostics (LSP or `tsc --noEmit`) after structural changes

### MUST NOT DO
- Use `as` to cast external/unvalidated data
- Use `any` without `// SAFETY:` comment justifying why
- Use `enum`, `namespace`, or `experimentalDecorators`
- Use barrel files (`export * from`)
- Generate `.eslintrc` or legacy ESLint config
- Use `moduleResolution: "node"` or `"classic"`
- Use `@ts-ignore` — use `@ts-expect-error` with explanation
- Use extensionless imports in NodeNext (use `.js` or `.ts` with `rewriteRelativeImportExtensions`)
- Suggest `baseUrl` (deprecated in TS 6.0) or `outFile` (removed in TS 6.0)

## Knowledge Reference

TypeScript 5.8–6.0 (baselines target 6.0). TS 6.0 defaults: strict, esnext module, es2025 target. TS 7 (tsgo) preview: Go-native ~10x faster, not yet GA. Node 24 LTS with built-in type stripping. Zod v4 + Standard Schema 1.0. Biome 2.x, ESLint 9/10, Vitest 4.x, tsx 4.x, tsdown 0.21.x. `satisfies` (4.9+), `const` type params (5.0+), `verbatimModuleSyntax` (5.0+), `NoInfer` (5.4+), `erasableSyntaxOnly` (5.8+), `import defer` (5.9+).
