# Incremental Typing: JSDoc → @ts-check → TypeScript

## JSDoc Type Syntax

TypeScript's checker understands JSDoc annotations in `.js` files. This is the lowest-friction way to add types — no file renames, no build changes.

### Basic patterns

```javascript
// @ts-check

/** @type {string} */
let name = "hello";

/** @type {number[]} */
const scores = [1, 2, 3];

/** @type {{ id: string; name: string }} */
const user = { id: "1", name: "Jane" };

/** @type {Map<string, number>} */
const cache = new Map();
```

### Function types

```javascript
/**
 * @param {string} id
 * @param {{ includeDeleted?: boolean }} [options]
 * @returns {Promise<User | null>}
 */
export async function findUser(id, options = {}) {
  // TypeScript checks this body against the declared types
}

/**
 * @param {string} message
 * @param {...unknown} args
 * @returns {void}
 */
function log(message, ...args) {
  console.log(message, ...args);
}
```

### Type definitions (reusable)

```javascript
/**
 * @typedef {Object} User
 * @property {string} id
 * @property {string} name
 * @property {string} email
 * @property {"admin" | "member" | "guest"} role
 */

/**
 * @typedef {Object} PaginatedResponse
 * @template T
 * @property {T[]} data
 * @property {number} total
 * @property {number} page
 */

/** @type {PaginatedResponse<User>} */
const response = await fetchUsers();
```

### Import types from other files

```javascript
/** @typedef {import("./types.js").User} User */
/** @typedef {import("./types.js").Config} Config */

/**
 * @param {User} user
 * @returns {string}
 */
function formatName(user) {
  return `${user.firstName} ${user.lastName}`;
}
```

### Generics

```javascript
/**
 * @template T
 * @param {T[]} items
 * @param {(item: T) => boolean} predicate
 * @returns {T | undefined}
 */
function find(items, predicate) {
  return items.find(predicate);
}
```

### Casting (when needed)

```javascript
const el = /** @type {HTMLInputElement} */ (document.getElementById("input"));
```

### Enum-like constants

```javascript
/** @enum {string} */
const Status = {
  Active: "active",
  Inactive: "inactive",
  Pending: "pending",
};
// Note: JSDoc @enum is NOT the same as TS enum. It's just a type annotation.
```

## @ts-check Workflow

### Per-file opt-in

Add `// @ts-check` to the first line. TypeScript immediately checks the file:

```javascript
// @ts-check

// This will now error: Type 'number' is not assignable to type 'string'
/** @type {string} */
const x = 42;
```

### Suppressing known issues temporarily

```javascript
// @ts-check

// @ts-expect-error — TODO: fix after migrating auth module
const token = getAuthToken();
```

Use `@ts-expect-error` (not `@ts-ignore`) — it errors when the suppression is no longer needed.

### Per-file opt-out (when checkJs is project-wide)

```javascript
// @ts-nocheck
// This file is not ready for type checking yet
```

## tsconfig for JS Type Checking

### Phase 1: Per-file checking

```jsonc
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": false,          // rely on @ts-check per file
    "noEmit": true,
    "strict": false,
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"]
}
```

### Phase 2: Project-wide checking

```jsonc
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": true,           // check all JS files
    "noEmit": true,
    "strict": false,           // still lenient
    "noImplicitAny": false,    // too noisy for initial rollout
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"]
}
```

## `.d.ts` Stubs for Untyped Dependencies

When a shared library has no types, create declaration stubs so consumers get basic type info.

### Minimal stub (unblock consumers)

```typescript
// types/untyped-lib.d.ts
declare module "untyped-lib" {
  export function setup(config: Record<string, unknown>): void;
  export function process(input: unknown): Promise<unknown>;
}
```

### Richer stub (when you know the API)

```typescript
// types/@neb/microservice.d.ts
declare module "@neb/microservice" {
  import type { Express, Request, Response, NextFunction } from "express";

  interface ServerConfig {
    port?: number;
    routes: string;
    models?: string;
  }

  export function setupServer(config: ServerConfig): Express;

  export function auth(req: Request, res: Response, next: NextFunction): void;

  export class InvalidParamsError extends Error {
    constructor(message: string);
    statusCode: 400;
  }

  export class NotFoundError extends Error {
    constructor(message: string);
    statusCode: 404;
  }

  // ... add exports as needed
}
```

Register the stubs in tsconfig:

```jsonc
{
  "compilerOptions": {
    "typeRoots": ["./types", "./node_modules/@types"]
  }
}
```

## Strict Mode Ratcheting

Don't enable `strict: true` on day one. Ratchet one flag at a time:

### Order of strictness flags

1. **`noImplicitAny`** — the highest-value flag. Forces explicit types on untyped parameters. Start here.
2. **`strictNullChecks`** — second-highest value. Catches `null`/`undefined` bugs. May surface many errors in code that doesn't guard optional values.
3. **`strictFunctionTypes`** — catches contravariance bugs in function parameters. Usually low noise.
4. **`strict: true`** — enables all remaining flags. Do this last.

### Per-flag workflow

1. Enable the flag in tsconfig
2. Run `tsc --noEmit` — collect all errors
3. Fix errors file by file (don't bulk-fix with `any`)
4. Commit when all errors are resolved
5. Enable next flag

### Tracking progress

```bash
# Count remaining type errors
tsc --noEmit 2>&1 | grep "error TS" | wc -l

# Count @ts-check coverage
grep -rl "@ts-check" src/ | wc -l
# vs total JS files
find src/ -name "*.js" | wc -l
```

## The .js → .ts Rename

### When to rename

A file is ready to rename when:
- It has `// @ts-check` and passes with zero errors
- All JSDoc types are complete and accurate
- Tests pass

### Per-file process

1. `git mv src/utils.js src/utils.ts`
2. Replace JSDoc with inline types:

```javascript
// Before (JSDoc in .js)
/**
 * @param {string} id
 * @returns {Promise<User | null>}
 */
export async function findUser(id) { ... }
```

```typescript
// After (inline in .ts)
export async function findUser(id: string): Promise<User | null> { ... }
```

3. Remove `// @ts-check` (unnecessary in `.ts`)
4. Remove `@typedef` imports — use `import type` instead
5. Run `tsc --noEmit` — must pass
6. Run tests — must pass
7. Commit

### Automated migration (for large files)

`ts-migrate` can automate the rename + basic type insertion:

```bash
npx ts-migrate-full <path>
```

It adds `any` types everywhere — useful for unblocking but creates tech debt. Prefer manual migration for critical code paths.
