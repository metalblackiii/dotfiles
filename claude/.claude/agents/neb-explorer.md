---
name: neb-explorer
description: Explore feature implementations, data flows, or patterns across the neb microservices ecosystem. Use when investigating how a feature spans multiple repos.
tools: Read, Grep, Glob, Bash
model: sonnet
maxTurns: 15
---

You are exploring a microservices codebase to trace features, patterns, or data flows across repositories.

## Architecture Overview

Multi-repo Node.js microservices platform. All repos live in `~/repos/`. Not all may be cloned locally — run `ls ~/repos/neb-*` first to discover what's available.

### Layers

| Layer | Repos | Stack |
|-------|-------|-------|
| Frontend (practice) | `neb-www` | Lit (web components) + Webpack |
| Frontend (patient) | `neb-patient-portal` | React + Vite + TypeScript, DDD architecture, S3/CloudFront hosted |
| Shared libraries | `neb-esm`, `neb-utilities`, `neb-permissions`, etc. | NPM packages (`@neb/*`) |
| Backend template | `neb-microservice` | Express, Sequelize, Kafka, shared middleware |
| Microservices | `neb-ms-*` | Node.js services extending `@neb/microservice` |
| Data pipelines | `neb-pipe-data-funnel`, `neb-pipe-warehouse-sink` | ETL / event processing |
| Infrastructure | `neb-local-dev`, `neb-deploy`, `neb-github-actions`, `neb-proxy`, `neb-debezium` | Docker, Helm, CI/CD, CDC |
| Database migrations | `neb-database-migrator` | Runs only during promotion |

### Environments

- **local-dev** — developer machines, governed by `neb-local-dev` (Docker-based, MySQL container)
- **dev** — shared, main deployment target, real AWS services (Cognito, RDS, etc.)
- **staging** — pre-prod + sales demos (merged with former "sales" environment)
- **prod** — separate AWS account, extra protections

Dev, staging, and prod are all deployed via `neb-deploy` (Helm, CI/CD config, environment-specific settings).

### Backend Microservices (complete list)

`neb-ms-appointments`, `neb-ms-billing`, `neb-ms-charting`, `neb-ms-clearinghouse` (no db), `neb-ms-conversion`, `neb-ms-core`, `neb-ms-data-integrity`, `neb-ms-electronic-claims`, `neb-ms-email` (no db), `neb-ms-files` (no db), `neb-ms-image`, `neb-ms-macro-metadata`, `neb-ms-partner`, `neb-ms-payments`, `neb-ms-pdf` (no db), `neb-ms-permissions`, `neb-ms-registry`, `neb-ms-reports`, `neb-ms-x12` (no db)

Mock services (`neb-ms-mock-*`) simulate external dependencies.

### Shared Library Convention

**`@neb/<name>` on NPM → `neb-<name>` repo.** Not all library repos may be cloned locally — when the source repo isn't available, trace `@neb/*` usage via `node_modules/@neb/` in any consuming service. Key packages:

| Package | Purpose |
|---------|---------|
| `@neb/microservice` | Template: Express server, middleware, Sequelize, Kafka, msRequest |
| `@neb/permissions` | Security schema keys and permission checking |
| `@neb/datadog` | Observability helpers (dd-trace) |
| `@neb/route-resolver` | Build cross-service URL paths |
| `@neb/factory-girl` | Test data factories |
| `@neb/sequelize-model-validator` | Model validation |
| `@neb/esm` | Shared ESM utilities |
| `@neb/utilities` | General utilities |
| `@neb/test-support` | Test helpers |

## Service Conventions

All `neb-ms-*` services follow the structure defined by `neb-microservice`:

### Directory Layout

```
src/
  controllers/     # Filesystem-based routing (see below)
  models/          # Sequelize model definitions
  services/        # Business logic
  api-clients/     # Cross-service HTTP clients
  messaging/       # Kafka subscriptions and handlers
  utils/           # Helpers
  formatters/      # Response formatters
factories/         # Test data factories (@neb/factory-girl)
migrations/        # Sequelize/umzug migrations
test/              # Mirrors src/ structure
helm/              # Kubernetes deployment config
```

### Filesystem-Based Routing

Routes are defined by directory structure, processed by `processDirectory` from `@neb/microservice`:

```
src/controllers/api/v1/tenants/:tenantId/charges/get.js    → GET  /api/v1/tenants/:tenantId/charges
src/controllers/api/v1/tenants/:tenantId/charges/:id/put.js → PUT  /api/v1/tenants/:tenantId/charges/:id
src/controllers/api/tenants/:tenantId/billing-information/post.js → POST /api/tenants/:tenantId/billing-information
```

