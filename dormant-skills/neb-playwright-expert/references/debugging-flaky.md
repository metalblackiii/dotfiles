# Debugging & Flaky Tests

## Debug Mode

Use the custom runner's debug mode for headed, slow-motion execution:

```bash
npm run test:playwright:debug -- --file booking-flow
```

This enables:
- Visible browser window
- Slowed execution for visual inspection
- Console output in terminal

For Playwright's built-in inspector:
```bash
PWDEBUG=1 npm run test:playwright:file -- --file booking-flow
```

## Interactive UI Mode

```bash
npm run test:playwright:ui
```

Opens Playwright's interactive test runner with:
- Step-through execution
- Time-travel debugging
- DOM snapshot at each step
- Network request inspection

## Common Flaky Test Causes

### 1. Missing waitForReady()

**Symptom**: Test works locally, fails in CI.

```javascript
// BAD: component may not be interactive yet
const form = getComponent(page, 'PatientForm');
await form.setName('John');  // race condition

// GOOD: always wait first
const form = getComponent(page, 'PatientForm');
await form.waitForReady();
await form.setName('John');
```

### 2. Dataset Ordering

**Symptom**: Data is undefined or login fails.

Check that `permissionsDataset` is declared before `apiDataset` when cross-dataset extraction is needed. See `data-setup.md` for details.

### 3. Animation/Transition Timing

**Symptom**: Click happens before element is in final position.

```javascript
// Wait for the component to be stable, not just visible
const modal = getComponent(page, 'ConfirmDialog');
await modal.waitForReady();  // waits for interactive state
await modal.confirm();
```

### 4. Network Timing

**Symptom**: Assertion runs before API response arrives.

```javascript
// Wait for the specific response before asserting
const [response] = await Promise.all([
  page.waitForResponse('**/api/appointments'),
  appointmentForm.submit(),
]);
expect(response.status()).toBe(200);
```

### 5. Test Isolation

**Symptom**: Test passes alone, fails when run with others.

Each test should create its own data via `setupPlaywrightTest()`. Never rely on data from a previous test. Use `test.beforeEach()` for setup, not `test.beforeAll()`.

## CI vs Local

| Setting | Local | CI |
|---------|-------|-----|
| Headed | Optional (`--debug`) | Always headless |
| Workers | Parallel | 1 worker |
| Retries | 0 | 2 |
| Screenshots | On failure | On failure |
| Trace | Off | On first retry |

CI uses 1 worker to reduce flakiness from resource contention. If a test is flaky only in CI, it's usually a timing issue — add proper waits.

## Trace Viewer

When CI captures a trace (on first retry):

```bash
npx playwright show-trace trace.zip
```

Shows:
- Step-by-step execution with screenshots
- Network requests and responses
- Console logs
- DOM snapshots at each action

## Reporting

```bash
npm run test:playwright:report
```

Opens the HTML report showing:
- Pass/fail per test
- Duration and slow tests (>15s flagged)
- Screenshots on failure
- Retry history

## Debugging Checklist

1. Can you reproduce locally? → `npm run test:playwright:debug -- --file <name>`
2. Is it a timing issue? → Check for missing `waitForReady()` calls
3. Is data set up correctly? → Log `data` object, check dataset order
4. Is it CI-only? → Likely resource contention — add explicit waits
5. Is it intermittent? → Run 5x locally: `for i in {1..5}; do npm run test:playwright:file -- --file <name>; done`
