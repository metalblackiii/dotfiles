---
name: neb-ms-conventions
description: Use when writing or modifying code in neb microservice repositories (neb-ms-* or neb-microservice) (org-specific example)
---

# Neb Service Conventions

## Overview

All `neb-ms-*` services extend `@neb/microservice`. This skill covers the patterns and conventions for implementing code in these services. The framework source in the `neb-microservice` repo may be available locally — consult it when you need to understand how middleware, routing, or helpers work under the hood.

## Directory Layout

```
src/
  controllers/     # Filesystem-based routing
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

## Filesystem-Based Routing

Routes are defined by directory structure, processed by `processDirectory` from `@neb/microservice`:

```
src/controllers/api/v1/tenants/:tenantId/charges/get.js    → GET  /api/v1/tenants/:tenantId/charges
src/controllers/api/v1/tenants/:tenantId/charges/:id/put.js → PUT  /api/v1/tenants/:tenantId/charges/:id
```

Versioned (`v1`, `v2`) and unversioned routes coexist.

## Controller Pattern

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

## Database

- **MySQL** (mysql2/Sequelize) for most services, **Postgres** for warehouse pipelines
- **Multi-tenant**: each request gets a tenant-scoped DB connection via `req.db`
- Models accessed as `db.ModelName` (e.g., `db.Charge.findAll(...)`)
- Migrations managed by `neb-database-migrator` (umzug, runs during promotion)
- Redis (ioredis) for transparent caching

## Cross-Service Communication

**REST via `msRequest`** (primary pattern):

```js
import { msRequest } from '@neb/microservice';
msRequest({
  method: 'get',
  url: `${process.env.NEB_PAYMENTS_API_URL}/api/v1/tenants/${tenantId}/...`,
  headers: { 'X-ACCESS-TOKEN': process.env.MS_SECRET_KEY },
  opts: { json: true },
});
```

- Service URLs from env vars: `NEB_<SERVICE>_API_URL`
- Auth via `X-ACCESS-TOKEN` header with `MS_SECRET_KEY`
- API client modules in `src/api-clients/` wrap `msRequest` for specific services
- `@neb/route-resolver` builds parameterized URLs

**Kafka messaging** (async):
- Send/subscribe pairs from `@neb/microservice` (e.g., `sendCreateTenant`/`subscribeCreateTenant`)
- Handlers live in `src/messaging/`

**SQS** — used in some services (claims, clearinghouse)

## Auth & Security

- **Cognito** for user authentication (JWT via express-jwt)
- `@neb/permissions` provides `SECURITY_SCHEMA_KEYS` for endpoint authorization
- `userSecurity` middleware enforces permissions per-route

## Testing Conventions

- Tests in `test/` mirror `src/` structure (e.g., `test/controllers/...`, `test/services/...`)
- `@neb/factory-girl` for test data factories (defined in `factories/`)
- `@neb/test-support` for shared test helpers

## Observability

- **Datadog** (dd-trace) for tracing, `@neb/datadog` helpers
- **Pino** for structured logging

## Architectural Decisions

For service boundary design, DDD patterns, saga/choreography decisions, data ownership strategy, or any architectural design work spanning neb services — use `legacy-modernizer` for incremental migration strategy and `api-designer` for contract/interface design. This skill covers *how the codebase works today*; those skills cover *how to design what comes next*.