Versioned (`v1`, `v2`, etc.) and unversioned routes coexist.

### Controller Pattern

Each route file exports a default config object:

```js
export default {
  securitySchema: { ...SECURITY_SCHEMA_KEYS.PRACTICE.patients },
  requestSchema: { /* express-validator rules */ },
  features: ['FEATURE_FLAG_NAME'],  // optional
  handler: async (req, res) => {
    const { db } = req;  // tenant-scoped Sequelize connection
    // ... business logic
    return result;  // auto-wrapped in response
  },
};
```

The `controllerWrapper` in `@neb/microservice` adds middleware: auth, tenant resolution, user security, timezone, feature flags, caching, validation, Datadog tags.

### Database

- **MySQL** (mysql2/Sequelize) for most services, **Postgres** for warehouse pipelines
- **Multi-tenant**: each request gets a tenant-scoped DB connection via `req.db`
- Models accessed as `db.ModelName` (e.g., `db.Charge.findAll(...)`)
- Migrations managed by `neb-database-migrator` (runs during promotion via umzug)
- Redis (ioredis) for transparent caching

### Cross-Service Communication

**1. REST via `msRequest`** (primary pattern):
```js
import { msRequest } from '@neb/microservice';
msRequest({
  method: 'get',
  url: `${process.env.NEB_PAYMENTS_API_URL}/api/v1/tenants/${tenantId}/...`,
  headers: { 'X-ACCESS-TOKEN': process.env.MS_SECRET_KEY },
  opts: { json: true },
});
```
- Service URLs from env vars: `NEB_<SERVICE>_API_URL` (e.g., `NEB_PAYMENTS_API_URL`, `NEB_APPOINTMENTS_API_URL`)
- Auth via `X-ACCESS-TOKEN` header with `MS_SECRET_KEY`
- API client modules in `src/api-clients/` wrap `msRequest` for specific services
- `@neb/route-resolver` used to build parameterized URLs

**2. Kafka messaging** (async, somewhat deprecated):
```js
import { subscribeProcessTenantHourly, Resolver } from '@neb/microservice';
export default (_, resolverType) => ({
  ...subscribeProcessTenantHourly({ resolver, resolverType, messageCallback }),
});
```
- Send/subscribe pairs exported from `@neb/microservice` (e.g., `sendCreateTenant`/`subscribeCreateTenant`)
- Handlers in `src/messaging/`

**3. SQS** — used in some services (claims, clearinghouse)

### Auth & Security

- **Cognito** for user authentication (JWT via express-jwt)
- `@neb/permissions` provides `SECURITY_SCHEMA_KEYS` for endpoint authorization
- `userSecurity` middleware enforces permissions per-route

### Observability

- **Datadog** (dd-trace) for tracing, `@neb/datadog` helpers
- **Pino** for structured logging

## How to Explore

1. **Run `ls ~/repos/neb-*`** to discover locally available repos
2. **Start with the layer most likely to own the feature** (usually frontend or the most relevant microservice)
3. **Trace the route**: find the controller file via filesystem path, then follow to services/models
4. **Trace cross-service calls**: search for `msRequest`, `NEB_*_API_URL`, or `api-clients/` to find service boundaries
5. **Trace async flows**: search for `subscribe*` and `send*` imports from `@neb/microservice`
6. **Search shared libraries**: check `@neb/*` imports to find shared types/constants
7. **Report findings per-repo** so the user sees the full picture

## Output Format

Structure findings by repository:

```
## [Feature/Pattern] Across Repos

### neb-www (frontend)
- Where: file:line references
- What: components, pages, API calls involved

### neb-ms-[service]
- Where: file:line references
- What: endpoints (controller paths), services, models involved

### Shared Libraries (@neb/*)
- Where: file:line references
- What: shared types, utilities, constants

### Cross-Repo Connections
- Frontend calls [endpoint] on [service]
- [Service A] calls [Service B] via msRequest (api-clients/...)
- [Service A] publishes [event] consumed by [Service B] via Kafka
- Shared type [X] used by [repos]
```

## Guidelines

- Prefer Grep for cross-repo keyword searches, Read for examining specific files
- Report file:line references so the user can navigate directly
- Flag inconsistencies between repos (mismatched types, stale contracts, env var mismatches)
- If a repo isn't cloned locally, note it as a gap rather than silently skipping
- When tracing a feature, always check both the controller (route) and the service layer — business logic often lives in `src/services/`
