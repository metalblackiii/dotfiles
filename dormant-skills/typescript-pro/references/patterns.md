# TypeScript Patterns

## Parse, Don't Validate (Schema-First)

**Status: dominant methodology** — the primary pattern for handling external data in modern TypeScript.

Instead of accepting `unknown` and sprinkling type assertions or manual checks, define a schema that parses input into a validated, typed value — or fails with a structured error. This is the "Parse, Don't Validate" principle: once data crosses a trust boundary, parse it into a known type immediately.

```typescript
import { z } from "zod";

// Define the schema — this IS the type definition
const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(["admin", "member", "guest"]),
});

// Derive the TypeScript type from the schema
type User = z.infer<typeof UserSchema>;

// Parse at system boundaries — API handlers, file reads, env vars
function handleRequest(body: unknown): User {
  return UserSchema.parse(body); // throws ZodError on invalid input
}

// Safe parse for when you want to handle errors explicitly
function tryParseUser(body: unknown) {
  const result = UserSchema.safeParse(body);
  if (!result.success) {
    return { ok: false as const, error: result.error.flatten() };
  }
  return { ok: true as const, user: result.data };
}
```

```typescript
// Valibot — tree-shakeable alternative to Zod
import * as v from "valibot";

const UserSchema = v.object({
  id: v.pipe(v.string(), v.uuid()),
  name: v.pipe(v.string(), v.minLength(1)),
  email: v.pipe(v.string(), v.email()),
  role: v.picklist(["admin", "member", "guest"]),
});

type User = v.InferOutput<typeof UserSchema>;
```

**When to use:** API request/response boundaries, environment variables, config files, form data, database results, anything from `unknown` or `any`. Define the schema once, derive the type, parse at the boundary, then trust the type downstream.

**Zod vs Valibot:** Zod has broader ecosystem adoption and richer API. Valibot is tree-shakeable and produces smaller bundles — better for client-side code where bundle size matters.

## Builder Pattern

**Status: declining** — prefer option objects with `satisfies` for most config/construction needs. Builders add ceremony without adding safety when the alternative is a typed options bag.

```typescript
// Preferred: typed options object
interface UserOptions {
  name: string;
  email: string;
  age?: number;
  role?: "admin" | "member";
}

function createUser(options: UserOptions): User {
  return { id: crypto.randomUUID(), role: "member", ...options };
}

const user = createUser({ name: "Jane", email: "jane@example.com" });
```

Builders still make sense for progressive construction where intermediate states are meaningful (e.g., query builders, request pipelines), but not for one-shot object creation.

```typescript
// Builder still appropriate: progressive query construction
class QueryBuilder<T> {
  private conditions: Array<(item: T) => boolean> = [];

  where<K extends keyof T>(key: K, value: T[K]): this {
    this.conditions.push(item => item[key] === value);
    return this;
  }

  execute(items: T[]): T[] {
    return items.filter(item =>
      this.conditions.every(condition => condition(item))
    );
  }
}
```

## Factory Pattern

**Status: prefer factory functions** — class-heavy Abstract Factory is rarely needed in TypeScript. Factory functions returning plain objects are the modern default.

```typescript
// Factory function — the modern default
interface Logger {
  log(message: string): void;
}

type LoggerConfig =
  | { type: "console" }
  | { type: "file"; filename: string };

function createLogger(config: LoggerConfig): Logger {
  switch (config.type) {
    case "console":
      return { log: (msg) => console.log(msg) };
    case "file":
      return { log: (msg) => { /* write to config.filename */ } };
  }
}

const logger = createLogger({ type: "console" });
```

Use discriminated unions for config variants instead of class hierarchies. The factory function returns an interface — callers don't need to know or care about internals.

## Repository Pattern

