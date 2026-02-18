# Characterization Testing

Characterization tests capture the **current behavior** of existing code, including bugs and quirks. They're not asserting correctness — they're documenting the contract so you know when you've changed it.

## When to Use

- Before modifying code that has no tests
- Before migrating call sites from one API to another
- When "what does this actually do?" is unclear from reading the code
- When manual QA is the only existing verification

## The Process

### 1. Identify the Boundary

Pick the outermost boundary you can test:
- API endpoint (best — tests the full path)
- Service method (good — tests business logic)
- Individual function (acceptable — tests isolated behavior)

### 2. Record Current Behavior

```javascript
// Step 1: Call the code with known inputs
// Step 2: Log/capture the actual output
// Step 3: Write an assertion matching what you observed

test('booking flow returns entitlements for provider', async () => {
  const result = await getBookingEntitlements({
    providerId: 'test-provider-123',
    tenantId: 'test-tenant',
    tier: 'Good',
  });

  // These assertions describe what the code DOES today,
  // not necessarily what it SHOULD do
  expect(result.canBook).toBe(true);
  expect(result.addOns).toEqual(['basic-scheduling']);
  expect(result.maxSlots).toBe(10);
});
```

### 3. Cover the Variants

For entitlement-style code, characterize each dimension:

| Dimension | Variants to Test |
|-----------|-----------------|
| Tier | Good, Better, Best |
| Role | Provider, Staff, Admin |
| Feature flags | Flag on, flag off |
| Edge cases | No tenant, expired subscription, missing config |

### 4. Verify the Characterization

Run the tests against the **unmodified code**. They should all pass. If any fail, your characterization is wrong — fix the test, not the code.

### 5. Now Modify

With characterization tests in place:
- Make your change
- Run the tests
- Failures = behavior changed (decide if intentional)
- Passing = behavior preserved

## Patterns

### Golden File Testing

For complex outputs (HTML, JSON responses), save the full output and compare:

```javascript
test('booking page renders correctly for Good tier', async () => {
  const html = await renderBookingPage({ tier: 'Good' });
  expect(html).toMatchSnapshot();
});
```

### Contract Testing

For API boundaries between services:

```javascript
test('billing service returns expected shape for entitlement check', async () => {
  const response = await billingService.checkEntitlement({
    tenantId: 'test',
    featureKey: 'scheduling',
  });

  // Shape contract — not value-specific
  expect(response).toMatchObject({
    entitled: expect.any(Boolean),
    tier: expect.stringMatching(/Good|Better|Best/),
    limits: expect.any(Object),
  });
});
```

### Approval Testing

For UI or output-heavy code: capture output, review manually once, then auto-compare on future runs. Useful for complex rendered components where snapshots are too brittle.

## Marking Characterization Tests

Label them so the team knows their purpose and lifecycle:

```javascript
describe('[CHARACTERIZATION] Booking entitlement checks', () => {
  // Captures pre-migration behavior of hasAddOn().
  // Replace with proper tests after hasEntitlement() migration.
  // Target removal: after migration Phase 2 complete.

  test('Good tier provider can book with basic scheduling', () => {
    // ...
  });
});
```

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Do This Instead |
|-------------|---------------|-----------------|
| Testing only the happy path | Misses edge cases that break during migration | Cover error paths and boundary conditions |
| Asserting on implementation details | Tests break on valid refactors | Assert on observable behavior (inputs/outputs) |
| Writing characterization tests AFTER changing code | You're testing the new behavior, not capturing the old | Always characterize BEFORE modifying |
| Treating characterization tests as permanent | They're scaffolding — replace with proper tests over time | Mark them clearly, retire after migration |
