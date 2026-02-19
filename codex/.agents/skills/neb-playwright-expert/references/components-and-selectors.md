# Component System & Selectors

## Two-Tier Generation

neb-www generates Playwright component classes from source code via `npm run test:gen:playwright`:

**Tier 1 — Component Generation**: Scans source directories, generates a class for each component with methods matching the source component's API (camelCase).

**Tier 2 — Container Detection**: Analyzes generated components, detects parent-child relationships, and adds child access methods to container components.

When a component is missing, regenerate before writing manual selectors:
```bash
npm run test:gen:playwright
```

## getComponent() API

```javascript
const { getComponent } = require('../helpers/component-helper');

// Basic usage
const button = getComponent(page, 'SubmitButton');
await button.waitForReady();
await button.click();

// Scoped to a container element
const modal = getComponent(page, 'PatientForm', '#edit-dialog');
await modal.waitForReady();

// Access container children (tier 2 generated)
const table = getComponent(page, 'AppointmentTable');
await table.waitForReady();
const row = table.getRow(0); // child access method
```

### Common Methods

Every component inherits:

| Method | Purpose | Required |
|--------|---------|----------|
| `waitForReady()` | Wait until component is interactive | **Always call first** |
| `waitForVisible()` | Wait until component is visible in DOM | Before visibility checks |
| `isVisible()` | Check if component is visible | Conditional logic |
| `isEnabled()` | Check if component is enabled | Before interactions |
| `click()` | Click the component | User actions |

Component-specific methods are generated from source and available via auto-complete.

## Selector Priority

In neb-www, the component system replaces the standard Playwright selector strategy:

| Priority | Approach | When |
|----------|----------|------|
| **1st** | `getComponent(page, 'Name')` | Always — default for all elements |
| **2nd** | `getComponent(page, 'Name', '#scope')` | When multiple instances exist on page |
| **3rd** | `page.getByRole()` | Only if no generated component exists AND after regenerating |
| **Never** | Raw CSS/XPath selectors | Brittle, bypasses component system |

## Container Scoping

When the same component appears multiple times (e.g., multiple forms on a page):

```javascript
// BAD: ambiguous — which PatientName?
const name = getComponent(page, 'PatientName');

// GOOD: scoped to specific container
const name = getComponent(page, 'PatientName', '#primary-patient-card');
```

## Component Method Chaining

```javascript
const form = getComponent(page, 'AppointmentForm');
await form.waitForReady();
await form.setDate('2024-01-15');
await form.setTime('10:00');
await form.setProvider('Dr. Smith');
await form.submit();
```

## Handling Missing Components

If `getComponent()` throws because a component doesn't exist:
1. Run `npm run test:gen:playwright` — the component may not be generated yet
2. Check that the source component exists and is properly exported
3. If the source component is new, verify tier 1 generation picked it up
4. Only as a last resort, use `page.getByRole()` with a comment explaining why

## Bulk Operations

```javascript
// Get all rows in a table
const table = getComponent(page, 'PatientTable');
await table.waitForReady();
const rowCount = await table.getRowCount();

for (let i = 0; i < rowCount; i++) {
  const row = table.getRow(i);
  // operate on each row
}
```
