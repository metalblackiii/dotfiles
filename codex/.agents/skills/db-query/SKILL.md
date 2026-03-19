---
name: db-query
description: ALWAYS invoke when you need to query a live MySQL database, inspect table schemas, explore data, or verify database state. Triggers on "check the database", "what tables exist", "query the DB", "look at the data", "describe this table", "run this SQL". Do not answer database questions from memory when live data is available.
---

# DB Query

Execute queries against live MySQL databases via the `dbq` wrapper. For query design, optimization, and EXPLAIN analysis, use `database-expert` instead.

## Prerequisites

- `mysql-client` must be installed and on PATH (`brew install mysql-client`). It is keg-only — if `mysql` is not found after install, the user must add it to PATH manually (see Troubleshooting).
- Login paths configured via `mysql_config_editor` (see Setup below)
- A running MySQL instance (local Docker, k8s, or tunneled Aurora)

## Setup

Login paths are stored encrypted in `~/.mylogin.cnf` via `mysql_config_editor`. The agent does not manage this file — the user sets it up once.

```bash
# Create login paths
mysql_config_editor set --login-path=unit --host=127.0.0.1 --port=3306 --user=root --password
mysql_config_editor set --login-path=local --host=mysqldev --port=3306 --user=root --password

# Verify
mysql_config_editor print --all
```

## Connections

| Login Path | Environment | When Available |
|---|---|---|
| `unit` | Docker MySQL (unit/integration tests) | After `npm run start:local:dependencies` in neb-local-dev |
| `local` | K8s cluster MySQL (local dev) | After `npm run connect` in neb-local-dev |

Additional login paths (e.g., `dev`, `staging`) may exist for tunneled Aurora/RDS connections.

If unsure which environment is running or which login path to use, ask the user.

## Commands

Use the `dbq.sh` wrapper for all queries. It uses `--login-path` for credentials (never exposed), enforces read-only sessions, and applies hardening flags automatically.

The script lives alongside this skill. Use the path that matches the current platform:

| Platform | Path |
|---|---|
| Claude Code | `~/.claude/skills/db-query/scripts/dbq.sh` |
| Codex | `~/.agents/skills/personal/db-query/scripts/dbq.sh` |

Use the path matching your platform in all commands below. Examples use the Claude Code path.

```bash
# Usage: dbq.sh <login-path> <database> <sql>

# List databases
~/.claude/skills/db-query/scripts/dbq.sh local information_schema "SELECT SCHEMA_NAME FROM SCHEMATA"

# List tables
~/.claude/skills/db-query/scripts/dbq.sh local global "SHOW TABLES"

# Describe table structure
~/.claude/skills/db-query/scripts/dbq.sh local global "DESCRIBE <table>"

# Query data
~/.claude/skills/db-query/scripts/dbq.sh local global "SELECT <columns> FROM <table> WHERE <condition> LIMIT 100"

# Show indexes
~/.claude/skills/db-query/scripts/dbq.sh local global "SHOW INDEX FROM <table>"

# Count rows
~/.claude/skills/db-query/scripts/dbq.sh local global "SELECT COUNT(*) FROM <table>"
```

Replace `local` with the appropriate login path and `global` with the target database.

## Schema Context

The neb platform uses **database-per-tenant sharding** — each tenant gets its own set of databases. No `WHERE tenantId = ?` is needed; connecting to the right database IS the isolation.

### Known databases (local dev)

| Database | Service | Contents |
|---|---|---|
| `global` | platform | Tenant registry, service status, feature flags |
| `permissions_production` | permissions | Practice users, locations, roles |
| `helixPractice_*` | neb-ms-core | Patients, appointments, providers, encounters |
| `billing_helixPractice_*` | neb-ms-billing | Claims, invoices, payments, line items |
| `charting_helixPractice_*` | charting | Encounter charges, charting data |
| `electronicclaims_helixPractice_*` | neb-ms-electronic-claims | eClaims, ERA transactions, 835/837 data |
| `payments_helixPractice_*` | payments | Payment processing |

### Table and column conventions

- **Table names**: camelCase, singular — `patient`, `lineItem`, `patientCase`, `eClaim`
- **Column names**: camelCase — `patientId`, `dateOfBirth`, `claimFilingIndicator`
- **Primary keys**: UUID (`CHAR(36)`) named `id`
- **Foreign keys**: `{modelName}Id` — `invoiceId`, `patientCaseId`
- **Money columns**: INTEGER (cents) — divide by 100 for dollars
- **Timestamps**: `createdAt` / `updatedAt` (DATETIME)

## Safety Rules

1. **Always use LIMIT** — default to 100, max 1000. Never run unbounded SELECTs.
2. **SELECT only** — the wrapper enforces read-only sessions. INSERT/UPDATE/DELETE will fail.
3. **Verify before querying** — run SHOW TABLES or DESCRIBE before querying unfamiliar tables.
4. **Never query non-local databases** without explicit user confirmation.
5. **No sensitive data in output** — if results contain PII/PHI (names, SSNs, emails, phone numbers), summarize or aggregate instead of displaying raw rows.
6. **Never call `my_print_defaults`** — it exposes credentials. Always use `dbq.sh`.

## Workflow

1. Determine which environment the user wants to query (ask if unclear)
2. Start with schema exploration (SHOW TABLES → DESCRIBE) before data queries
3. Apply LIMIT to every SELECT query

## Troubleshooting

| Problem | Fix |
|---|---|
| `mysql: command not found` | `brew install mysql-client` — it's keg-only, may need `brew link --force mysql-client` or adding to PATH manually |
| `unknown variable 'login-path=...'` | `--login-path` must be the FIRST flag. The `dbq.sh` wrapper handles this — always use it instead of raw `mysql`. |
| `login path '...' not found` | Run `mysql_config_editor print --all` to see configured paths. User needs to add the login path. |
| `Can't connect to MySQL server` | Check if the database is running. Unit (Docker): `npm run start:local:dependencies`. Local (k8s): `npm run connect`. |
| `Access denied` | Login path credentials may be wrong. Ask the user to re-run `mysql_config_editor set --login-path=<name>`. |
| `Cannot execute statement in a READ ONLY transaction` | Expected — the wrapper enforces read-only. Only SELECT/SHOW/DESCRIBE are allowed. |
| `Unknown database` | List databases: `dbq.sh <login-path> information_schema "SELECT SCHEMA_NAME FROM SCHEMATA"` |
