# Migration Playbook

## Pre-Migration: The Audit

Before writing any migration code, build a complete inventory.

### Audit Checklist

1. **Find every call site** of the legacy API (e.g., `hasAddOn`, `hasFeatureOrBeta` used for entitlements, tier checks)
2. **Categorize each site** by migration type
3. **Map dependencies** — which call sites block others?
4. **Estimate effort** per category, not per site
5. **Identify the blast radius** — what breaks if a migration is wrong?

### Migration Type Categories

| Type | Description | Risk | Example |
|------|-------------|------|---------|
| **Mechanical** | 1:1 mapping, swap function name and key | Low | `hasAddOn('ct-informs')` → `hasEntitlement('patient-intake-forms')` |
| **N:1 Mapping** | Multiple old checks collapse into one new check | Low-Medium | `hasAddOn('ct-engage') \|\| hasAddOn('ct-remind')` → `hasEntitlement('patient-engagement')` |
| **Logic Change** | The check logic itself changes, not just the function | Medium | Tier-based checks (`tier === 'Advanced'`) → entitlement checks |
| **Architecture Change** | The surrounding pattern needs redesign | High | Object-based configs (`addOnsSupport: { verify: true }`) → individual checks |
| **Redesign** | The entire component/flow needs rethinking | High | Practice package selector → GBB tier selector |

## Migration Execution

### One PR Per Logical Group

Group related call sites into a single PR. Good grouping:

- All call sites for one entitlement (e.g., all `ct-verify` → `real-time-eligibility`)
- All call sites in one component (if they're tightly coupled)

Bad grouping:
- All mechanical replacements in one mega-PR (too large to review, too risky to revert)
- Mixing different entitlements in one PR (conflates separate concerns)

### PR Structure for Migration

Each migration PR should contain:

```
Title: migrate: replace hasAddOn('ct-verify') with hasEntitlement('real-time-eligibility')

Files changed:
  - src/components/eligibility/neb-eligibility-check.js (3 sites)
  - src/components/billing/neb-claim-form.js (1 site)

Testing:
  - [x] PHX_GBB_ENTITLEMENTS=off: behavior unchanged (passthrough)
  - [x] PHX_GBB_ENTITLEMENTS=on, entitlement present: feature accessible
  - [x] PHX_GBB_ENTITLEMENTS=on, entitlement absent: feature gated
```

### Call Site Migration Patterns

**Mechanical (1:1)**:
```javascript
// Before
if (hasAddOn(CT_VERIFY)) { ... }

// After
if (hasEntitlement(ENTITLEMENTS.REAL_TIME_ELIGIBILITY)) { ... }
```

**N:1 Mapping**:
```javascript
// Before
if (hasAddOn(CT_ENGAGE) || hasAddOn(CT_REMIND)) { ... }

// After
if (hasEntitlement(ENTITLEMENTS.PATIENT_ENGAGEMENT)) { ... }
```

**Tier-based to Entitlement**:
```javascript
// Before
if (tenant.tier === 'Advanced') { ... }

// After
if (hasEntitlement(ENTITLEMENTS.ELECTRONIC_CLAIMS)) { ... }
```

**Object config pattern**:
```javascript
// Before
const config = {
  addOnsSupport: {
    verify: hasAddOn(CT_VERIFY),
    engage: hasAddOn(CT_ENGAGE),
  }
};

// After — flatten to individual checks
const canVerify = hasEntitlement(ENTITLEMENTS.REAL_TIME_ELIGIBILITY);
const canEngage = hasEntitlement(ENTITLEMENTS.PATIENT_ENGAGEMENT);
```

## Tracking Progress

Maintain a migration inventory with status:

| Call Site | Legacy API | New API | Type | Status |
|-----------|-----------|---------|------|--------|
| `neb-eligibility-check.js:42` | `hasAddOn(CT_VERIFY)` | `hasEntitlement(REAL_TIME_ELIGIBILITY)` | Mechanical | Done |
| `neb-claim-form.js:108` | `tier === 'Advanced'` | `hasEntitlement(ELECTRONIC_CLAIMS)` | Logic change | In progress |

Track overall metrics:
- Total call sites: N
- Migrated: X
- Remaining: Y
- Blocked: Z (and by what)

## Backend Migration Considerations

Backend services have their own call sites and may need different migration timing:

- Frontend and backend migrations can be independent — they check different things
- Backend services may need the entitlement utility as a shared package
- Service-to-service calls may need entitlement context passed via headers or params
- Backend rollback is the same pattern: feature flag → passthrough to legacy
