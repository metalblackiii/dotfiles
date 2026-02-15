---
name: database-optimizer
description: Use when optimizing database performance, planning Aurora migrations, troubleshooting slow Sequelize queries, designing indexes, or analyzing query execution plans in MySQL/Aurora/PostgreSQL
---

# Database Optimizer

Database performance specialist for multi-tenant Node.js applications using Sequelize. Covers MySQL/Aurora (primary) and PostgreSQL (warehouse pipelines). Focuses on query optimization, indexing strategy, ORM pitfalls, and engine-specific capabilities.

## When to Use

- Optimizing slow queries or Sequelize operations
- Planning or executing MySQL RDS to Aurora migration
- Designing indexes for new tables or features
- Troubleshooting N+1 queries, eager loading issues, or ORM-generated SQL
- Analyzing EXPLAIN output and query execution plans
- Evaluating Aurora features (reader endpoints, parallel query, fast failover)

## Core Workflow

1. **Profile** — Identify slow queries via slow query log, Datadog APM, or `EXPLAIN ANALYZE`. Get the actual SQL Sequelize generates.
2. **Analyze** — Read the execution plan. Look for full table scans, filesorts, temporary tables, and join buffer usage.
3. **Optimize** — Apply fixes in order: indexing → query rewrite → schema change → caching. Prefer the least invasive fix.
4. **Validate** — Benchmark with production-scale data. Compare EXPLAIN before/after. Verify no regression on other queries hitting the same tables.
5. **Monitor** — Set up alerts for query duration thresholds. Track p95/p99 latency, not just averages.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| MySQL & Aurora | `references/mysql-aurora.md` | Aurora migration, reader/writer endpoints, Aurora-specific features |
| Sequelize Patterns | `references/sequelize-optimization.md` | ORM pitfalls, N+1, eager loading, raw queries, transaction patterns |
| Index Strategies | `references/index-strategies.md` | Composite indexes, covering indexes, InnoDB clustering, index design |
| PostgreSQL | `references/postgresql.md` | Postgres-specific optimization, EXPLAIN differences, GIN/BRIN indexes, analytics patterns |

## Constraints

### MUST DO
- Always check the SQL that Sequelize actually generates (`logging: console.log`)
- Use `EXPLAIN ANALYZE` (MySQL 8.0.18+) for actual execution statistics
- Consider multi-tenant implications — indexes must perform across all tenant data volumes
- Account for Aurora reader endpoint for read-heavy queries
- Test index changes against write performance, not just reads
- Use transactions appropriately — Sequelize `managed` transactions preferred

### MUST NOT DO
- Optimize queries without seeing the EXPLAIN output first
- Add indexes blindly — every index slows writes and consumes storage
- Use Sequelize `.findAll()` without limits on unbounded result sets
- Ignore the ORM layer — always check what SQL is generated
- Assume MySQL RDS behavior equals Aurora behavior (buffer pool, I/O, failover differ)
- Skip testing with production-scale data volumes

## Related Skills

- **sql-pro** — for complex query writing (CTEs, window functions, schema design)
- **neb-ms-conventions** — for how database access works in neb services (`req.db`, models)
