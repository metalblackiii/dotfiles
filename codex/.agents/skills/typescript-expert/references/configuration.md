# TypeScript Configuration (2026)

## TS 6.0 Default Changes

TS 6.0 (March 2026) changed defaults significantly. New `tsc --init` output assumes:

| Option | Old default | TS 6.0 default |
|--------|------------|----------------|
| `strict` | `false` | **`true`** |
| `module` | `"commonjs"` | **`"esnext"`** |
| `target` | `"es5"` | **`"es2025"`** |
| `types` | all `@types/*` | **`[]`** (explicit only) |
| `esModuleInterop` | `false` | **`true`** (cannot be `false`) |

**Migration tool:** `npx @andrewbranch/ts5to6` — analyzes your tsconfig and suggests changes.

## TS 6.0 Deprecations

Deprecated in 6.0 (suppressible with `"ignoreDeprecations": "6.0"`), hard-removed in TS 7:

| Deprecated | Migration |
|---|---|
| `--target es5` | Minimum target is `es2015` |
| `--moduleResolution node` / `node10` | Use `nodenext` or `bundler` |
| `--moduleResolution classic` | Removed entirely |
| `--module amd`, `umd`, `systemjs`, `none` | Use a bundler |
| `--baseUrl` | Use `paths` with explicit roots |
| `--esModuleInterop false` | Cannot be `false` |
| `import ... assert { ... }` | Use `import ... with { ... }` |

**Already removed in 6.0** (no `ignoreDeprecations` escape hatch):

| Removed | Migration |
|---|---|
| `--outFile` | Use an external bundler (esbuild, Rolldown, tsdown) |

## Strict Mode

`strict: true` enables all strict sub-flags. In TS 6.0+ it's the default — you only need it explicitly for TS <6.0.

```jsonc
{
  "compilerOptions": {
    "strict": true,
    // strict: true enables:
    //   noImplicitAny, strictNullChecks, strictFunctionTypes,
    //   strictBindCallApply, strictPropertyInitialization,
    //   noImplicitThis, alwaysStrict, useUnknownInCatchVariables

    // Additional checks (NOT included in strict):
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

## Module Resolution Decision Tree

| Scenario | `module` | `moduleResolution` | Key flags |
|----------|----------|-------------------|-----------|
| **Node.js app** | `"NodeNext"` | `"NodeNext"` | `verbatimModuleSyntax`, `erasableSyntaxOnly`, explicit extensions (`.js` default; `.ts` with rewrite or Node type-stripping) |
| **Node.js, pinned** | `"Node18"` / `"Node20"` | (implied) | Stable semantics; `NodeNext` tracks latest Node |
| **Bundled app** | `"Preserve"` | `"bundler"` | `noEmit`, `allowImportingTsExtensions`, `verbatimModuleSyntax` |
| **Library** | `"NodeNext"` | `"NodeNext"` | Strictest = most portable. Validate with ATTW before publishing |

**Banned:** `"Classic"`, `"node"` / `"node10"` — deprecated in TS 6.0, removed in TS 7.

### Node.js app / library

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
    // jsx: "react-jsx" for React projects
  }
}
```

## Node Type-Stripping Workflow

Node can run `.ts` files directly via built-in type stripping (stable from Node 25.2, warning-free from 24.3/22.18). It only erases type annotations — no enums, no namespaces, no parameter properties.

```jsonc
// tsconfig.json for Node type-stripping compatibility
{
  "compilerOptions": {
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "rewriteRelativeImportExtensions": true,
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2024"
  }
}
```

**What `erasableSyntaxOnly` bans:**
- `enum` → use `as const` objects
- `namespace` (non-`declare`) → use ES modules
- Parameter properties (`constructor(public x: number)`) → explicit assignment
- `import =` / `export =` → standard ESM syntax