```typescript
// Type-safe repository with generic CRUD
interface Entity {
  id: string | number;
}

interface Repository<T extends Entity> {
  find(id: T['id']): Promise<T | null>;
  findAll(): Promise<T[]>;
  create(data: Omit<T, 'id'>): Promise<T>;
  update(id: T['id'], data: Partial<Omit<T, 'id'>>): Promise<T>;
  delete(id: T['id']): Promise<void>;
}

class UserRepository implements Repository<User> {
  async find(id: User['id']): Promise<User | null> {
    // Database query
    return null;
  }

  async findAll(): Promise<User[]> {
    return [];
  }

  async create(data: Omit<User, 'id'>): Promise<User> {
    // Insert into database
    return { id: 1, ...data };
  }

  async update(id: User['id'], data: Partial<Omit<User, 'id'>>): Promise<User> {
    // Update database
    return { id, name: '', email: '', ...data };
  }

  async delete(id: User['id']): Promise<void> {
    // Delete from database
  }
}

// Query builder with type safety
class QueryBuilder<T> {
  private conditions: Array<(item: T) => boolean> = [];

  where<K extends keyof T>(key: K, value: T[K]): this {
    this.conditions.push(item => item[key] === value);
    return this;
  }

  execute(items: T[]): T[] {
    return items.filter(item =>
      this.conditions.every(condition => condition(item))
    );
  }
}

const query = new QueryBuilder<User>()
  .where('email', 'john@example.com')
  .where('age', 30);
```

## Type-Safe API Client

```typescript
// REST API client with type safety
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';

type ApiEndpoints = {
  '/users': {
    GET: { response: User[] };
    POST: { body: CreateUserDto; response: User };
  };
  '/users/:id': {
    GET: { params: { id: string }; response: User };
    PUT: { params: { id: string }; body: UpdateUserDto; response: User };
    DELETE: { params: { id: string }; response: void };
  };
  '/posts': {
    GET: { query: { userId?: string }; response: Post[] };
    POST: { body: CreatePostDto; response: Post };
  };
};

type ExtractParams<T extends string> =
  T extends `${infer _Start}/:${infer Param}/${infer Rest}`
    ? { [K in Param]: string } & ExtractParams<`/${Rest}`>
    : T extends `${infer _Start}/:${infer Param}`
    ? { [K in Param]: string }
    : {};

class ApiClient {
  async request<
    Path extends keyof ApiEndpoints,
    Method extends keyof ApiEndpoints[Path]
  >(
    method: Method,
    path: Path,
    options?: ApiEndpoints[Path][Method] extends { body: infer B }
      ? { body: B }
      : ApiEndpoints[Path][Method] extends { params: infer P }
      ? { params: P }
      : ApiEndpoints[Path][Method] extends { query: infer Q }
      ? { query: Q }
      : never
  ): Promise<
    ApiEndpoints[Path][Method] extends { response: infer R } ? R : never
  > {
    // Make HTTP request
    return null as any;
  }
}

const client = new ApiClient();

// Type-safe API calls
const users = await client.request('GET', '/users');
const user = await client.request('GET', '/users/:id', { params: { id: '1' } });
const newUser = await client.request('POST', '/users', {
  body: { name: 'John', email: 'john@example.com' }
});
```

## State Machine Pattern

```typescript
// Type-safe state machine
type State = 'idle' | 'loading' | 'success' | 'error';

type Event =
  | { type: 'FETCH' }
  | { type: 'SUCCESS'; data: any }
  | { type: 'ERROR'; error: Error }
  | { type: 'RETRY' };

type StateMachine = {
  [S in State]: {
    [E in Event['type']]?: State;
  };
};

const machine: StateMachine = {
  idle: { FETCH: 'loading' },
  loading: { SUCCESS: 'success', ERROR: 'error' },
  success: { FETCH: 'loading' },
  error: { RETRY: 'loading' }
};

class StateManager<S extends string, E extends { type: string }> {
  constructor(
    private state: S,
    private transitions: Record<S, Partial<Record<E['type'], S>>>
  ) {}

  getState(): S {
    return this.state;
  }

  dispatch(event: E): S {
    const nextState = this.transitions[this.state][event.type];
    if (nextState === undefined) {
      throw new Error(`Invalid transition from ${this.state} on ${event.type}`);
    }
    this.state = nextState;
    return this.state;
  }
}

const manager = new StateManager<State, Event>('idle', machine);
manager.dispatch({ type: 'FETCH' }); // 'loading'
manager.dispatch({ type: 'SUCCESS', data: {} }); // 'success'
```

## Decorator Pattern

**Status: framework-specific** — decorators are mainly relevant in NestJS, Angular, and similar class/DI-heavy frameworks. Outside those, prefer plain functions and composition.

TypeScript 5.0 standardized TC39 decorators. These are **not** compatible with legacy `experimentalDecorators` — they have different signatures, no parameter decorators, and no `emitDecoratorMetadata`. If migrating, it's a rewrite.

