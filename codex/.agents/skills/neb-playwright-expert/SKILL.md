---
name: neb-playwright-expert
description: Use when writing, debugging, or planning E2E tests in neb-www using the Playwright framework and its custom component generation system.
---

# Playwright Neb

E2E testing patterns for neb-www's Playwright infrastructure. neb-www has a custom component generation system, dataset-driven test data, and conventions that override standard Playwright patterns.

## When to Use

- Writing new Playwright E2E tests in neb-www
- Migrating WDIO tests to Playwright
- Debugging flaky or failing Playwright tests
- Planning E2E test coverage for features

## When NOT to Use

- Unit or integration tests → use `test-driven-development`
- Planning which test layers a feature needs → use `test-driven-development`
- Playwright in non-neb projects → these patterns are neb-specific

## Iron Rules

1. **Never use raw selectors** — always use `getComponent(page, 'ComponentName')`
2. **Always call `waitForReady()`** before interacting with a component
3. **Never run `npx playwright test` directly** — use `npm run test:playwright:*` scripts
4. **Never remove `.only`** from existing describe blocks
5. **Regenerate components** after adding new source components: `npm run test:gen:playwright`

## Component System

neb-www auto-generates 1189+ Playwright components from source via two-tier generation:
- **Tier 1**: Scans source directories, generates component classes with methods
- **Tier 2**: Detects container relationships, generates child access methods

```javascript
const { getComponent } = require('../helpers/component-helper');

const loginForm = getComponent(page, 'LoginForm');
await loginForm.waitForReady();

// Scoped to a container
const modal = getComponent(page, 'AppointmentModal', '#booking-dialog');
await modal.waitForReady();
```

Every generated component inherits: `waitForReady()`, `waitForVisible()`, `isVisible()`, `isEnabled()`, plus methods from the source component (auto-generated, camelCase).

See `references/components-and-selectors.md` for the full component system.

## Data Setup

Tests use a dataset system for creating backend entities:

```javascript
const { setupPlaywrightTest } = require('./playwrightIntegrationSetup');

const data = await setupPlaywrightTest(page, {
  apiDataset: true,
  permissionsDataset: { permissions: ['canBook', 'canViewBilling'] },
  billingDataset: true,
});

const providerId = data.apiData.provider.id;
```

**Dataset order matters**: `permissionsDataset` must be declared before `apiDataset` for cross-dataset extraction.

See `references/data-setup.md` for all datasets and configuration options.

## Test Runner

```bash
npm run test:playwright                  # Default parallel
npm run test:playwright:sequential       # One at a time
npm run test:playwright:file -- --file booking-flow  # Specific file
npm run test:playwright:debug            # Headed + slow motion
npm run test:playwright:ui               # Interactive UI mode
npm run test:playwright:report           # View HTML report
```

File paths are relative to integration/ — don't include "integration/" in `--file`.

## Login Pattern

Always use component-based login:

```javascript
const loginPage = getComponent(page, 'LoginPage');
await loginPage.waitForReady();
await loginPage.login(data.permissionsData.email, data.permissionsData.password);
```

## Setup Functions

| Function | App | Notes |
|----------|-----|-------|
| `setupPlaywrightTest(page, opts)` | Generic | Base setup for any test |
| `setupPractice(page, opts)` | Practice | Includes navigation |
| `setupSettings(page, opts)` | Settings | Settings app context |
| `setupBooking(page, opts)` | Booking | Constructs booking URL |
| `setupSupport(page, opts)` | Support | Uses support user credentials |

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Component System & Selectors | `references/components-and-selectors.md` | Working with component generation or choosing selectors |
| Data Setup Patterns | `references/data-setup.md` | Configuring test data with datasets |
| Debugging & Flaky Tests | `references/debugging-flaky.md` | Tests failing intermittently or in CI |
| API Mocking | `references/api-mocking.md` | Intercepting network requests in tests |

## Constraints

### MUST DO
- Use `getComponent()` for all element access
- Call `waitForReady()` before interacting with any component
- Run `npm run test:gen:playwright` after adding new source components
- Follow staged development (get test running first, then refine)
- Use dataset system for test data — never hardcode entity IDs

### MUST NOT DO
- Use raw CSS/XPath selectors
- Use `npx playwright test` directly (bypasses custom runner)
- Use `page.waitForTimeout()` for synchronization (use component waits)
- Hardcode URLs — use setup functions that construct them
- Remove `.only` from existing test files
