---
name: database-expert
description: Use when writing SQL queries, optimizing database performance, designing schemas, planning Aurora migrations, troubleshooting Sequelize queries, designing indexes, or analyzing execution plans. Covers SQL language, ORM patterns, and engine-specific optimization for MySQL/Aurora/PostgreSQL.
---

# Database Expert

Database specialist for multi-tenant Node.js applications using Sequelize. Covers SQL query design (CTEs, window functions, recursive queries), performance optimization, indexing strategy, ORM pitfalls, and engine-specific capabilities across MySQL/Aurora (primary) and PostgreSQL (warehouse pipelines).

## When to Use

- Writing complex SQL — CTEs, window functions, recursive queries, joins
- Optimizing slow queries or Sequelize operations
- Designing database schemas, indexes, and migrations
- Planning or executing MySQL RDS to Aurora migration
- Troubleshooting N+1 queries, eager loading issues, or ORM-generated SQL
- Analyzing EXPLAIN output and query execution plans
- Evaluating Aurora features (reader endpoints, parallel query, fast failover)

## Core Workflow

1. **Profile** — Identify slow queries via slow query log, Datadog APM, or `EXPLAIN ANALYZE`. Get the actual SQL Sequelize generates.
2. **Analyze** — Read the execution plan. Look for full table scans, filesorts, temporary tables, and join buffer usage. Review schema and index coverage.
3. **Design** — Create set-based operations using CTEs, window functions, appropriate joins. Apply filtering early in query execution.
4. **Optimize** — Apply fixes in order: indexing → query rewrite → schema change → caching. Prefer the least invasive fix.
5. **Validate** — Benchmark with production-scale data. Compare EXPLAIN before/after. Verify no regression on other queries hitting the same tables.
6. **Monitor** — Set up alerts for query duration thresholds. Track p95/p99 latency, not just averages.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Query Patterns | `references/query-patterns.md` | JOINs, CTEs, subqueries, recursive queries |
| Window Functions | `references/window-functions.md` | ROW_NUMBER, RANK, LAG/LEAD, analytics |
| SQL Optimization | `references/optimization.md` | EXPLAIN plans, statistics, query tuning |
| Database Design | `references/database-design.md` | Normalization, keys, constraints, schemas |
| Dialect Differences | `references/dialect-differences.md` | PostgreSQL vs MySQL vs SQL Server specifics |
| MySQL & Aurora | `references/mysql-aurora.md` | Aurora migration, reader/writer endpoints, Aurora-specific features |
| Sequelize Patterns | `references/sequelize-optimization.md` | ORM pitfalls, N+1, eager loading, raw queries, transaction patterns |
| Index Strategies | `references/index-strategies.md` | Composite indexes, covering indexes, InnoDB clustering, index design |
| PostgreSQL | `references/postgresql.md` | Postgres-specific optimization, EXPLAIN differences, GIN/BRIN indexes |

## Constraints

### MUST DO
- Analyze execution plans before optimization
- Always check the SQL that Sequelize actually generates (`logging: console.log`)
- Use `EXPLAIN ANALYZE` (MySQL 8.0.18+) for actual execution statistics
- Use set-based operations over row-by-row processing
- Apply filtering early in query execution
- Use EXISTS over COUNT for existence checks
- Handle NULLs explicitly
- Create covering indexes for frequent queries
- Consider multi-tenant implications — indexes must perform across all tenant data volumes
- Account for Aurora reader endpoint for read-heavy queries
- Test index changes against write performance, not just reads
- Test with production-scale data volumes
- Use transactions appropriately — Sequelize `managed` transactions preferred

### MUST NOT DO
- Use SELECT * in production queries
- Optimize queries without seeing the EXPLAIN output first
- Add indexes blindly — every index slows writes and consumes storage
- Use Sequelize `.findAll()` without limits on unbounded result sets
- Ignore the ORM layer — always check what SQL is generated
- Use cursors when set-based operations work
- Skip NULL handling in comparisons
- Assume MySQL RDS behavior equals Aurora behavior (buffer pool, I/O, failover differ)

## Related Skills

- **neb-ms-conventions** — for how database access works in neb services (`req.db`, models)
