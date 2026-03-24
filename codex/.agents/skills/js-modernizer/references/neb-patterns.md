# Neb-Specific Migration Patterns

Patterns specific to the neb microservice ecosystem. All neb repos share the same architecture: ESM source → Babel → CJS output, zero TypeScript, zero JSDoc, Mocha + Chai + Sinon.

## Critical Path

```
1. @neb/microservice  — type the base framework (190+ exports)
2. neb-ms-image       — pilot migration (31 files, leaf node)
3. neb-ms-billing     — largest service (1,592 src files)
4. neb-www            — frontend (3,170 files, Lit components)
```

**neb-microservice must be typed first.** Every service imports from it. Without types on `setupServer`, `auth`, `msRequest`, `InvalidParamsError`, etc., downstream services can't have meaningful types.

## @neb/microservice: Type Declaration Strategy

The base framework won't migrate to TS overnight. Ship `.d.ts` declarations alongside the JS source so consumers get types immediately.

### Minimal viable declarations

```typescript
// index.d.ts (ship alongside index.js)
import type { Express, Request, Response, NextFunction, Router } from "express";

// Server setup
export interface ServerConfig {
  port?: number;
  routes: string;
  models?: string;
  messaging?: MessagingConfig;
}
export function setupServer(config: ServerConfig): Express;
export function processDirectory(dir: string, router: Router): void;

// Middleware
export function auth(req: Request, res: Response, next: NextFunction): void;
export function userSecurity(req: Request, res: Response, next: NextFunction): void;
export function timezone(req: Request, res: Response, next: NextFunction): void;
export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction): void;

// Errors
export class InvalidParamsError extends Error {
  statusCode: 400;
}
export class NotFoundError extends Error {
  statusCode: 404;
}
export class UnauthorizedError extends Error {
  statusCode: 401;
}
export class MsRequestError extends Error {
  statusCode: number;
}

// Cross-service requests
export interface MsRequestOptions {
  method?: string;
  uri: string;
  headers?: Record<string, string>;
  body?: unknown;
  json?: boolean;
  qs?: Record<string, string>;
}
export function msRequest(options: MsRequestOptions): Promise<unknown>;
export function stubMsRequest(stubs: Record<string, unknown>): void;

// Database
export function getDbConnection(req: Request): unknown;
export function getTenantDbConnection(tenantId: string): unknown;
export function getGlobalDbConnection(): unknown;

// Messaging
export interface MessagingConfig {
  kafkaHost?: string;
  groupId?: string;
}
export class MessagingClient {
  send(topic: string, message: unknown): Promise<void>;
  subscribe(topic: string, handler: (message: unknown) => Promise<void>): void;
}

// Utilities
export function sleep(ms: number): Promise<void>;
export function executeInTransaction<T>(
  db: unknown,
  fn: (transaction: unknown) => Promise<T>,
): Promise<T>;
```

**Ship this as a `.d.ts` file next to `index.js` in the published package.** Add `"types": "./index.d.ts"` to `package.json`. Downstream services immediately get IDE inference without any migration.

## Sequelize `db.ModelName` Pattern

The most common hard-to-type pattern across neb services. Models are accessed dynamically:

```javascript
// Current pattern — untyped
const { Charge, Payment, Patient } = req.db;
const charge = await Charge.findByPk(id);
```

### Typing strategy

Create a models interface that maps model names to Sequelize model types:

```typescript
// types/models.d.ts
import type { Model, ModelStatic } from "sequelize";

interface ChargeAttributes {
  id: number;
  amount: number;
  patientId: number;
  status: "pending" | "posted" | "void";
}

interface PaymentAttributes {
  id: number;
  amount: number;
  chargeId: number;
}

interface NebModels {
  Charge: ModelStatic<Model<ChargeAttributes>>;
  Payment: ModelStatic<Model<PaymentAttributes>>;
  Patient: ModelStatic<Model<PatientAttributes>>;
  // ... add models as needed
}

// Augment Express Request
declare module "express-serve-static-core" {
  interface Request {
    db: NebModels;
  }
}
```

**Incremental approach:** Don't type all models at once. Start with `Record<string, ModelStatic<Model>>` and narrow individual models as you migrate their files:

```typescript
// Start with this (permissive)
interface NebModels {
  [key: string]: ModelStatic<Model>;
}

// Then narrow individual models as you migrate
interface NebModels {
  Charge: ModelStatic<Model<ChargeAttributes>>;
  [key: string]: ModelStatic<Model>; // catch-all for unmigrated
}
```

## Lit Component Typing (neb-www)

neb-www uses Lit 2 with `static get properties()` patterns. Lit ships its own TypeScript types.

### Current JS pattern

