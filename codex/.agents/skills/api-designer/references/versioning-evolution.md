# API Versioning & Evolution

## Versioning Strategy

### URL Path Versioning (Current Convention)

```
/api/v1/tenants/:tenantId/patients
/api/v2/tenants/:tenantId/patients     ← breaking change
```

This is the established pattern across neb services. New versions get new directory paths:

```
src/controllers/api/v1/tenants/:tenantId/patients/get.js
src/controllers/api/v2/tenants/:tenantId/patients/get.js
```

### When to Bump the Version

| Change Type | Version Bump? | Example |
|-------------|:------------:|---------|
| Add optional field to response | No | Adding `entitlements` to tenant response |
| Add optional query parameter | No | Adding `?includeLegacy=true` |
| Add new endpoint | No | `GET /api/v1/tenants/:id/entitlements` |
| Remove field from response | **Yes** | Dropping `addOns` from tenant response |
| Rename field | **Yes** | `tier` → `productTier` |
| Change field type | **Yes** | `tier: string` → `tier: object` |
| Change validation rules (stricter) | **Yes** | Making `email` required when it was optional |
| Change response status code | **Yes** | 200 → 201 for creation |
| Change authentication requirements | **Yes** | Adding new required permission |

### The Additive Rule

If you can make the change additive (add without removing), don't version. This is almost always the better path:

```javascript
// Instead of renaming tier → productTier (breaking):
// Add productTier alongside tier (additive)
{
  "tier": "Advanced",           // legacy — keep for existing consumers
  "productTier": "better",      // new — added alongside
  "insuranceTier": "good",      // new — added alongside
}
```

Deprecate the old field in documentation, remove in a future version bump.

## Managing Multiple Versions

### Shared Logic Pattern

Versions should share business logic and only differ at the controller/formatter layer:

```
src/
  controllers/
    api/
      v1/tenants/:tenantId/patients/get.js  → uses v1 formatter
      v2/tenants/:tenantId/patients/get.js  → uses v2 formatter
  services/
    patient-service.js                       → shared business logic
  formatters/
    patient-formatter-v1.js
    patient-formatter-v2.js
```

**Never duplicate business logic between versions.** Only the request schema (validation) and response formatter should differ.

### Version Lifecycle

```
v1: Active   → Deprecated → Sunset → Removed
v2: Active   → ...
```

1. **Active**: Fully supported, receives bug fixes
2. **Deprecated**: Works but documented as "use v2 instead". Set `Deprecation` header.
3. **Sunset**: Read-only notice period. Logs warnings when called.
4. **Removed**: Returns 410 Gone

### Deprecation Headers

```javascript
// In deprecated endpoint handler
res.set('Deprecation', 'true');
res.set('Sunset', 'Sat, 01 Mar 2025 00:00:00 GMT');
res.set('Link', '</api/v2/tenants/:id/patients>; rel="successor-version"');
```

## Breaking Changes Checklist

Before making a breaking change:

1. **Is there an additive alternative?** (Usually yes — try harder)
2. **Who consumes this endpoint?** (Frontend only? Other services? External partners?)
3. **Can consumers migrate before the old version is removed?**
4. **Is the new version backward-compatible with existing data?**

## Cross-Service Version Coordination

When service A calls service B:

- **Pin to specific version**: `GET ${NEB_REGISTRY_API_URL}/api/v2/tenants/${id}`
- **Don't auto-follow redirects** to new versions — explicit is safer
- **API client modules** (`src/api-clients/`) should document which version they target
- **Coordinate version bumps**: If B bumps to v3, A's api-client must be updated in the same release

## Entitlement-Aware Versioning

When adding entitlement gates to existing endpoints:

```javascript
// Adding entitlement check to existing endpoint is NOT a breaking change
// if gated by feature flag with passthrough default
export default {
  handler: async (req, res) => {
    // New: entitlement check (passthrough when flag off)
    if (!await hasEntitlement(req.tenantId, 'real-time-eligibility')) {
      return res.status(403).json({ error: 'Entitlement required' });
    }
    // ... existing logic
  },
};
```

**However**: Returning 403 where 200 was previously returned IS a behavior change for affected tenants. Gate this behind the feature flag so it only applies to GBB tenants.