**`rewriteRelativeImportExtensions`** (TS 5.7+): Write `import "./foo.ts"` in source; `tsc` emits `import "./foo.js"`. Bridges author-time and runtime resolution.

**Dev runner:** `tsx` remains the better choice for development — handles `.tsx`, respects `tsconfig`, supports watch mode. Node's built-in stripping is best for production where no tooling dependency is preferred.

## ESLint Flat Config

Flat config (`eslint.config.js`) is the only format from ESLint 10+. Key changes from legacy:

```bash
npm install -D eslint @eslint/js typescript-eslint
```

```javascript
// eslint.config.js
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true, // auto-discovers tsconfigs
      },
    },
  },
  {
    // Disable type-checked rules for config files
    files: ["*.config.{js,ts,mjs}"],
    ...tseslint.configs.disableTypeChecked,
  },
);
```

**`projectService` vs `project`:** Always use `projectService: true`. It replaces `project: "./tsconfig.json"` — faster, auto-discovers tsconfigs, handles multi-root workspaces. Never use `project` globs.

### Adding strict rules

```javascript
export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,    // stricter than recommended
  tseslint.configs.stylisticTypeChecked, // style consistency
  { languageOptions: { parserOptions: { projectService: true } } },
);
```

## Project References

For monorepos with shared packages:

```jsonc
// Root tsconfig.json
{
  "files": [],
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/frontend" },
    { "path": "./packages/backend" }
  ]
}

// packages/shared/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true
  },
  "include": ["src/**/*"]
}

// packages/frontend/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "references": [{ "path": "../shared" }],
  "include": ["src/**/*"]
}
```

## Isolated Declarations (TS 5.5+)

Enables external tools (tsdown, Oxc) to generate `.d.ts` files without the full type checker — each file's declarations are self-contained.

```jsonc
{
  "compilerOptions": {
    "declaration": true,
    "isolatedDeclarations": true
  }
}
```

**Requires:** all exported functions/classes must have explicit return types. The compiler errors on implicit types that cross file boundaries.

**When to adopt:** library authors using tsdown/Oxc for declaration emit, monorepos where parallel declaration generation matters. Skip for application code that doesn't publish types.

## Incremental Compilation

Only use `incremental` in configs that **emit output** (`outDir` set, no `noEmit`). Don't add it to a base tsconfig extended by build configs.

```jsonc
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo"
  }
}
```

## Build vs Typecheck Configs

Use a build-specific tsconfig to exclude test files from output while keeping full type coverage during development:

```jsonc
// tsconfig.json (base — typecheck, IDE, test runner)
{
  "compilerOptions": { /* ... full options ... */ },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}

// tsconfig.build.json (emit — excludes tests)
{
  "extends": "./tsconfig.json",
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "src/**/*.test.ts", "src/**/*.spec.ts"]
}
```

**Important:** Always include an explicit `include` in the build config. When only `exclude` is specified in a child config, `tsc` may silently produce no output.

## Quick Reference

| Option | Purpose | Since |
|--------|---------|-------|
| `strict` | All strict checks (default in TS 6.0) | 2.3 |
| `verbatimModuleSyntax` | Explicit `import type` / `export type` | 5.0 |
| `erasableSyntaxOnly` | Ban non-erasable syntax for type stripping | 5.8 |
| `isolatedModules` | Each file transpilable independently | 2.0 |
| `noUncheckedIndexedAccess` | Index returns `T \| undefined` | 4.1 |
| `exactOptionalPropertyTypes` | Distinguish `undefined` from missing | 4.4 |
| `noUncheckedSideEffectImports` | Catch typos in side-effect imports | 5.6 |
| `rewriteRelativeImportExtensions` | `.ts` → `.js` in emitted imports | 5.7 |
| `isolatedDeclarations` | Parallel `.d.ts` emit | 5.5 |
| `moduleDetection: "force"` | Treat all files as modules | 4.7 |
| `skipLibCheck` | Skip `.d.ts` checking | 2.0 |
