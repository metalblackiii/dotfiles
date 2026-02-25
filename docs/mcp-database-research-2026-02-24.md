# MCP Database Server Research

**Date:** 2026-02-24
**Status:** Research complete, pending pilot
**Context:** Evaluate MCP servers for MySQL/Aurora/RDS database operations in Claude Code and Codex

## Current State

### ptek-eng-toolbox (existing)

Custom MCP server at `~/repos/ptek-eng-toolbox` with a `database` profile containing:

- **schema-getter** — table schemas via Sequelize (MySQL, Postgres, SQLite, MSSQL)
- **query-execution-plan-getter** — EXPLAIN plans with dialect-specific optimization

**Known issue:** Both tools use string interpolation for agent-provided input (table names, queries). Needs parameterization and allowlist hardening before adding more DB surface area.

### Local dev environment (neb-local-dev)

`mysqldev` Helm chart in the local K8s cluster:

| Detail | Value |
|--------|-------|
| K8s service | `mysqldev`, port 3306 |
| Root creds | `root` / `password` |
| App user | `ct_prod` / `password` (ALL PRIVILEGES) |
| Default DB | `global` |
| Features | GTID mode, Debezium CDC, PV-backed |

Also has `postgresdev` in the same cluster.

## Options Evaluated

### Tier 1: AWS Official (awslabs/mcp)

