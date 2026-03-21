# Data Setup Patterns

## Dataset System

Tests create real backend entities via the dataset system. Each dataset type creates specific entities needed for testing.

### Available Datasets

| Dataset | Creates | Common Options |
|---------|---------|---------------|
| `apiDataset` | Provider, patient, appointments | Core entity setup |
| `billingDataset` | Billing/payment entities | Scrubbing defaults |
| `chartingDataset` | Clinical charting data | Chart templates |
| `paymentsDataset` | Payment processing entities | Payment methods |
| `permissionsDataset` | User roles and permissions | `{ permissions: [...] }` |
| `macroMetadataDataset` | Template/macro data | Macro types |
| `registryDataset` | Registry/configuration | Tenant + location attrs |
| `layout` | Viewport size | `'small'`, `'medium'`, `'large'` |

### Basic Configuration

```javascript
const { setupPlaywrightTest } = require('./playwrightIntegrationSetup');

// Boolean for defaults
const data = await setupPlaywrightTest(page, {
  apiDataset: true,
  billingDataset: true,
});

// Object for custom options
const data = await setupPlaywrightTest(page, {
  permissionsDataset: {
    permissions: ['canBook', 'canViewBilling', 'canEditPatient'],
  },
  apiDataset: true,
});
```

### Cross-Dataset Extraction

Datasets process in **declaration order**. This enables cross-dataset references:

```javascript
// permissionsDataset processes FIRST, creating a bookingAccount
// apiDataset processes SECOND, can reference permissionsData
const data = await setupPlaywrightTest(page, {
  permissionsDataset: { permissions: ['canBook'] },
  apiDataset: true,  // can now access data.permissionsData.bookingAccount.cognitoId
});
```

**Critical**: If `permissionsDataset` is declared after `apiDataset`, the extraction fails silently — no error, just missing data.

### Accessing Created Entities

```javascript
const data = await setupPlaywrightTest(page, {
  apiDataset: true,
  permissionsDataset: { permissions: ['canBook'] },
});

// API entities
const providerId = data.apiData.provider.id;
const patientId = data.apiData.patient.id;

// Permission entities
const cognitoId = data.permissionsData.bookingAccount.cognitoId;
const email = data.permissionsData.email;
const password = data.permissionsData.password;
```

## App-Specific Setup

Each app has a dedicated setup function that handles navigation:

```javascript
const { setupPractice, setupBooking, setupSettings } = require('./playwrightIntegrationSetup');

// Practice app — navigates after setup
const data = await setupPractice(page, {
  apiDataset: true,
  permissionsDataset: { permissions: ['canViewSchedule'] },
});

// Booking app — constructs booking URL
const data = await setupBooking(page, {
  apiDataset: true,
});

// Settings app
const data = await setupSettings(page, {
  permissionsDataset: { permissions: ['canManageSettings'] },
});
```

## Troubleshooting

### Silent Dataset Failures

Datasets can fail silently (no error thrown, but data is missing or incomplete). Signs:
- `data.apiData.provider` is `undefined`
- Login fails with valid-looking credentials
- Tests timeout waiting for data that wasn't created

**Fix**: Check dataset declaration order, verify permissions are valid strings, ensure the backend service is running.

### Environment Variables

The setup system reads from environment:
- `BASE_URL` — Application base URL
- `STAGING_URL`, `STAGING_EMAIL`, `STAGING_PASSWORD` — For staging tests

### Layout Handling

```javascript
// Test responsive behavior
const data = await setupPlaywrightTest(page, {
  apiDataset: true,
  layout: 'small',  // MIN_WIDTH_MEDIUM = 835px breakpoint
});
```
