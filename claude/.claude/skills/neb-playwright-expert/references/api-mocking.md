# API Mocking

Intercept and mock network requests in Playwright tests using `page.route()`.

## Basic Mocking

```javascript
// Mock a specific endpoint
await page.route('**/api/entitlements', async (route) => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({
      tier: 'Good',
      features: ['scheduling', 'basic-billing'],
    }),
  });
});
```

## Common Patterns

### Mock Error Responses

```javascript
await page.route('**/api/billing/charge', async (route) => {
  await route.fulfill({
    status: 500,
    body: JSON.stringify({ error: 'Payment gateway unavailable' }),
  });
});
```

### Modify Real Responses

Fetch the real response, then modify it:

```javascript
await page.route('**/api/providers', async (route) => {
  const response = await route.fetch();
  const json = await response.json();

  // Override one field
  json.providers[0].tier = 'Best';

  await route.fulfill({ response, body: JSON.stringify(json) });
});
```

### Conditional Mocking

```javascript
await page.route('**/api/**', async (route) => {
  const url = route.request().url();

  if (url.includes('/entitlements')) {
    await route.fulfill({ body: JSON.stringify({ tier: 'Good' }) });
  } else {
    await route.continue(); // pass through
  }
});
```

### Wait for Responses

```javascript
// Wait for a specific API call to complete
const responsePromise = page.waitForResponse('**/api/appointments');
await submitButton.click();
const response = await responsePromise;
expect(response.status()).toBe(200);

// Wait for response and check body
const response = await page.waitForResponse(
  (resp) => resp.url().includes('/api/appointments') && resp.status() === 200,
);
const data = await response.json();
expect(data.appointments).toHaveLength(3);
```

### Simulate Slow Networks

```javascript
await page.route('**/api/**', async (route) => {
  await new Promise((resolve) => setTimeout(resolve, 3000));
  await route.continue();
});
```

## Quick Reference

| Method | Use Case |
|--------|----------|
| `route.fulfill()` | Return a completely mocked response |
| `route.continue()` | Let the request pass through unchanged |
| `route.fetch()` | Fetch real response, then modify before fulfilling |
| `route.abort()` | Simulate network failure |
| `page.waitForResponse()` | Wait for a specific response before asserting |

## When to Mock vs Use Real Data

| Scenario | Approach |
|----------|----------|
| Testing UI for specific tier/state | Mock the entitlement API |
| Testing happy path user flow | Use real data via dataset system |
| Testing error handling UI | Mock error responses |
| Testing loading states | Mock with delay |
| Testing integration correctness | Real data — mocking defeats the purpose |

**Default to real data** via the dataset system. Only mock when you need specific conditions that are hard to create via datasets (error states, edge cases, specific timing).
