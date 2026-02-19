# Analysis Checklist

## Comprehensive Checklist

| Area | What to Find | Patterns |
|------|--------------|----------|
| **Entry points** | App bootstrap, server start | `**/src/index.js`, `**/server.js` |
| **Routes** | API endpoints (filesystem routing) | `**/controllers/api/**/{get,post,put,delete}.js` |
| **Models** | Sequelize definitions | `**/models/**/*.js`, `DataTypes.` |
| **Services** | Business logic | `**/services/**/*.js` |
| **Auth** | Security schemas, permissions | `SECURITY_SCHEMA_KEYS`, `securitySchema` |
| **Validation** | Request schemas | `requestSchema`, `express-validator` |
| **Error handling** | Error responses, try/catch | `catch`, `res.status(4`, `res.status(5` |
| **External calls** | Cross-service HTTP | `msRequest`, `NEB_*_API_URL` |
| **Messaging** | Kafka handlers | `**/messaging/**/*.js`, `subscribe` |
| **Feature gates** | Flags and entitlements | `hasFeatureOrBeta`, `hasEntitlement`, `hasAddOn` |
| **Config** | Environment, helm values | `**/.env*`, `**/helm/values*.yaml` |
| **Tests** | Test files reveal behaviors | `**/*.test.js`, `**/factories/**/*.js` |
| **Formatters** | Response shapes | `**/formatters/**/*.js` |
| **Components** | Lit web components | `**/neb-*.js`, `LitElement` |

## Analysis Phases

### Phase 1: Structure Discovery
- [ ] Identify technology stack (MySQL/Postgres, Express version, Sequelize version)
- [ ] Map directory structure
- [ ] Find entry points and bootstrap sequence
- [ ] List all modules/packages

### Phase 2: API Surface
- [ ] Document all endpoints (method + path from filesystem routing)
- [ ] Note security schemas per endpoint
- [ ] Identify request schemas (validation rules)
- [ ] Find feature flag gates on endpoints
- [ ] Map response formatters to endpoints

### Phase 3: Data Layer
- [ ] Map all Sequelize models and their relationships
- [ ] Review migrations for schema evolution
- [ ] Find soft-delete patterns (`paranoid: true`)
- [ ] Note multi-tenant patterns (`req.db`, `tenantId` scoping)
- [ ] Check for raw SQL queries

### Phase 4: Business Logic
- [ ] Trace main flows through services
- [ ] Identify business rules and validation
- [ ] Document state transitions (status fields, workflow steps)
- [ ] Find cross-service dependencies (api-clients, msRequest)
- [ ] Map Kafka message flows (publish/subscribe pairs)

### Phase 5: Feature Gating
- [ ] List all feature flags referenced
- [ ] List all entitlement checks
- [ ] List all legacy add-on checks
- [ ] Map which features are behind which gates
- [ ] Note conditional behavior changes per flag state

### Phase 6: Security
- [ ] Check authentication method (Cognito/JWT)
- [ ] Review authorization patterns (SECURITY_SCHEMA_KEYS)
- [ ] Find input validation coverage
- [ ] Note HIPAA-relevant data handling (PHI, PII)
- [ ] Check for data exposure in responses

### Phase 7: Quality & Testing
- [ ] Review existing test coverage
- [ ] Read test descriptions for intended behavior
- [ ] Check factory definitions for data patterns
- [ ] Document error handling patterns
- [ ] Find logging patterns (Pino)

## Verification Questions

Before finalizing specification:

- [ ] All endpoints documented with their security and validation?
- [ ] All models mapped with relationships?
- [ ] Feature flag behavior documented for all states (on/off)?
- [ ] Cross-service dependencies identified?
- [ ] Error responses documented?
- [ ] Kafka message flows traced end-to-end?
- [ ] Uncertainties clearly flagged?
