# Sequelize Optimization

## Seeing the SQL

Always check what Sequelize generates before optimizing:

```javascript
// Per-query logging
const results = await db.Appointment.findAll({
  where: { tenantId },
  logging: console.log,  // prints generated SQL
});

// Or globally in Sequelize config
new Sequelize(uri, { logging: console.log });
```

## Common Sequelize Performance Pitfalls

### N+1 Queries

The most common ORM performance problem:

```javascript
// BAD: N+1 — one query per patient
const appointments = await db.Appointment.findAll({ where: { tenantId } });
for (const appt of appointments) {
  appt.patient = await db.Patient.findByPk(appt.patientId);  // N queries
}

// GOOD: Eager loading — single JOIN
const appointments = await db.Appointment.findAll({
  where: { tenantId },
  include: [{ model: db.Patient, as: 'patient' }],
});

// GOOD: Batch loading — two queries total
const appointments = await db.Appointment.findAll({ where: { tenantId } });
const patientIds = [...new Set(appointments.map(a => a.patientId))];
const patients = await db.Patient.findAll({
  where: { id: patientIds },
});
const patientMap = new Map(patients.map(p => [p.id, p]));
appointments.forEach(a => { a.patient = patientMap.get(a.patientId); });
```

### Unbounded Queries

```javascript
// BAD: No limit — could return millions of rows
const all = await db.Charge.findAll({ where: { tenantId } });

// GOOD: Always paginate
const page = await db.Charge.findAll({
  where: { tenantId },
  limit: 100,
  offset: 0,
});
```

### Over-Fetching Columns

```javascript
// BAD: Fetches all columns including large text/blob fields
const patients = await db.Patient.findAll({ where: { tenantId } });

// GOOD: Select only needed columns
const patients = await db.Patient.findAll({
  where: { tenantId },
  attributes: ['id', 'firstName', 'lastName', 'dateOfBirth'],
});
```

### Inefficient Includes

```javascript
// BAD: Deep nested includes with no column limits
const appointments = await db.Appointment.findAll({
  include: [
    { model: db.Patient, include: [
      { model: db.Insurance, include: [
        { model: db.Carrier }
      ]}
    ]},
    { model: db.Provider },
    { model: db.Location },
  ],
});

// GOOD: Limit depth, select columns, consider separate queries
const appointments = await db.Appointment.findAll({
  attributes: ['id', 'date', 'patientId', 'providerId'],
  include: [
    { model: db.Patient, attributes: ['id', 'firstName', 'lastName'] },
  ],
});
// Fetch insurance separately only when needed
```

## When to Use Raw Queries

Use raw SQL when Sequelize's query builder produces suboptimal SQL:

```javascript
// Complex aggregations
const results = await db.sequelize.query(`
  SELECT
    DATE(a.date) AS appointmentDate,
    COUNT(*) AS total,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) AS completed
  FROM Appointment a
  WHERE a.tenantId = :tenantId
    AND a.date BETWEEN :start AND :end
  GROUP BY DATE(a.date)
  ORDER BY appointmentDate
`, {
  replacements: { tenantId, start, end },
  type: db.Sequelize.QueryTypes.SELECT,
});
```

**Use raw queries for**: Complex aggregations, multi-table updates, CTEs, window functions, performance-critical queries
**Use Sequelize for**: CRUD operations, simple queries, queries that benefit from model associations

## Transaction Patterns

```javascript
// GOOD: Managed transaction (auto-commit/rollback)
await db.sequelize.transaction(async (transaction) => {
  await db.Charge.create(chargeData, { transaction });
  await db.Ledger.create(ledgerEntry, { transaction });
});

// BAD: Unmanaged transaction (easy to forget commit/rollback)
const t = await db.sequelize.transaction();
try {
  await db.Charge.create(chargeData, { transaction: t });
  await t.commit();
} catch (e) {
  await t.rollback();
  throw e;
}
```

## Multi-Tenant Considerations

With tenant-scoped connections (`req.db`):

- **Always filter by tenantId** — even with scoped connections, defense in depth
- **Index tenantId first** in composite indexes — it's in almost every WHERE clause
- **Test with multiple tenant sizes** — a query fast for small tenants may be slow for large ones
- **Connection pool per tenant** — be aware of total connection count across all tenants
