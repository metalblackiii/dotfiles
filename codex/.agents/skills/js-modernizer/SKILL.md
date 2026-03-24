---
name: js-modernizer
description: ALWAYS invoke when modernizing JavaScript code, migrating from CJS to ESM, removing Babel, adding TypeScript to a JavaScript project, or converting .js files to .ts
---

# JS Modernizer

Phased methodology for migrating legacy JavaScript to modern TypeScript. Enforces a strict pipeline — no skipping phases, no bulk rewrites, no behavior changes mixed with type additions.

## Iron Rules

1. **Never skip phases** — the pipeline is Legacy JS → Modern JS → Typed JS → TypeScript. Each phase is independently committable and testable.
2. **One file at a time** — never bulk-rename `.js` → `.ts`. Migrate one module, verify tests, commit.
3. **Tests pass between every change** — if tests break, fix before proceeding. No "we'll fix it later."
4. **Semantic preservation** — modernization must NOT change runtime behavior. Refactoring and type-adding are separate commits.
5. **Leaf nodes first** — migrate files with zero dependents before files with many. Work inward from the dependency graph edges.
6. **Type the framework first** — if the base library/framework is untyped, downstream types are meaningless. Ship `.d.ts` stubs for shared packages before migrating consumers.
7. **Babel removal before tsc** — don't run two transpilers simultaneously. Remove Babel first, verify everything works, then introduce `tsc`.
8. **JSDoc before rename** — add type annotations in `.js` files (via JSDoc + `@ts-check`) before renaming to `.ts`. This catches type errors while the file is still JS.
9. **`@ts-check` before `checkJs`** — opt in per file with `// @ts-check` before enabling `checkJs` project-wide. Discover the blast radius incrementally.
10. **Don't modernize and migrate simultaneously** — a commit that removes `var` and adds TypeScript types is doing two things. Separate them.

## Assessment Checklist

Before starting, answer these questions to determine the current phase:

```
1. Module system?
   □ CJS source (require/module.exports)     → Start at Phase 0
   □ ESM source compiled by Babel to CJS     → Start at Phase 0 (Babel removal)
   □ Native ESM ("type": "module")           → Skip to Phase 1
   □ Already TypeScript                      → Use typescript-expert instead

2. ES version?
   □ Has var, callbacks, prototype patterns  → Phase 0 includes syntax modernization
   □ Modern (const/let, async/await, arrow)  → Syntax is ready

3. Types?
   □ No JSDoc, no @ts-check, no tsconfig    → Start at Phase 1
   □ JSDoc types on some files               → Continue Phase 1
   □ @ts-check + allowJs/checkJs working     → Start at Phase 2
   □ Some .ts files already                  → Continue Phase 2

4. Dependencies?
   □ Deprecated packages (request, moment)   → Address in Phase 0 or parallel track
   □ Untyped shared libraries                → Ship .d.ts stubs first (Phase 1)
   □ Dynamic require() / require-all         → Must resolve before native ESM
```

## Phase 0: Modern JS (no types yet)

**Goal:** Clean, native ESM JavaScript that can run without a transpiler.

### Babel removal (the most common blocker)

If the project uses ESM syntax compiled through Babel to CJS:

1. Add `"type": "module"` to `package.json`
2. Remove `@babel/register` from dev startup (`node -r @babel/register` → `node`)
3. Remove `@babel/cli` from build (`babel src -d dist` → direct execution or `tsc` later)
4. Remove `@babel/preset-env`, `.babelrc` / `babel.config.js`
5. Fix CJS holdouts — see `references/esm-migration.md` for `__dirname`, `require()`, and dynamic import patterns
6. Update test runner config (Mocha/Jest may need `--experimental-vm-modules` or loader flags)
7. Verify: `node src/index.js` runs without Babel

### Syntax modernization (if needed)

- `var` → `const`/`let` (prefer `const`)
- Callbacks → `async`/`await`
- `Function.prototype.bind(this)` → arrow functions
- `arguments` → rest parameters
- `require('dotenv').config()` → `import 'dotenv/config'`
- String concatenation → template literals

### Deprecated dependency replacement (parallel track)

These can happen alongside or after Babel removal:

