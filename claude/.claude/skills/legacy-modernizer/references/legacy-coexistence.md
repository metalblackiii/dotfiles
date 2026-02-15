# Legacy Coexistence

## The Dual-Mode Problem

During migration, two systems run simultaneously. Every check must produce correct results for both legacy and new tenants. This is the hardest part of incremental migration.

## Coexistence Strategies

### Strategy 1: Feature Flag Gate (Recommended)

A per-tenant feature flag controls which path the facade takes.

```javascript
async function hasEntitlement(key) {
  const gbbEnabled = hasFeatureOrBeta('PHX_GBB_ENTITLEMENTS');

  if (!gbbEnabled) return true;  // passthrough — legacy behavior unaffected

  return checkEntitlementRecord(key);  // GBB path
}
```

**Pros**: Explicit control, per-tenant rollback, clear signal
**Cons**: Passthrough returns `true` for everything (permissive default)

**When passthrough is dangerous**: If "passthrough returns true" means a legacy tenant suddenly sees features they shouldn't have, the passthrough default is wrong. Consider returning the legacy system's answer instead:

```javascript
if (!gbbEnabled) return legacyCheck(key);  // delegate to old system
```

### Strategy 2: Data-Driven Routing

The presence of new-system data determines routing.

```javascript
function hasEntitlement(key) {
  if (tenant.productTier) {
    return resolveTierEntitlements(tenant).includes(key);  // GBB
  }
  return legacyHasEntitlement(tenant, key);  // Legacy
}
```

**Pros**: No flag to manage, automatic routing
**Cons**: Partial data causes undefined behavior, harder to roll back

### Strategy 3: Time-Based Cutover

All tenants created after a date use the new system.

**Pros**: Simple, no per-tenant management
**Cons**: Can't migrate existing tenants, can't roll back individual tenants

## The Legacy Mapping Table

When the facade delegates to the legacy system, it needs a mapping from new concepts to old concepts:

```javascript
const LEGACY_MAPPINGS = {
  'real-time-eligibility': (tenant) => hasAddOn(tenant, 'ct-verify'),
  'patient-engagement':    (tenant) => hasAddOn(tenant, 'ct-engage') || hasAddOn(tenant, 'ct-remind'),
  'patient-intake-forms':  (tenant) => hasAddOn(tenant, 'ct-informs'),
  'electronic-claims':     (tenant) => tenant.tier === 'Advanced',
  'multi-location':        (tenant) => tenant.tier === 'Advanced',
};
```

This mapping is the bridge between the two worlds. Keep it:
- **Explicit** — every entitlement that exists in the new system has a legacy equivalent
- **Tested** — unit test each mapping against known legacy tenant configurations
- **Temporary** — this code is deleted when legacy support ends

## Dual-Gating: Feature Flags + Entitlements

When a new feature ships simultaneously with the new entitlement system, it needs two gates:

```javascript
// Is the code ready? (engineering rollout)
const codeReady = hasFeatureOrBeta('ai-charting-automation');

// Did they pay for it? (billing entitlement)
const hasPaid = hasEntitlement(ENTITLEMENTS.AI_CHARTING_AUTOMATION);

// Both must pass
const canAccess = codeReady && hasPaid;
```

**The risk**: Developers conflate the two checks, or forget one.

**Guidelines**:
- Keep the two checks visibly separate in code — resist combining into a helper
- Comment which check is which: `// engineering gate` vs `// entitlement gate`
- Feature flags are temporary (removed after rollout); entitlements are permanent
- A feature should go through: flag-only → flag+entitlement → entitlement-only

## Rollback Patterns

### Per-Tenant Rollback

Disable the GBB flag for a specific tenant → facade reverts to legacy path for that tenant only. No code change, no deploy.

### Per-Feature Rollback

Revert the migration PR for a specific entitlement → that call site goes back to the legacy check. Other migrated call sites are unaffected.

### Full System Rollback

Disable the GBB flag globally → all tenants use legacy paths. The new system's data (entitlement records) is inert — it exists but is never read.

### Data Rollback

If the new system wrote data that the legacy system doesn't understand:
- Legacy fields should always be preserved during migration (don't delete `tier`, `addOns`)
- New fields/records can be ignored by the legacy path
- The new system should be additive, not destructive

## Grandfathering

Legacy tenants continue working unchanged until explicitly migrated:

1. **No behavior change** — legacy tenants never see new entitlement logic
2. **No forced migration** — migration happens on a schedule, not all at once
3. **No data loss** — legacy fields remain intact even after migration
4. **Clear end-of-life** — document when legacy support ends and communicate to stakeholders

## Testing Dual-Mode Systems

Every migration must be tested in all flag states:

| Scenario | Flag State | Expected Behavior |
|----------|-----------|-------------------|
| Legacy tenant, unmigrated call site | Off | Legacy behavior (unchanged) |
| Legacy tenant, migrated call site | Off | Legacy behavior (passthrough) |
| GBB tenant, migrated call site, has entitlement | On | Feature accessible |
| GBB tenant, migrated call site, lacks entitlement | On | Feature gated |
| GBB tenant, unmigrated call site | On | Depends on passthrough strategy |

The last scenario is the edge case that catches teams off guard — make sure your passthrough strategy handles it.
