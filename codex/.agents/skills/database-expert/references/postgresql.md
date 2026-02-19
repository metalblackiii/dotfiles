# PostgreSQL Optimization

## Key Differences from MySQL

If you're primarily a MySQL developer, these are the Postgres behaviors that will trip you up:

| Aspect | MySQL/InnoDB | PostgreSQL |
|--------|-------------|------------|
| Clustering | Data stored in PK order (clustered) | Heap table — rows in insertion order |
| MVCC cleanup | Undo log (automatic) | Dead tuples — needs VACUUM |
| Index types | B-tree only (mostly) | B-tree, Hash, GIN, GiST, BRIN, SP-GiST |
| EXPLAIN output | Estimated rows/cost | `EXPLAIN ANALYZE` gives actual time + rows |
| Case sensitivity | Case-insensitive by default (collation) | Case-sensitive by default |
| Sequences | AUTO_INCREMENT | `SERIAL` / `GENERATED ALWAYS AS IDENTITY` |
| JSON | `JSON` type, limited indexing | `JSONB` with GIN indexes, rich operators |
| CTEs | Optimized (inlined in MySQL 8) | Optimization fence before PG 12, inlined after |

## EXPLAIN ANALYZE

PostgreSQL's EXPLAIN is more informative than MySQL's:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM claims WHERE tenant_id = ? AND status = 'pending';
```

### What to Look For

| Indicator | Red Flag | Action |
|-----------|----------|--------|
| `Seq Scan` | Full table scan on large table | Add index |
| `actual rows` >> `rows` estimate | Bad statistics | Run `ANALYZE table_name` |
| `Buffers: shared read` high | Cold cache, lots of disk I/O | Check buffer pool size or add covering index |
| `Sort Method: external merge` | Sort spills to disk | Increase `work_mem` or add index matching ORDER BY |
| `Hash Join` on large tables | Memory-intensive | Consider indexed nested loop via better indexes |
| `actual loops` high | Inside a nested loop, repeated many times | Restructure query or add index to inner relation |

### Reading the Output

```
Nested Loop  (cost=0.57..8.62 rows=1 width=200) (actual time=0.025..0.028 rows=1 loops=1)
  →  Index Scan using idx_claim_tenant_status on claims  (actual time=0.015..0.016 rows=1 loops=1)
       Index Cond: (tenant_id = 42 AND status = 'pending')
  →  Index Scan using pk_patients on patients  (actual time=0.008..0.009 rows=1 loops=1)
       Index Cond: (id = claims.patient_id)
Planning Time: 0.150 ms
Execution Time: 0.050 ms
```

Key: `actual time=start..end` is in milliseconds. `rows=N` is actual rows returned. `loops=N` means the node executed N times (multiply time × loops for total).

## PostgreSQL-Specific Index Types

### Partial Indexes

Index only the rows you query:

```sql
-- Only index active claims (90% of queries filter on status)
CREATE INDEX idx_active_claims ON claims (tenant_id, created_at)
  WHERE status IN ('pending', 'in_progress');
```

Smaller index, faster writes, faster reads for the common case.

### Expression Indexes

Index computed values:

```sql
-- Index on lowercased email for case-insensitive lookup
CREATE INDEX idx_patient_email ON patients (LOWER(email));

-- Query must match the expression exactly
SELECT * FROM patients WHERE LOWER(email) = 'john@example.com';
```

### GIN Indexes (for JSONB and arrays)

```sql
-- Index JSONB column for containment queries
CREATE INDEX idx_metadata ON claims USING GIN (metadata jsonb_path_ops);

-- Query
SELECT * FROM claims WHERE metadata @> '{"source": "electronic"}';
```

### BRIN Indexes (for time-series / append-only data)

```sql
-- Tiny index for naturally-ordered data (timestamps, sequential IDs)
CREATE INDEX idx_claim_created ON claims USING BRIN (created_at);
```

BRIN indexes are 100x smaller than B-tree for time-series data. Only useful when the physical order of rows correlates with the indexed column.

## Analytics & Warehouse Patterns

### Materialized Views

Pre-compute expensive aggregations:

```sql
CREATE MATERIALIZED VIEW mv_monthly_claim_summary AS
SELECT
  tenant_id,
  DATE_TRUNC('month', service_date) AS month,
  COUNT(*) AS total_claims,
  SUM(amount) AS total_amount,
  COUNT(*) FILTER (WHERE status = 'paid') AS paid_claims
FROM claims
GROUP BY tenant_id, DATE_TRUNC('month', service_date);

-- Refresh on schedule (not automatic)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_claim_summary;
```

`CONCURRENTLY` allows reads during refresh but requires a unique index on the view.

### Partitioning

For very large tables (millions+ rows), partition by time or tenant:

```sql
CREATE TABLE claims (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  tenant_id INT NOT NULL,
  service_date DATE NOT NULL,
  ...
) PARTITION BY RANGE (service_date);

CREATE TABLE claims_2025_q1 PARTITION OF claims
  FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
```

**Partition pruning**: Queries with `WHERE service_date = '2025-02-15'` only scan the relevant partition.

### Window Functions for Analytics

```sql
-- Running totals and comparisons
SELECT
  tenant_id,
  month,
  total_claims,
  LAG(total_claims) OVER (PARTITION BY tenant_id ORDER BY month) AS prev_month,
  total_claims - LAG(total_claims) OVER (PARTITION BY tenant_id ORDER BY month) AS delta
FROM mv_monthly_claim_summary;
```

## VACUUM and Maintenance

PostgreSQL's MVCC leaves dead tuples that must be cleaned:

- **autovacuum** handles this automatically — don't disable it
- **VACUUM ANALYZE** after bulk loads or large deletes
- Monitor `n_dead_tup` in `pg_stat_user_tables` — if it grows unbounded, autovacuum is falling behind

```sql
-- Check autovacuum health
SELECT
  relname,
  n_live_tup,
  n_dead_tup,
  last_autovacuum,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;
```

## Connection Pooling

PostgreSQL forks a process per connection (heavier than MySQL threads). Use a connection pooler:

- **PgBouncer** (external pooler) — transaction or session mode
- **Sequelize pool** — built-in, but per-application-instance

For multi-tenant with many application instances, PgBouncer in front of Postgres prevents connection exhaustion.

## Sequelize with PostgreSQL

Most Sequelize patterns are identical to MySQL. Key differences:

```javascript
// PostgreSQL supports RETURNING (get created row without extra query)
const charge = await db.Charge.create(data, { returning: true });

// Array columns (PostgreSQL-only)
await queryInterface.addColumn('patients', 'tags', {
  type: Sequelize.ARRAY(Sequelize.STRING),
});

// JSONB columns with indexing
await queryInterface.addColumn('claims', 'metadata', {
  type: Sequelize.JSONB,
});
```