**[awslabs/mysql-mcp-server](https://github.com/awslabs/mcp/tree/main/src/mysql-mcp-server)** (v1.0.15, 2026-02-05)

- Two connection modes: RDS Data API (`--resource_arn`) and direct MySQL (`--hostname`)
- Read-only by default (`--readonly True`)
- Auth: AWS IAM, Secrets Manager
- Works for both local dev (direct hostname) and Aurora/RDS (Data API)
- Install: `uvx awslabs.mysql-mcp-server@latest`

**[awslabs/postgres-mcp-server](https://github.com/awslabs/mcp/tree/main/src/postgres-mcp-server)** (v1.0.17, 2026-02-05)

- Similar dual-mode (RDS API + PG wire)
- Writes gated by `--allow_write_query`
- Relevant for `postgresdev` in local cluster

### Tier 2: Cross-Database Gateway

**[bytebase/dbhub](https://github.com/bytebase/dbhub)** (~4k stars)

- Multi-DB: MySQL, MariaDB, Postgres, SQL Server, SQLite
- Safety: read-only mode, row limiting, query timeout, SSH tunneling
- Multi-connection via TOML config
- Install: `npx @bytebase/dbhub@latest`

### Tier 3: Community MySQL

**[benborla/mcp-server-mysql](https://github.com/benborla/mcp-server-mysql)** (~500 stars)

- Granular write flags: `ALLOW_INSERT_OPERATION`, `ALLOW_UPDATE_OPERATION`, `ALLOW_DELETE_OPERATION` (all false by default)
- SSH tunnel, connection pooling, rate limiting, query timeout
- Install: `npx @benborla29/mcp-server-mysql`

**[cnosuke/mcp-mysql](https://github.com/cnosuke/mcp-mysql)**

- Go-based, Docker-first
- Unique: EXPLAIN pre-check before query execution
- Read-only mode removes write tools entirely from MCP tool list

## Capability Comparison

| Capability | awslabs/mysql | dbhub | benborla | cnosuke | ptek-toolbox |
|------------|:---:|:---:|:---:|:---:|:---:|
| Query execution | Yes | Yes | Yes | Yes | No |
| Schema inspection | Yes | Yes | Yes (auto) | Yes | Yes |
| Read-only mode | Default on | Yes | Per-operation | Yes | N/A |
| EXPLAIN plans | No | No | No | Pre-check | Yes |
| Row limiting | No | Yes | No | No | No |
| Query timeout | No | Yes | Yes | No | No |
| AWS IAM auth | Yes | No | No | No | No |
| Secrets Manager | Yes | No | No | No | No |
| Multi-database | Via config | TOML | Yes | Yes | Via env |
| Migration analysis | No | No | No | No | Yes |

## Recommendation

### Phased approach

| Phase | Action | Rationale |
|-------|--------|-----------|
| **1. Pilot** | `awslabs.mysql-mcp-server` in read-only mode | Works for both local (`--hostname localhost:3306`) and Aurora (`--resource_arn` or `--hostname`). One server, two connection modes. |
| **2. Harden** | Fix string interpolation in ptek-eng-toolbox DB tools | Parameterize inputs, allowlist table/schema names, redact errors. Must happen before adding query execution to toolbox. |
| **3. Decide** | Consolidate or keep separate | After hardening, decide whether to add query execution to toolbox (single MCP server) or keep awslabs as the query layer. |

### For local dev specifically

- awslabs server works via `--hostname` mode against port-forwarded `mysqldev`
- No AWS auth needed for local — just direct MySQL connection
- Consider read-only even locally to prevent accidental writes to golden data

### For Aurora/RDS (dev/staging/prod)

- Use awslabs with IAM + Secrets Manager
- Create a dedicated `mcp_readonly` MySQL user with `GRANT SELECT` only
- Exclude PHI tables from accessible schema where possible
- Enable Aurora audit logging independently
- Connect through private subnets / VPC endpoints

## HIPAA Security Notes

MCP server read-only modes have had SQL injection bypasses ([Datadog disclosure](https://securitylabs.datadoghq.com/articles/mcp-vulnerability-case-study-SQL-injection-in-the-postgresql-mcp-server/), [Aurora DSQL disclosure](https://medium.com/@michael.kandelaars/sql-injection-vulnerability-in-the-aws-aurora-dsql-mcp-server-b00eea7c85d9)). Never rely on MCP-level read-only as the security boundary:

1. Enforce read-only at the **database user level** (`GRANT SELECT` only)
2. Never store credentials in `.mcp.json` — use env vars from secrets manager
3. Network isolation (VPC, security groups) as primary enforcement
4. Audit query logs independently of MCP server
5. Exclude PHI-containing tables from agent-accessible schemas

## Example Configurations

### Local dev (port-forwarded mysqldev)

```json
{
  "mcpServers": {
    "mysql-local": {
      "command": "uvx",
      "args": [
        "awslabs.mysql-mcp-server@latest",
        "--hostname", "127.0.0.1",
        "--username", "root",
        "--password", "password",
        "--database", "global",
        "--readonly", "True"
      ]
    }
  }
}
```

### Aurora/RDS (via Secrets Manager)

```json
{
  "mcpServers": {
    "mysql-aurora": {
      "command": "uvx",
      "args": [
        "awslabs.mysql-mcp-server@latest",
        "--hostname", "<cluster-endpoint>",
        "--secret_arn", "arn:aws:secretsmanager:<region>:<account>:secret:<name>",
        "--database", "<db>",
        "--region", "<region>",
        "--readonly", "True"
      ],
      "env": { "AWS_PROFILE": "<profile>" }
    }
  }
}
```

### Alongside ptek-eng-toolbox

```json
{
  "mcpServers": {
    "mysql-local": {
      "command": "uvx",
      "args": ["awslabs.mysql-mcp-server@latest", "--hostname", "127.0.0.1", "--username", "root", "--password", "password", "--database", "global", "--readonly", "True"]
    },
    "ptek-eng-toolbox": {
      "command": "node",
      "args": ["/Users/martinburch/repos/ptek-eng-toolbox/dist/index.js", "--p", "database"]
    }
  }
}
```

## Open Questions

- [ ] Does mcp-electron need `uvx` executable support for AWS servers?
- [ ] Should `postgresdev` get the same treatment (`awslabs.postgres-mcp-server`)?
- [ ] What tables/schemas should be excluded from agent access in non-local environments?
- [ ] Should ptek-eng-toolbox query execution be a separate tool or extend existing tools?

## Sources

- [awslabs/mcp GitHub](https://github.com/awslabs/mcp)
- [awslabs mysql-mcp-server on PyPI](https://pypi.org/project/awslabs.mysql-mcp-server/) (v1.0.15)
- [awslabs postgres-mcp-server on PyPI](https://pypi.org/project/awslabs.postgres-mcp-server/) (v1.0.17)
- [bytebase/dbhub](https://github.com/bytebase/dbhub)
- [benborla/mcp-server-mysql](https://github.com/benborla/mcp-server-mysql)
- [cnosuke/mcp-mysql](https://github.com/cnosuke/mcp-mysql)
- [Datadog MCP SQL Injection Case Study](https://securitylabs.datadoghq.com/articles/mcp-vulnerability-case-study-SQL-injection-in-the-postgresql-mcp-server/)
- [AWS RDS Data API Limitations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.limitations.html)
- [MCP Security Best Practices](https://modelcontextprotocol.io/docs/learn/security-best-practices)
