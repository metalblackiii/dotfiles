# TypeScript Anti-Patterns: What AI Models Get Wrong

Top 10 AI TypeScript mistakes, ordered by frequency and impact. Each includes a before/after example and the reason models make this mistake.

## 1. `as` on External Data

**Why models do it:** Training data is full of `as User` casts. It looks type-safe but provides zero runtime safety.

```typescript
// BAD
async function getUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  const data = await res.json();
  return data as User; // no validation — trusts the server blindly
}

// GOOD — parse at the trust boundary
import { z } from "zod";

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(["admin", "member", "guest"]),
});
type User = z.infer<typeof UserSchema>;

async function getUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  const data: unknown = await res.json();
  return UserSchema.parse(data); // throws ZodError on invalid shape
}
```

**Rule:** Every `as` on data from `fetch`, `JSON.parse`, `fs.readFile`, environment variables, or query params is a bug waiting to happen. Parse it.

## 2. Annotation (`:`) Instead of `satisfies`

**Why models do it:** `:` is older and more common in training data. Models don't distinguish "widen to type" from "validate against type."

```typescript
// BAD — loses literal types
const config: Record<string, { url: string; timeout: number }> = {
  api: { url: "https://api.example.com", timeout: 5000 },
  auth: { url: "https://auth.example.com", timeout: 3000 },
};
// config.api is Record<string, ...> — no autocomplete on "api" | "auth"

// GOOD — validates AND preserves
const config = {
  api: { url: "https://api.example.com", timeout: 5000 },
  auth: { url: "https://auth.example.com", timeout: 3000 },
} satisfies Record<string, { url: string; timeout: number }>;
// config.api is { url: string; timeout: number } — full autocomplete

// BEST — literal types + validation
const config = {
  api: { url: "https://api.example.com", timeout: 5000 },
  auth: { url: "https://auth.example.com", timeout: 3000 },
} as const satisfies Record<string, { url: string; timeout: number }>;
// config.api.timeout is 5000, not number
```

## 3. Unguarded Indexed Access

**Why models do it:** Pre-`noUncheckedIndexedAccess` code didn't need guards. Models trained on older TS assume `arr[0]` returns `T`, not `T | undefined`.

```typescript
// BAD — crashes on empty array
function getFirstName(users: User[]): string {
  return users[0].name;
}

// GOOD — guard the access
function getFirstName(users: User[]): string | undefined {
  const first = users[0];
  return first?.name;
}

// BAD — record access without guard
function getConfig(key: string, configs: Record<string, Config>): Config {
  return configs[key]; // TS error: Type 'Config | undefined' is not assignable to 'Config'
}

// GOOD
function getConfig(key: string, configs: Record<string, Config>): Config | undefined {
  return configs[key];
}
```

## 4. `enum` Instead of `as const`

**Why models do it:** Enums are prominent in training data. Models don't know about `erasableSyntaxOnly` or Node type-stripping.

```typescript
// BAD — generates runtime code, incompatible with type stripping
enum HttpMethod {
  GET = "GET",
  POST = "POST",
  PUT = "PUT",
  DELETE = "DELETE",
}

// GOOD — zero runtime, works everywhere
const HttpMethod = {
  GET: "GET",
  POST: "POST",
  PUT: "PUT",
  DELETE: "DELETE",
} as const;
type HttpMethod = (typeof HttpMethod)[keyof typeof HttpMethod];

// Usage is identical
function request(method: HttpMethod, url: string) { /* ... */ }
request(HttpMethod.GET, "/api/users");
request("POST", "/api/users"); // also works — it's just a string union
```

## 5. `any` in Generic Constraints and Return Types

**Why models do it:** `any` is the "make it compile" escape hatch. Models reach for it when type inference gets complex.

```typescript
// BAD — any disables all type checking in the generic
function merge<T extends Record<string, any>>(a: T, b: Partial<T>): T {
  return { ...a, ...b };
}

// GOOD — unknown preserves type safety
function merge<T extends Record<string, unknown>>(a: T, b: Partial<T>): T {
  return { ...a, ...b };
}

// BAD — any return type
function parseConfig(raw: string): any {
  return JSON.parse(raw);
}

// GOOD — unknown forces callers to validate
function parseConfig(raw: string): unknown {
  return JSON.parse(raw);
}
```

**The `any` escape hatch:** If you genuinely need `any`, annotate with a safety comment:
```typescript
// SAFETY: Third-party library types are incorrect; filed issue #123
const result = badlyTypedLib.method() as any as CorrectType;
```