```typescript
// Standard decorator (TS 5.0+) — note the new signature
function Log<This, Args extends any[], Return>(
  target: (this: This, ...args: Args) => Return,
  context: ClassMethodDecoratorContext<This, (this: This, ...args: Args) => Return>,
) {
  return function (this: This, ...args: Args): Return {
    console.log(`Calling ${String(context.name)} with`, args);
    const result = target.call(this, ...args);
    console.log(`Result:`, result);
    return result;
  };
}

class Calculator {
  @Log
  add(a: number, b: number): number {
    return a + b;
  }
}
```

**When to use standard decorators:**
- NestJS controllers/services (NestJS is migrating to standard decorators)
- Angular components/services (Angular still uses legacy decorators as of v19)
- Libraries exposing decorator-based APIs

**When NOT to use:** general application code. A higher-order function achieves the same thing without class coupling:

```typescript
// Prefer: higher-order function
function withLogging<Args extends unknown[], R>(
  name: string,
  fn: (...args: Args) => R,
): (...args: Args) => R {
  return (...args) => {
    console.log(`Calling ${name} with`, args);
    const result = fn(...args);
    console.log(`Result:`, result);
    return result;
  };
}

const add = withLogging("add", (a: number, b: number) => a + b);
```

## Result/Either Pattern

```typescript
// Type-safe error handling
type Result<T, E = Error> =
  | { success: true; value: T }
  | { success: false; error: E };

function ok<T>(value: T): Result<T, never> {
  return { success: true, value };
}

function err<E>(error: E): Result<never, E> {
  return { success: false, error };
}

async function fetchUser(id: string): Promise<Result<User, string>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return err('User not found');
    }
    const user = await response.json();
    return ok(user);
  } catch (error) {
    return err('Network error');
  }
}

// Usage with pattern matching
const result = await fetchUser('123');
if (result.success) {
  console.log(result.value.name); // Type-safe access
} else {
  console.error(result.error); // Type-safe error
}

// Either monad
class Either<L, R> {
  private constructor(
    private readonly value: L | R,
    private readonly isRight: boolean
  ) {}

  static left<L, R>(value: L): Either<L, R> {
    return new Either<L, R>(value, false);
  }

  static right<L, R>(value: R): Either<L, R> {
    return new Either<L, R>(value, true);
  }

  map<T>(fn: (value: R) => T): Either<L, T> {
    if (this.isRight) {
      return Either.right(fn(this.value as R));
    }
    return Either.left(this.value as L);
  }

  flatMap<T>(fn: (value: R) => Either<L, T>): Either<L, T> {
    if (this.isRight) {
      return fn(this.value as R);
    }
    return Either.left(this.value as L);
  }

  getOrElse(defaultValue: R): R {
    return this.isRight ? (this.value as R) : defaultValue;
  }
}
```

## Singleton Pattern

**Status: antipattern in JS/TS** — a class with a single instance is just a module-scoped object. TypeScript's own docs note this. Use ES module scope for singleton behavior.

```typescript
// Antipattern: class-based singleton
// class Database { private static instance: Database; ... }

// Preferred: module-scoped instance
// db.ts
const pool = createPool({ connectionString: process.env.DATABASE_URL });

export function query<T>(sql: string, params?: unknown[]): Promise<T[]> {
  return pool.query(sql, params);
}

// Consumers import the module — the module IS the singleton
import { query } from "./db.ts";
```

In DI-framework contexts (Angular, NestJS), singleton behavior comes from the container (`providedIn: 'root'`, `@Injectable({ scope: Scope.DEFAULT })`), not from manual Singleton classes.

## Quick Reference

| Pattern | Status | Use Case |
|---------|--------|----------|
| Parse, Don't Validate | **dominant** | Schema-first boundary validation (Zod, Valibot) |
| Factory (functions) | **preferred** | Create objects via functions, not class hierarchies |
| Result/Either | **recommended** | Type-safe error handling without exceptions |
| State Machine | **recommended** | Manage typed state transitions |
| Repository | **stable** | Abstract data access layer |
| API Client | **stable** | Type-safe HTTP requests |
| Decorator | **framework-specific** | NestJS/Angular only; prefer HOFs elsewhere |
| Builder | **declining** | Only for progressive construction; prefer option objects |
| Singleton | **antipattern** | Use module scope or DI container instead |