| Old | New | Notes |
|-----|-----|-------|
| `request` / `request-promise` | `undici` or native `fetch` | Node 18+ has global `fetch` |
| `moment` / `moment-timezone` | `date-fns` or `Temporal` | High-effort if pervasive |
| `node-fetch` | Native `fetch` | Node 18+ |
| `require-all` | Explicit imports or `import()` glob | See ESM migration reference |

## Phase 1: Typed JS (JSDoc + @ts-check)

**Goal:** Type coverage without renaming any files. TypeScript checks `.js` files.

### Step 1: Add tsconfig.json

```jsonc
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": false,         // start with per-file @ts-check, not project-wide
    "noEmit": true,           // don't generate output — just type-check
    "strict": false,          // start lenient, ratchet later
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"]
}
```

### Step 2: Add `@ts-check` to files, one at a time

```javascript
// @ts-check

/** @param {string} id */
/** @returns {Promise<User | null>} */
export async function findUser(id) {
  // ...
}
```

Start with leaf nodes (utilities, constants, types). Run `tsc --noEmit` after each file.

### Step 3: Create `.d.ts` stubs for untyped dependencies

```typescript
// types/untyped-lib.d.ts
declare module "untyped-lib" {
  export function doThing(input: string): Promise<unknown>;
}
```

### Step 4: Enable `checkJs` project-wide

Once most files have `@ts-check` and pass, flip `checkJs: true` in tsconfig. Files that aren't ready can opt out with `// @ts-nocheck`.

### Step 5: Ratchet strictness

Enable strict flags one at a time, fixing violations between each:
1. `noImplicitAny: true`
2. `strictNullChecks: true`
3. `strict: true` (enables all remaining strict flags)

## Phase 2: TypeScript (rename .js → .ts)

**Goal:** Full TypeScript with inline types replacing JSDoc.

### Migration order

1. Type definition files first (constants, enums-as-const, shared types)
2. Leaf utilities (no imports from other project files)
3. Data layer (models, repositories)
4. Business logic (services)
5. Entry points (routes, handlers, main)

### Per-file process

1. Rename `foo.js` → `foo.ts`
2. Replace JSDoc annotations with inline TypeScript types
3. Fix any new type errors surfaced by the rename
4. Run `tsc --noEmit` — must pass
5. Run tests — must pass
6. Commit

### Replace Babel build with tsc

Once enough files are `.ts`, replace the Babel build pipeline:

```jsonc
// tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noEmit": false,
    "outDir": "./dist",
    "declaration": true,
    "sourceMap": true
  },
  "exclude": ["**/*.test.ts", "**/*.spec.ts"]
}
```

At this point, `typescript-expert` skill takes over for ongoing TS development.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| ESM Migration | `references/esm-migration.md` | Babel removal, CJS→ESM gotchas, `__dirname`, dynamic imports |
| Incremental Typing | `references/incremental-typing.md` | JSDoc patterns, `@ts-check` workflow, strict ratcheting, `.d.ts` stubs |
| Neb Patterns | `references/neb-patterns.md` | Sequelize `db.Model`, `@neb/microservice`, Lit components, Mocha→Vitest |

## Constraints

### MUST DO
- Assess current phase before starting any work
- Commit after each file migration (not in bulk)
- Run tests between every change
- Remove Babel before introducing tsc
- Add JSDoc types before renaming to .ts
- Type shared libraries/frameworks before consumers
- Preserve runtime behavior — refactoring and typing are separate commits

### MUST NOT DO
- Bulk-rename `.js` → `.ts` across the project
- Add `strict: true` on day one — ratchet incrementally
- Mix syntax modernization with type additions in one commit
- Skip the JSDoc/`@ts-check` phase (it catches errors cheaply)
- Introduce `tsc` while Babel is still the build pipeline
- Change runtime behavior while "modernizing" (e.g., changing error handling, removing fallbacks)
- Use `any` to silence errors during migration — use `unknown` and narrow

## Knowledge Reference

CJS/ESM interop, `"type": "module"`, Babel removal patterns, JSDoc type syntax (`@param`, `@returns`, `@typedef`, `@template`, `@ts-check`), `allowJs`/`checkJs`, strict flag ratcheting, `.d.ts` stub authoring, `ts-migrate` (automated codemod), `@arethetypeswrong/cli` (library validation). Pairs with `typescript-expert` for Phase 2+ ongoing development.
