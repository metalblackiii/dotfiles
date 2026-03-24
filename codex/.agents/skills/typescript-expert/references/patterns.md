# TypeScript Patterns (2026)

## Schema Validation: Parse, Don't Validate

Instead of `as` assertions or manual checks, define a schema that parses input into a validated type — or fails with a structured error. Parse at every trust boundary.

### Zod v4 (default choice)

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(["admin", "member", "guest"]),
});

type User = z.infer<typeof UserSchema>;

// Parse at system boundaries
function handleRequest(body: unknown): User {
  return UserSchema.parse(body); // throws ZodError on invalid input
}

// Safe parse for explicit error handling
function tryParseUser(body: unknown) {
  const result = UserSchema.safeParse(body);
  if (!result.success) {
    return { ok: false as const, error: result.error.flatten() };
  }
  return { ok: true as const, user: result.data };
}
```

**Zod v4 changes from v3:** 14x faster parsing, smaller bundle (12.1 KB), metadata/registries, JSON Schema output, Zod Mini (even smaller), Zod Core (build-your-own). API is largely compatible — `safeParse` result shape is the same.

### Valibot (bundle-critical)

```typescript
import * as v from "valibot";

const UserSchema = v.object({
  id: v.pipe(v.string(), v.uuid()),
  name: v.pipe(v.string(), v.minLength(1)),
  email: v.pipe(v.string(), v.email()),
  role: v.picklist(["admin", "member", "guest"]),
});

type User = v.InferOutput<typeof UserSchema>;
```

**When Valibot over Zod:** client-side validation where 1.4 KB matters (vs 12.1 KB), edge functions, or any context where bundle size is a constraint.

### Standard Schema 1.0

All three major validators (Zod, Valibot, ArkType) implement Standard Schema — a shared ~60-line interface. Libraries like tRPC, TanStack Form, and ts-rest accept any Standard Schema library.

```typescript
// Framework code accepts any Standard Schema validator
import type { StandardSchemaV1 } from "@standard-schema/spec";

function validate<T>(schema: StandardSchemaV1<T>, data: unknown): T {
  const result = schema["~standard"].validate(data);
  if (result.issues) {
    throw new ValidationError(result.issues);
  }
  return result.value;
}
```

**Guidance:** Use Zod by default (broadest ecosystem, most docs). Swap to Valibot for bundle-critical contexts. The Standard Schema interface means consumers don't need to change.

### Where to parse

| Trust boundary | Parse with |
|---------------|------------|
| API request body | Schema at handler entry |
| API response (fetch) | Schema after `res.json()` |
| Environment variables | Schema at app startup |
| Config files | Schema at load time |
| URL params / query | Schema in route handler |
| Form data | Schema on submit |
| Database results | Schema if using raw queries (ORM handles this) |

## Error Handling

### Hierarchy (pick one per project)

| Approach | Library | Best for |
|----------|---------|----------|
| `try/catch` | Built-in | Most projects. Enable `useUnknownInCatchVariables`. |
| Result types | `neverthrow` | Functions where callers must handle failure explicitly |
| Full typed effects | `Effect-TS` | System-wide typed error propagation, retry, logging |

**`fp-ts` is deprecated.** Its README points to Effect-TS as the successor.

### try/catch (mainstream)

```typescript
// Custom error classes for typed catch
class NotFoundError extends Error {
  readonly code = "NOT_FOUND" as const;
  constructor(resource: string, id: string) {
    super(`${resource} ${id} not found`);
    this.name = "NotFoundError";
  }
}

class ValidationError extends Error {
  readonly code = "VALIDATION" as const;
  constructor(
    message: string,
    readonly fields: Record<string, string[]>,
  ) {
    super(message);
    this.name = "ValidationError";
  }
}

// Discriminate in catch
try {
  await updateUser(id, data);
} catch (error) {
  if (error instanceof NotFoundError) {
    return res.status(404).json({ code: error.code });
  }
  if (error instanceof ValidationError) {
    return res.status(400).json({ code: error.code, fields: error.fields });
  }
  throw error; // re-throw unknown errors
}
```

### neverthrow (typed results)

```typescript
import { ok, err, Result, ResultAsync } from "neverthrow";

type AppError = NotFoundError | ValidationError;

function findUser(id: string): ResultAsync<User, AppError> {
  return ResultAsync.fromPromise(
    db.users.findUnique({ where: { id } }),
    () => new NotFoundError("User", id),
  );
}

