# MySQL & Aurora

## MySQL 8 Fundamentals

### InnoDB Storage Engine

All optimization assumes InnoDB (the MySQL 8 default):

- **Clustered index**: Data stored in primary key order. PK lookups are fastest.
- **Buffer pool**: In-memory cache of data and index pages. Size it to 70-80% of available memory.
- **MVCC**: Multi-version concurrency control for consistent reads without locking.
- **Row-level locking**: Locks individual rows, not pages or tables.

### EXPLAIN Output — What to Look For

```sql
EXPLAIN ANALYZE SELECT * FROM Appointment WHERE tenantId = ? AND date > ?;
```

| Column | Red Flag | Action |
|--------|----------|--------|
| `type` | `ALL` (full table scan) | Add index on filter columns |
| `type` | `index` (full index scan) | Index exists but not selective enough |
| `rows` | Much larger than result set | Index not covering the query |
| `Extra` | `Using filesort` | Add index matching ORDER BY |
| `Extra` | `Using temporary` | Simplify GROUP BY or add covering index |
| `Extra` | `Using where` with large row estimate | Index not filtering enough rows |

**Target**: `type` should be `ref`, `eq_ref`, or `range`. `rows` should be close to actual result count.

### Key MySQL 8 Features for Optimization

- **Descending indexes**: `CREATE INDEX idx ON table (col DESC)` — eliminates reverse scans
- **Functional indexes**: `CREATE INDEX idx ON table ((YEAR(created_at)))` — index computed values
- **Common Table Expressions**: Recursive CTEs for hierarchical data
- **Window functions**: Analytics without self-joins
- **JSON support**: `JSON_EXTRACT`, generated columns for indexing JSON fields

## Aurora-Specific Considerations

### Architecture Differences from RDS MySQL

Aurora uses a fundamentally different storage architecture:

| Aspect | RDS MySQL | Aurora MySQL |
|--------|-----------|-------------|
| Storage | EBS volumes | Distributed storage (6 copies across 3 AZs) |
| Replication | Binlog-based async | Storage-level sync |
| Failover | ~60-120s (DNS propagation) | ~30s (writer endpoint reroutes) |
| Read replicas | Async, seconds of lag | Typically <100ms lag |
| Storage scaling | Manual (resize EBS) | Automatic (grows in 10GB increments) |
| Backup | Snapshots to S3 | Continuous, point-in-time restore |

### Aurora Reader Endpoints

Aurora provides built-in read/write splitting:

- **Cluster endpoint** (writer): All writes, also serves reads
- **Reader endpoint**: Load-balances across read replicas
- **Custom endpoints**: Target specific replicas

**When to use reader endpoints**:
- Reports and analytics queries
- Read-heavy API endpoints that tolerate slight lag (<100ms)
- Bulk data exports

**When NOT to use reader endpoints**:
- Read-after-write scenarios (user creates then immediately views)
- Transactions that mix reads and writes
- Any operation where stale data causes incorrect behavior

### Aurora Parallel Query

For analytical queries scanning large datasets:

```sql
-- Check if parallel query is being used
EXPLAIN SELECT /*+ SET_VAR(aurora_pq=1) */ ...
```

Best for: Full table scans on large tables, aggregations, reports
Not useful for: Point lookups, small result sets, OLTP queries

### Aurora-Specific Performance Considerations

1. **Buffer pool warmup**: Aurora restores buffer pool from cluster storage on restart — faster than RDS MySQL cold starts
2. **I/O optimization**: Aurora's distributed storage means fewer I/O bottlenecks, but network latency replaces disk latency
3. **Connection overhead**: Use connection pooling aggressively — Aurora handles more concurrent connections than RDS but each still has overhead
4. **Storage I/O cost**: Aurora charges per I/O request. Reducing full table scans saves money, not just time.

## Migration from RDS MySQL to Aurora

### What Changes

- **Connection strings**: Update to Aurora cluster endpoint (writer) and reader endpoint
- **Failover behavior**: Faster, but application must handle connection drops gracefully
- **Parameter groups**: Aurora uses cluster parameter groups — some MySQL params don't apply
- **Monitoring**: Aurora CloudWatch metrics differ from RDS (e.g., `AuroraReplicaLag` replaces `ReplicaLag`)

### What Doesn't Change

- **SQL syntax**: Same MySQL 8 SQL
- **Sequelize usage**: Same adapter (`mysql2`), same models, same queries
- **Schema**: No migration needed
- **Application code**: Mostly unchanged (connection string swap)

### Migration Testing Checklist

1. **Query performance**: Run slow query log comparison between RDS and Aurora
2. **Failover handling**: Test application behavior during writer failover
3. **Read replica lag**: Measure actual lag for your workload
4. **Connection pooling**: Verify pool settings work with Aurora's connection limits
5. **Parameter groups**: Audit custom MySQL parameters for Aurora compatibility
6. **Backup/restore**: Verify point-in-time restore works as expected
