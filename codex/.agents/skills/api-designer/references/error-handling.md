# Error Handling

## Error Response Format

Use a consistent shape across all endpoints:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description of what went wrong",
    "details": [
      {
        "field": "date",
        "message": "Must be a future date",
        "value": "2024-01-01"
      }
    ]
  }
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `error.code` | string | Machine-readable error code (SCREAMING_SNAKE) |
| `error.message` | string | Human-readable summary |

### Optional Fields

| Field | Type | When to Include |
|-------|------|----------------|
| `error.details` | array | Validation errors with per-field info |
| `error.details[].field` | string | Which field failed validation |
| `error.details[].message` | string | Why the field failed |
| `error.details[].value` | any | The rejected value (omit for sensitive data) |

## Error Code Taxonomy

Define error codes by category:

```javascript
// Common error codes
const ERROR_CODES = {
  // Validation
  VALIDATION_ERROR: 400,
  MISSING_REQUIRED_FIELD: 400,
  INVALID_FORMAT: 400,

  // Auth
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  INSUFFICIENT_PERMISSIONS: 403,
  ENTITLEMENT_REQUIRED: 403,

  // Not found
  RESOURCE_NOT_FOUND: 404,
  TENANT_NOT_FOUND: 404,

  // Conflict
  DUPLICATE_RESOURCE: 409,
  STATE_CONFLICT: 409,

  // Business rules
  BUSINESS_RULE_VIOLATION: 422,

  // Server
  INTERNAL_ERROR: 500,
  UPSTREAM_SERVICE_ERROR: 502,
  SERVICE_UNAVAILABLE: 503,
};
```

## Validation Errors

### Request Schema Validation (express-validator)

```javascript
export default {
  requestSchema: {
    body: {
      date: {
        isISO8601: true,
        errorMessage: 'Must be a valid ISO 8601 date',
      },
      patientId: {
        isUUID: true,
        errorMessage: 'Must be a valid UUID',
      },
      amount: {
        isFloat: { options: { min: 0 } },
        errorMessage: 'Must be a non-negative number',
      },
    },
  },
  handler: async (req, res) => { ... },
};
```

The `controllerWrapper` handles validation automatically and returns 400 with details.

### Business Rule Validation

For rules that go beyond format validation:

```javascript
handler: async (req, res) => {
  const appointment = await db.Appointment.findByPk(req.params.id);

  if (!appointment) {
    return res.status(404).json({
      error: {
        code: 'RESOURCE_NOT_FOUND',
        message: `Appointment ${req.params.id} not found`,
      },
    });
  }

  if (appointment.status === 'completed') {
    return res.status(409).json({
      error: {
        code: 'STATE_CONFLICT',
        message: 'Cannot modify a completed appointment',
      },
    });
  }

  // proceed...
};
```

## Entitlement Errors

When an endpoint requires an entitlement the tenant doesn't have:

```javascript
if (!await hasEntitlement(req.tenantId, ENTITLEMENTS.REAL_TIME_ELIGIBILITY)) {
  return res.status(403).json({
    error: {
      code: 'ENTITLEMENT_REQUIRED',
      message: 'This feature requires the Real-Time Eligibility entitlement',
      details: [{
        entitlement: 'real-time-eligibility',
        currentTier: tenant.productTier,
      }],
    },
  });
}
```

**Important**: Don't expose tier upgrade information in public APIs — that's a sales/UI concern, not an API concern. The `details` above are appropriate for internal/admin APIs only.

## Error Handling Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| `res.status(200).json({ error: '...' })` | Client can't distinguish success from failure by status | Use appropriate 4xx/5xx status |
| Generic `500` for all errors | Caller can't tell if they made a mistake or the server did | Use 4xx for client errors |
| Stack traces in production | Security risk, leaks internals | Log internally, return generic message |
| Different error shapes per endpoint | Clients need per-endpoint error handling | Use consistent error format |
| Swallowing errors silently | Bugs hide, debugging is impossible | Log and return appropriate error |
| Exposing database errors | SQL errors leak schema details | Catch and wrap in application error |

## Service-to-Service Errors

When calling another service via `msRequest`:

```javascript
try {
  const result = await msRequest({ ... });
  return result;
} catch (error) {
  if (error.statusCode === 404) {
    // Upstream resource not found — may be 404 or 422 for us
    return res.status(422).json({
      error: {
        code: 'BUSINESS_RULE_VIOLATION',
        message: 'Referenced patient not found in registry',
      },
    });
  }

  // Unexpected upstream error
  logger.error('Registry service error', { error, tenantId });
  return res.status(502).json({
    error: {
      code: 'UPSTREAM_SERVICE_ERROR',
      message: 'Unable to reach registry service',
    },
  });
}
```

**Don't pass through upstream error bodies** — they may contain internal details from the other service. Wrap in your own error shape.