```javascript
import { LitElement, html, css } from "lit";

class MyComponent extends LitElement {
  static get properties() {
    return {
      name: { type: String },
      count: { type: Number },
      items: { type: Array },
    };
  }

  constructor() {
    super();
    this.name = "";
    this.count = 0;
    this.items = [];
  }

  render() {
    return html`<div>${this.name}: ${this.count}</div>`;
  }
}

customElements.define("my-component", MyComponent);
```

### Typed TS pattern

```typescript
import { LitElement, html, css } from "lit";
import { customElement, property } from "lit/decorators.js";

@customElement("my-component")
class MyComponent extends LitElement {
  @property({ type: String }) name = "";
  @property({ type: Number }) count = 0;
  @property({ type: Array }) items: string[] = [];

  render() {
    return html`<div>${this.name}: ${this.count}</div>`;
  }
}
```

**Note:** Lit decorators require `experimentalDecorators` (Lit hasn't migrated to TC39 decorators yet as of Lit 3). If the project uses `erasableSyntaxOnly`, use the non-decorator pattern:

```typescript
import { LitElement, html } from "lit";
import { property } from "lit/decorators.js";

// Non-decorator alternative (works with erasableSyntaxOnly)
class MyComponent extends LitElement {
  static override properties = {
    name: { type: String },
    count: { type: Number },
    items: { type: Array },
  };

  declare name: string;
  declare count: number;
  declare items: string[];

  constructor() {
    super();
    this.name = "";
    this.count = 0;
    this.items = [];
  }

  override render() {
    return html`<div>${this.name}: ${this.count}</div>`;
  }
}
customElements.define("my-component", MyComponent);
```

### `__` private convention → private fields

```typescript
// Before (convention)
this.__internalState = null;

// After (language feature)
#internalState: string | null = null;
// Or if public API depends on __ access:
private __internalState: string | null = null;
```

**Caution:** `#private` fields have different runtime semantics than `__convention` — they're truly inaccessible from outside. If tests or parent classes access `__` properties, use `private` keyword instead.

## Legacy Polymer 3 Components (neb-www)

neb-www still has `@polymer/paper-*` components. These have minimal TypeScript support.

**Strategy:** Don't migrate Polymer components to TS. Instead:
1. Create `.d.ts` stubs for Polymer components used in Lit code
2. Migrate Polymer → Lit first (separate effort), then Lit JS → Lit TS
3. Typing Polymer components is wasted effort if they'll be replaced

## moment-timezone (neb-ms-billing)

391 usages across 115 files in billing. This is a parallel track, not a blocker for TS migration.

**For TS migration:** `moment` has `@types/moment` — types exist, they just aren't great. You can migrate `.js` → `.ts` while keeping `moment` and replace later.

**For modernization:** `date-fns` is the most common replacement. Migration is file-by-file:

```javascript
// Before
import moment from "moment-timezone";
const formatted = moment(date).tz("America/New_York").format("YYYY-MM-DD");
const diff = moment(end).diff(moment(start), "days");

// After
import { format, differenceInDays } from "date-fns";
import { toZonedTime } from "date-fns-tz";
const zoned = toZonedTime(date, "America/New_York");
const formatted = format(zoned, "yyyy-MM-dd");
const diff = differenceInDays(end, start);
```

## request-promise → fetch/undici (neb-microservice)

`msRequest` is the cross-service HTTP primitive. Replacing it affects every service.

```javascript
// Before (request-promise)
import rp from "request-promise";
const result = await rp({
  method: "GET",
  uri: `${baseUrl}/api/users/${id}`,
  headers: { Authorization: `Bearer ${token}` },
  json: true,
});

// After (native fetch)
const res = await fetch(`${baseUrl}/api/users/${id}`, {
  headers: { Authorization: `Bearer ${token}` },
});
if (!res.ok) throw new MsRequestError(`HTTP ${res.status}`);
const result = await res.json();
```

**Strategy:** Replace `msRequest` internals first (one commit). The function signature stays the same — consumers don't change. Then gradually migrate the signature to a more modern API.

## Mocha + Chai + Sinon in TypeScript

The test stack works in TS with minimal changes:

```bash
npm install -D @types/mocha @types/chai @types/sinon
```

```typescript
// test/services/user.test.ts
import { expect } from "chai";
import sinon from "sinon";
import { findUser } from "../src/services/user.js";

describe("findUser", () => {
  afterEach(() => sinon.restore());

  it("returns user by id", async () => {
    const stub = sinon.stub(db.User, "findByPk").resolves({ id: "1", name: "Jane" });
    const result = await findUser("1");
    expect(result).to.deep.equal({ id: "1", name: "Jane" });
    expect(stub.calledOnceWith("1")).to.be.true;
  });
});
```

**Don't migrate tests and source simultaneously.** Migrate source files to TS first, keep tests in JS. Migrate tests as a separate phase.
