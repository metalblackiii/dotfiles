# Index Strategies for MySQL/InnoDB

## InnoDB Index Fundamentals

### Clustered Index (Primary Key)

InnoDB stores data in primary key order. The PK _is_ the table:

- PK lookups are the fastest possible access path
- Use auto-increment `INT` or `BIGINT` for PKs — sequential inserts are fast
- UUID PKs cause random inserts → page splits → fragmentation → slow writes

### Secondary Indexes

Every secondary index stores the PK value at the leaf:

```
Index on (tenantId, date) actually stores: (tenantId, date, id)
```

This means:
- A secondary index lookup always requires a PK lookup to get the full row ("bookmark lookup")
- Small PKs = smaller secondary indexes = more fit in memory
- A covering index avoids the bookmark lookup entirely

## Composite Index Design

### The Left-Prefix Rule

A composite index `(A, B, C)` can be used for queries on:
- `WHERE A = ?`
- `WHERE A = ? AND B = ?`
- `WHERE A = ? AND B = ? AND C = ?`
- `WHERE A = ? AND B > ?` (range on B, C not used)

It CANNOT be used for:
- `WHERE B = ?` (skips A)
- `WHERE A = ? AND C = ?` (skips B — A is used, C is not)

### Column Ordering Rules

1. **Equality columns first** — columns compared with `=`
2. **Range column last** — the column used with `>`, `<`, `BETWEEN`, `IN`
3. **High-selectivity columns earlier** — `tenantId` first (always present), then the most selective filter

```sql
-- Query
WHERE tenantId = ? AND status = 'active' AND date > ?

-- Good index: equality first, range last
CREATE INDEX idx_tenant_status_date ON Appointment (tenantId, status, date);

-- Bad index: range column in middle kills the rest
CREATE INDEX idx_tenant_date_status ON Appointment (tenantId, date, status);
```

### The tenantId Rule

In multi-tenant tables, `tenantId` should almost always be the first column in every composite index:

```sql
-- Every query filters by tenant
CREATE INDEX idx_appt_tenant_date ON Appointment (tenantId, date);
CREATE INDEX idx_charge_tenant_patient ON Charge (tenantId, patientId);
CREATE INDEX idx_claim_tenant_status ON Claim (tenantId, status);
```

## Covering Indexes

A covering index includes all columns the query needs — no bookmark lookup required.

```sql
-- Query
SELECT id, date, status FROM Appointment WHERE tenantId = ? AND date > ?;

-- Covering index (all SELECT + WHERE columns)
CREATE INDEX idx_covering ON Appointment (tenantId, date, status);
-- InnoDB automatically includes PK (id), so this covers everything
```

`EXPLAIN` shows `Using index` in Extra when a covering index is used.

## Index Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Index on every column | Slows writes, wastes memory | Index for specific query patterns |
| Low-selectivity leading column | `WHERE isActive = 1` matches 95% of rows — useless | Move after high-selectivity columns |
| Redundant indexes | `(A)` and `(A, B)` both exist — `(A, B)` covers both | Drop the shorter one |
| Unused indexes | Index exists but no query uses it | Check `sys.schema_unused_indexes` |
| Too-wide indexes | Including large VARCHAR columns | Only include needed columns |
| Indexing for `LIKE '%suffix'` | Leading wildcard can't use B-tree index | Consider full-text index or app-level search |

## Index Maintenance

### Finding Unused Indexes (MySQL 8)

```sql
SELECT * FROM sys.schema_unused_indexes
WHERE object_schema = 'your_database';
```

### Finding Duplicate Indexes

```sql
SELECT * FROM sys.schema_redundant_indexes
WHERE table_schema = 'your_database';
```

### Index Size

```sql
SELECT
  table_name,
  index_name,
  ROUND(stat_value * @@innodb_page_size / 1024 / 1024, 2) AS size_mb
FROM mysql.innodb_index_stats
WHERE stat_name = 'size'
  AND database_name = 'your_database'
ORDER BY stat_value DESC;
```

## Sequelize Migration Example

```javascript
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.addIndex('Appointment', {
      fields: ['tenantId', 'date', 'status'],
      name: 'idx_appointment_tenant_date_status',
    });
  },
  down: async (queryInterface) => {
    await queryInterface.removeIndex('Appointment', 'idx_appointment_tenant_date_status');
  },
};
```

Always name indexes explicitly — Sequelize's auto-generated names are inconsistent across databases.
