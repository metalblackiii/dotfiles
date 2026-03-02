# Strangler Fig Pattern

## The Pattern

Replace a legacy system incrementally by building a new system around it. The new system starts by delegating to the old one, then gradually takes over until the old system can be removed.

```
Phase 1: Facade delegates to legacy
  Caller → hasEntitlement() → hasAddOn() → TenantAddOn table

Phase 2: Facade routes by tenant type
  GBB Tenant  → hasEntitlement() → FeatureOptIn (entl: records)
  Legacy Tenant → hasEntitlement() → hasAddOn() → TenantAddOn table

Phase 3: All tenants migrated, legacy removed
  Caller → hasEntitlement() → FeatureOptIn (entl: records)
```

## When to Apply

The strangler fig is the right pattern when:
- The legacy system works — it doesn't need a rewrite, it needs replacement
- You can identify a clean API boundary to wrap (a function, an endpoint, a table)
- You need to migrate incrementally without downtime
- Different tenants/users can be on different systems simultaneously

## Building the Facade

The facade is the single most important piece. It must:

1. **Match the legacy API's semantics exactly** — callers should not need to change behavior
2. **Be approach-agnostic** — the internal routing (legacy vs new) is hidden from callers
3. **Support both paths simultaneously** — legacy and new must coexist

```javascript
// Good facade: callers don't know which path they're on
export async function hasEntitlement(entitlementKey) {
  if (isGBBTenant()) {
    return checkEntitlementRecord(entitlementKey);  // new path
  }
  return legacyCheck(entitlementKey);  // old path
}

// Bad: leaking implementation details to callers
export async function hasEntitlement(entitlementKey, useLegacy = false) { ... }
```

## Routing Strategies

How to decide which path a caller takes:

| Strategy | Mechanism | Tradeoff |
|----------|-----------|----------|
| **Feature flag per-tenant** | `hasFeature('PHX_GBB_ENTITLEMENTS')` | Explicit control, manual per-tenant |
| **Presence of new data** | `if (tenant.productTier)` or `if (entl: records exist)` | Automatic, but fragile if data is partial |
| **Explicit migration flag** | `tenant.isGBB = true` | Clear intent, requires schema change |
| **Date-based cutover** | All tenants created after X use new path | Simple, but can't control existing tenants |

**Recommended**: Feature flag per-tenant. Gives explicit rollout control, per-tenant rollback, and a clear "this tenant is on the new system" signal.

## Migration Ordering

Migrate in this order for safety:

1. **Mechanical replacements first** — call sites where the old and new API have 1:1 mapping. Lowest risk, highest volume.
2. **Logic changes second** — call sites where the mapping requires conditional logic (e.g., 2 old add-ons → 1 new entitlement).
3. **Architecture changes last** — call sites where the entire pattern needs redesign (e.g., `addOnsSupport` object pattern → individual checks).

## Rollback Safety

Every phase must be independently reversible:

| Phase | Rollback Mechanism |
|-------|-------------------|
| Facade built, no callers migrated | Remove facade — no impact |
| Some callers migrated | Revert call site PRs — facade passthrough restores old behavior |
| All callers migrated, legacy code present | Disable feature flag — facade routes back to legacy |
| Legacy code removed | **Not reversible** — this is the point of no return |

**Never remove legacy code until**:
- All callers are on the new path
- The new path has been validated in production for a meaningful period
- You have explicit confirmation that rollback to legacy is no longer needed

## Anti-Patterns

| Anti-Pattern | Why It Fails |
|-------------|-------------|
| **Big-bang switchover** | One flag flips everything; failure affects all tenants |
| **Dual-write to both systems** | Consistency bugs, doubled complexity, neither system is source of truth |
| **Facade that modifies behavior** | Callers can't trust the migration is safe |
| **Migrating callers before the facade is stable** | Moving target — facade changes break already-migrated callers |
| **Skipping the audit** | You don't know how many call sites exist, so you can't track progress |
