---
name: db-query
description: ALWAYS invoke when you need to query a live MySQL database, inspect table schemas, explore data, or verify database state. Triggers on "check the database", "what tables exist", "query the DB", "look at the data", "describe this table", "run this SQL". Do not answer database questions from memory when live data is available.
---

# DB Query

Execute queries against live MySQL databases using `mycli` with DSN aliases. For query design, optimization, and EXPLAIN analysis, use `database-expert` instead.

## Prerequisites

- `mycli` must be installed (`brew install mycli`)
- DSN aliases configured in `~/.myclirc` (see Setup below)
- A running MySQL instance (local Docker, k8s, or tunneled Aurora)

## Setup

DSN aliases are configured in `~/.myclirc` under `[alias_dsn]`. The agent does not manage this file — the user sets it up once. Example structure:

```ini
[alias_dsn]
unit = mysql://root:password@127.0.0.1:3306/global
local = mysql://ct_prod:password@mysqldev:3306/global
```

## Connections

| DSN Alias | Environment | When Available |
|---|---|---|
| `unit` | Docker MySQL (unit/integration tests) | After `npm run start:local:dependencies` in neb-local-dev |
| `local` | K8s cluster MySQL (local dev) | After `npm run connect` in neb-local-dev |

Additional aliases (e.g., `dev`, `staging`) may exist for tunneled Aurora/RDS connections.

If unsure which environment is running or which alias to use, ask the user.

## Commands

Always use `--csv` for structured output the agent can parse. Always use `--dsn <alias>` for the connection.

```bash
# List databases
mycli --csv --dsn local -e "SHOW DATABASES"

# List tables
mycli --csv --dsn local -e "SHOW TABLES"

# Describe table structure
mycli --csv --dsn local -e "DESCRIBE <table>"

# Query data
mycli --csv --dsn local -e "SELECT <columns> FROM <table> WHERE <condition> LIMIT 100"

# Show indexes
mycli --csv --dsn local -e "SHOW INDEX FROM <table>"

# Count rows
mycli --csv --dsn local -e "SELECT COUNT(*) FROM <table>"
```

Replace `local` with the appropriate DSN alias for the target environment.

## Safety Rules

1. **Always use LIMIT** — default to 100, max 1000. Never run unbounded SELECTs.
2. **SELECT only** — no INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, or CREATE.
3. **Verify before querying** — run SHOW TABLES or DESCRIBE before querying unfamiliar tables.
4. **Never query non-local databases** without explicit user confirmation.
5. **No sensitive data in output** — if results contain PII/PHI (names, SSNs, emails, phone numbers), summarize or aggregate instead of displaying raw rows.

## Workflow

1. Determine which environment the user wants to query (ask if unclear)
2. Use the matching DSN alias from the connections table
3. Start with schema exploration (SHOW TABLES → DESCRIBE) before data queries
4. Use `--csv` flag on every invocation for clean, parseable output
5. Apply LIMIT to every SELECT query

## Troubleshooting

| Problem | Fix |
|---|---|
| `mycli: command not found` | Run `brew install mycli` |
| `Can't connect to MySQL server` | Check if the database is running. Unit (Docker): `npm run start:local:dependencies`. Local (k8s): `npm run connect`. |
| `Access denied` | Check DSN alias credentials in `~/.myclirc` match the target environment. |
| `Unknown database` | Run `SHOW DATABASES` to list available databases. |
| `Unknown alias` | Run `mycli --list-dsn` to see configured aliases. User needs to add the alias to `~/.myclirc`. |
