# Migration Testing Patterns

Testing strategies for incremental migrations — ensuring behavior is preserved as code transitions from legacy to new implementation.

## Before/After Validation

The core pattern: run the same inputs through both old and new code paths, compare results.

### Dual-Path Testing

```javascript
test('hasEntitlement returns same result as hasAddOn for known inputs', () => {
  const testCases = [
    { tenantId: 'tenant-1', feature: 'scheduling', expected: true },
    { tenantId: 'tenant-2', feature: 'billing-advanced', expected: false },
    { tenantId: 'tenant-3', feature: 'telehealth', expected: true },
  ];

  for (const { tenantId, feature, expected } of testCases) {
    const legacyResult = hasAddOn(tenantId, feature);
    const newResult = hasEntitlement(tenantId, feature);

    expect(newResult).toBe(legacyResult);
    expect(newResult).toBe(expected);
  }
});
```

### Shadow Testing

In production, run both paths but only use the legacy result. Log discrepancies:

```javascript
async function checkEntitlement(tenantId, feature) {
  const legacyResult = await hasAddOn(tenantId, feature);

  // Shadow: run new path, log but don't use
  try {
    const newResult = await hasEntitlement(tenantId, feature);
    if (newResult !== legacyResult) {
      logger.warn('Entitlement mismatch', {
        tenantId, feature, legacy: legacyResult, new: newResult,
      });
    }
  } catch (err) {
    logger.error('New entitlement path failed', { tenantId, feature, err });
  }

  return legacyResult; // Still using legacy
}
```

## Feature Flag Testing

Every feature-flagged migration needs tests for both states:

```javascript
describe('booking with entitlement flag', () => {
  test('flag OFF: uses legacy hasAddOn path', async () => {
    setFeatureFlag('use-entitlements', false);
    const result = await getBookingOptions(testProvider);
    expect(result.source).toBe('legacy');
    expect(hasAddOnSpy).toHaveBeenCalled();
  });

  test('flag ON: uses new hasEntitlement path', async () => {
    setFeatureFlag('use-entitlements', true);
    const result = await getBookingOptions(testProvider);
    expect(result.source).toBe('entitlement');
    expect(hasEntitlementSpy).toHaveBeenCalled();
  });

  test('flag ON: same behavior as flag OFF', async () => {
    const legacyResult = await withFlag('use-entitlements', false, () =>
      getBookingOptions(testProvider),
    );
    const newResult = await withFlag('use-entitlements', true, () =>
      getBookingOptions(testProvider),
    );
    expect(newResult.options).toEqual(legacyResult.options);
  });
});
```

## Migration Batch Testing

When migrating call sites in batches:

### Pre-Migration Checklist

For each batch of call sites:
1. **Characterization tests exist** for all call sites in the batch
2. **Dual-path test** proves old and new return identical results for representative inputs
3. **Feature flag test** covers both flag states
4. **E2E test** covers the user-facing workflow that passes through these call sites

### Regression Suite

Maintain a migration regression suite that grows with each batch:

```javascript
// tests/migration/entitlement-regression.test.js
// This suite runs ALL migrated call sites.
// Add to it with each migration batch.

describe('Entitlement migration regression', () => {
  describe('Batch 1: Booking flow', () => { /* ... */ });
  describe('Batch 2: Scheduling', () => { /* ... */ });
  // Batch 3 added when that migration PR lands
});
```

### Canary Validation

After deploying a migration batch:
1. Enable flag for a single test tenant
2. Run E2E suite against that tenant
3. Monitor logs for discrepancies (shadow testing)
4. If clean for N hours/days, expand rollout
5. If discrepancies found, disable flag, investigate

## E2E for Tier-Gated Features

For tier-gated features, E2E tests should cover the matrix:

```javascript
const tierMatrix = [
  { tier: 'Good', scheduling: true, telehealth: false, advancedBilling: false },
  { tier: 'Better', scheduling: true, telehealth: true, advancedBilling: false },
  { tier: 'Best', scheduling: true, telehealth: true, advancedBilling: true },
];

for (const { tier, ...expectations } of tierMatrix) {
  test(`${tier} tier sees correct features`, async () => {
    await loginAsTenant({ tier });

    for (const [feature, expected] of Object.entries(expectations)) {
      const visible = await page.isVisible(`[data-feature="${feature}"]`);
      expect(visible).toBe(expected);
    }
  });
}
```

## Anti-Patterns

| Anti-Pattern | Risk | Do This Instead |
|-------------|------|-----------------|
| Testing new path only | Regression in legacy path during coexistence | Test both paths |
| Skipping flag-off tests | Flag rollback doesn't work | Always test both flag states |
| One big migration batch | Failure affects everything | Small batches, each with its own test suite |
| Removing characterization tests too early | Lose safety net before migration validated | Keep until migration fully rolled out and stable |