// Callers must handle both paths
const result = await findUser("123");
result.match(
  (user) => res.json(user),
  (error) => res.status(error instanceof NotFoundError ? 404 : 400).json({ code: error.code }),
);
```

### When to choose neverthrow

- Functions where ignoring the error path is a bug (payment processing, state transitions)
- Library APIs where callers need typed error variants
- When you want `Result` without adopting a full runtime (Effect)

### Effect-TS (comprehensive)

Only adopt if the team is committed to the Effect ecosystem. It's powerful (typed errors, retry, logging, dependency injection, concurrency) but has a steep learning curve and changes how you structure entire applications.

## Module Patterns

### No barrel files

```typescript
// BAD — src/index.ts
export * from "./users.js";
export * from "./posts.js";
export * from "./comments.js";

// GOOD — import directly
import { createUser } from "./users/create.js";
import { getPost } from "./posts/get.js";
```

For libraries, use `package.json` `exports` instead:

```json
{
  "exports": {
    ".": "./dist/index.js",
    "./users": "./dist/users.js",
    "./posts": "./dist/posts.js"
  }
}
```

### `type` vs `interface`

**Default to `type`.** Avoids the declaration merging footgun (`interface` is always open for extension; `type` is closed).

```typescript
// Preferred — closed, predictable
type User = {
  id: string;
  name: string;
  email: string;
};

// Use interface only for deep inheritance chains (rare)
interface Repository<T> {
  find(id: string): Promise<T | undefined>;
  save(entity: T): Promise<void>;
}

interface UserRepository extends Repository<User> {
  findByEmail(email: string): Promise<User | undefined>;
}
```

Switch to `interface extends` when TS performance wiki indicates intersection types are slowing compilation (large unions, deep compositions). This is rare in application code.

### Import organization

```typescript
// 1. Node builtins
import { readFile } from "node:fs/promises";
import { join } from "node:path";

// 2. External packages
import { z } from "zod";
import express from "express";

// 3. Internal absolute imports
import { db } from "#db/client.js";

// 4. Relative imports
import { formatDate } from "./utils.js";

// Type-only imports — always use import type
import type { User } from "./types.js";
```

**Don't use `consistent-type-imports` ESLint rule alongside `verbatimModuleSyntax`** — pick one enforcement layer. `verbatimModuleSyntax` is the compiler-level solution; if enabled, the ESLint rule is redundant.

### Import paths

Prefer `package.json` `imports` (subpath imports) over tsconfig `paths` for runtime-resolved aliases:

```json
// package.json
{
  "imports": {
    "#db/*": "./src/db/*.js",
    "#utils/*": "./src/utils/*.js"
  }
}
```

```typescript
// Works at both compile time AND runtime (Node resolves it)
import { pool } from "#db/client.js";
```

tsconfig `paths` only affects compile-time resolution — Node doesn't know about them at runtime unless you add a separate path-mapping loader.

## Branded Types

For domain modeling — prevents accidental ID mix-ups at compile time:

```typescript
type Brand<T, B extends string> = T & { readonly __brand: B };
type UserId = Brand<string, "UserId">;
type OrderId = Brand<string, "OrderId">;

// Constructor functions
const toUserId = (id: string): UserId => id as UserId;
const toOrderId = (id: string): OrderId => id as OrderId;

// Compiler prevents mixing
function getOrder(userId: UserId, orderId: OrderId) { /* ... */ }

getOrder(toUserId("u1"), toOrderId("o1")); // OK
getOrder(toOrderId("o1"), toUserId("u1")); // Compile error
```

## Discriminated Unions

For state machines and typed variants:

```typescript
type RequestState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: string[] }
  | { status: "error"; error: Error };

function render(state: RequestState): string {
  switch (state.status) {
    case "idle": return "Ready";
    case "loading": return "Loading...";
    case "success": return state.data.join(", ");
    case "error": return state.error.message;
  }
  // No default needed — TS proves exhaustiveness
}
```

## Quick Reference

| Pattern | When to use |
|---------|-------------|
| Schema validation (Zod/Valibot) | Every trust boundary — API, env, config, forms |
| `try/catch` + custom errors | Default error handling |
| `neverthrow` Result | Typed errors where callers must handle failure |
| Effect-TS | Full typed effect system (team commitment required) |
| Branded types | Domain IDs that must not be mixed |
| Discriminated unions | State machines, typed variants |
| `type` (not `interface`) | Default for all type definitions |
| Direct imports (no barrels) | Always — import from source files |
| `#imports` (subpath) | Runtime-resolved aliases via package.json |