## 6. `namespace` Instead of ES Modules

**Why models do it:** Older TypeScript codebases used namespaces for code organization. Training data includes many examples.

```typescript
// BAD — non-erasable syntax, rejected by Node type stripping
namespace Validators {
  export function isEmail(value: string): boolean {
    return /^[^@]+@[^@]+\.[^@]+$/.test(value);
  }
  export function isUrl(value: string): boolean {
    return URL.canParse(value);
  }
}

// GOOD — standard ES modules
// validators.ts
export function isEmail(value: string): boolean {
  return /^[^@]+@[^@]+\.[^@]+$/.test(value);
}
export function isUrl(value: string): boolean {
  return URL.canParse(value);
}
```

## 7. Missing `import type`

**Why models do it:** Plain `import { Foo }` is shorter and works in many setups. Models don't consider `verbatimModuleSyntax`.

```typescript
// BAD — imports a type as a value; breaks under verbatimModuleSyntax
import { User, UserSchema } from "./user.js";

// GOOD — separate type and value imports
import type { User } from "./user.js";
import { UserSchema } from "./user.js";

// ALSO GOOD — inline type qualifier
import { type User, UserSchema } from "./user.js";
```

## 8. Missing `.js` Extensions in NodeNext

**Why models do it:** Bundlers don't require extensions. Models trained on bundled projects omit them.

```typescript
// BAD — fails at runtime under NodeNext ESM
import { helper } from "./utils";
import { db } from "./database";

// GOOD — explicit .js extension (even though source is .ts)
import { helper } from "./utils.js";
import { db } from "./database.js";

// For .tsx files
import { Button } from "./Button.js"; // not .jsx — TS resolves .js → .ts/.tsx
```

**Why `.js` and not `.ts`?** Node resolves imports at runtime against emitted `.js` files. TypeScript understands that `./foo.js` maps to `./foo.ts` at compile time. With `rewriteRelativeImportExtensions` (TS 5.7+), you can write `.ts` in source and have `tsc` emit `.js`.

## 9. Barrel Exports

**Why models do it:** Barrels look clean and are common in older tutorials. Models don't know about the performance impact.

```typescript
// BAD — src/index.ts barrel file
export * from "./users.js";
export * from "./posts.js";
export * from "./comments.js";
// Forces bundlers to load ALL modules even if only one is needed
// Creates circular dependency risks
// Slows down TypeScript checker

// GOOD — import directly from source
import { createUser } from "./users.js";
import { getPost } from "./posts.js";

// For libraries: use package.json "exports" for public API
// package.json
{
  "exports": {
    "./users": "./dist/users.js",
    "./posts": "./dist/posts.js"
  }
}
```

## 10. Legacy ESLint Configuration

**Why models do it:** `.eslintrc.json` dominated training data for years. Flat config only became default in ESLint 9 (2024).

```javascript
// BAD — .eslintrc.json (removed in ESLint 10)
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": "./tsconfig.json"
  }
}

// GOOD — eslint.config.js (flat config)
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true, // NOT project: "./tsconfig.json"
      },
    },
  },
);
```

**Key shift:** `projectService: true` replaces `project: "./tsconfig.json"`. It's faster, auto-discovers tsconfigs, and handles multi-root workspaces.

## Quick Reference

| # | Model does | Should do | Why |
|---|-----------|-----------|-----|
| 1 | `data as User` | `UserSchema.parse(data)` | `as` provides zero runtime safety |
| 2 | `const x: Type = {...}` | `{...} satisfies Type` | `:` widens; `satisfies` preserves literals |
| 3 | `arr[0].name` | `arr[0]?.name` | `noUncheckedIndexedAccess` makes index `T \| undefined` |
| 4 | `enum Status {}` | `as const` object + type | Enums blocked by `erasableSyntaxOnly` |
| 5 | `any` in generics | `unknown` or correct type | `any` disables checking in the generic |
| 6 | `namespace Foo {}` | ES module exports | Non-erasable; rejected by Node |
| 7 | `import { Foo }` (type) | `import type { Foo }` | Required by `verbatimModuleSyntax` |
| 8 | `from "./utils"` | `from "./utils.js"` | NodeNext ESM requires extensions |
| 9 | `export * from` | Direct imports | Barrels break tree-shaking |
| 10 | `.eslintrc.json` | `eslint.config.js` | Flat config is the only format from ESLint 10 |
