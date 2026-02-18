---
name: neb-repo-layout
description: Use when exploring, analyzing, or writing code across neb repositories to know where repos live and how they're organized.
user-invocable: false
---

# Neb Repository Layout

## Base Path

All neb repositories live in `~/repos/`. Not all may be cloned locally — run `Glob` with `pattern="neb-*" path="~/repos/"` to discover what's available.

## Architecture Layers

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

## Environments

- **local-dev** — developer machines, governed by `neb-local-dev` (Docker-based, MySQL container)
- **dev** — shared, main deployment target, real AWS services (Cognito, RDS, etc.)
- **staging** — pre-prod + sales demos (merged with former "sales" environment)
- **prod** — separate AWS account, extra protections

Dev, staging, and prod are all deployed via `neb-deploy` (Helm, CI/CD config, environment-specific settings).

## Backend Microservices (complete list)

`neb-ms-appointments`, `neb-ms-billing`, `neb-ms-charting`, `neb-ms-clearinghouse` (no db), `neb-ms-conversion`, `neb-ms-core`, `neb-ms-data-integrity`, `neb-ms-electronic-claims`, `neb-ms-email` (no db), `neb-ms-files` (no db), `neb-ms-image`, `neb-ms-macro-metadata`, `neb-ms-partner`, `neb-ms-payments`, `neb-ms-pdf` (no db), `neb-ms-permissions`, `neb-ms-registry`, `neb-ms-reports`, `neb-ms-x12` (no db)

Mock services (`neb-ms-mock-*`) simulate external dependencies.

## Shared Library Convention

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
