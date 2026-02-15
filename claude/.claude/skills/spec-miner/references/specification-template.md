# Specification Template

## Full Template

```markdown
# Reverse-Engineered Specification: [System/Feature Name]

## Overview
[High-level description based on analysis]

## Architecture Summary

### Technology Stack
- **Runtime**: Node.js
- **Framework**: Express via @neb/microservice
- **Database**: MySQL (via Sequelize) / PostgreSQL (warehouse)
- **Messaging**: Kafka
- **Frontend**: Lit (web components)

### Directory Structure
```
src/
├── controllers/    # Filesystem-based routing (API endpoints)
├── models/         # Sequelize model definitions
├── services/       # Business logic
├── api-clients/    # Cross-service HTTP clients
├── messaging/      # Kafka subscriptions and handlers
├── formatters/     # Response formatters
├── utils/          # Helpers
test/               # Mirrors src/ structure
factories/          # Test data factories
migrations/         # Sequelize/umzug migrations
helm/               # Kubernetes deployment config
```

### Data Flow
```
Request → controllerWrapper (auth, tenant, validation)
  → Controller handler → Service → Model (req.db) → Database
                       ↓
                 API clients (cross-service)
                 Kafka messages (async)
```

## Observed Functional Requirements

### [Module/Feature Name]

**OBS-XXX-001**: [Feature Name]
[EARS format requirement]

**OBS-XXX-002**: [Feature Name]
[EARS format requirement]

## Feature Gating

### Feature Flags
| Flag | Purpose | Behavior When Off |
|------|---------|-------------------|

### Entitlement Checks
| Entitlement | Legacy Equivalent | Call Sites |
|-------------|-------------------|------------|

### Add-On Checks (Legacy)
| Add-On | Purpose | Call Sites |
|--------|---------|------------|

## Cross-Service Dependencies

| Service | How Called | What For |
|---------|-----------|----------|
| neb-ms-registry | msRequest via api-client | Tenant data, practice info |
| neb-ms-billing | msRequest via api-client | Charges, ledger |

## Kafka Message Flows

| Message | Publisher | Subscriber | Payload |
|---------|-----------|------------|---------|

## Observed Non-Functional Requirements

### Security
- Authentication: Cognito JWT
- Authorization: SECURITY_SCHEMA_KEYS per endpoint
- Tenant isolation: req.db (scoped connection)

### Error Handling
| Code | Condition | Response Shape |
|------|-----------|----------------|
| 400 | Validation failure | `{ error: { code, message, details } }` |
| 401 | Invalid/missing token | `{ error: "Unauthorized" }` |
| 403 | Insufficient permissions | `{ error: { code: 'FORBIDDEN' } }` |
| 404 | Resource not found | `{ error: "Not found" }` |

## Inferred Acceptance Criteria

### AC-001: [Feature]
Given [precondition]
When [action]
Then [expected result]

## Uncertainties and Questions

- [ ] [Specific uncertainty with code location]
- [ ] [Behavior observed but intent unclear]
- [ ] [Commented-out code — was this intentional?]

## Recommendations

1. [Observation about missing tests, documentation, or inconsistencies]
2. [Potential improvement identified during analysis]
```

## Required Sections

| Section | Purpose |
|---------|---------|
| Overview | High-level summary |
| Architecture | Tech stack, structure, data flow |
| Functional Requirements | EARS format observations |
| Feature Gating | Flags, entitlements, add-ons |
| Cross-Service Dependencies | Service-to-service calls |
| Non-Functional | Security, errors, performance |
| Uncertainties | Questions for clarification |
