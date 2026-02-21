---
name: analyzing-prs
description: Domain knowledge for PR review checklists and quality criteria. Consumed by the review and self-review skills — not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# PR Analysis Skill

Domain knowledge for analyzing pull requests against quality standards and best practices.

## Review Categories

Use these categories to evaluate PR changes comprehensively.

### 1. Architecture Compliance

- [ ] Follows established patterns in the codebase
- [ ] Services/modules use clear boundaries and dependency injection where appropriate
- [ ] Controllers/handlers are thin and delegate to services
- [ ] No business logic in request handlers
- [ ] Composition over inheritance
- [ ] No unnecessary static/global dependencies

### 2. Testing Coverage

- [ ] Tests included for new functionality
- [ ] Test names describe behavior: "should [behavior] when [condition]"
- [ ] Tests follow Arrange-Act-Assert pattern
- [ ] External dependencies are mocked/stubbed appropriately
- [ ] Integration tests added for cross-cutting flows (if applicable)
- [ ] Edge cases covered (empty, null, boundary values, error paths)

### 3. Code Quality

- [ ] No compiler/linter warnings introduced
- [ ] Follows project naming conventions
- [ ] No commented-out code
- [ ] No TODO/FIXME comments without issue references
- [ ] No hardcoded secrets or credentials
- [ ] Error handling appropriate (try-catch where needed)
- [ ] Async/await used correctly (no fire-and-forget, proper error propagation)
- [ ] Resources properly cleaned up (connections, streams, event listeners)

### 4. Authentication & Authorization

- [ ] Appropriate auth checks on endpoints
- [ ] Required permissions/roles validated
- [ ] Token/session validation included where needed
- [ ] Webhook signature verification included (if applicable)
- [ ] Auth logic not duplicated — uses shared middleware/guards

### 5. Database & Migrations

- [ ] Migrations included for schema changes
- [ ] Migration naming is descriptive
- [ ] Migrations are reversible
- [ ] Indexes added for frequently queried columns
- [ ] Foreign keys and constraints configured correctly
- [ ] No raw SQL unless absolutely necessary (prefer ORM/query builder)
- [ ] Transactions used for multi-step operations

### 6. API Design

- [ ] Request/response types defined appropriately
- [ ] Input validation on all user-provided data
- [ ] API documentation updated for public endpoints
- [ ] HTTP status codes appropriate (200, 201, 400, 401, 404, 500)
- [ ] API versioning respected (if applicable)
- [ ] CORS configuration maintained

### 7. Logging & Observability

- [ ] Structured logging used (not console output in production)
- [ ] Log events have descriptive messages
- [ ] Sensitive data not logged (PII, credentials, tokens)
- [ ] Correlation/request IDs propagated where applicable

### 8. Frontend Changes (if applicable)

- [ ] Types defined for props, state, and API responses
- [ ] Styling follows project patterns (CSS modules, utility classes, etc.)
- [ ] No inline styles unless justified
- [ ] Accessibility considered (ARIA labels, keyboard navigation, focus management)
- [ ] Error and loading states handled
- [ ] Linting warnings resolved

### 9. Documentation

- [ ] Architecture docs updated if patterns changed
- [ ] README updated if setup changed
- [ ] Comments explain WHY/WARNING/TODO only — no "what" comments (per self-documenting-code rule)
- [ ] API documentation updated

### 10. Security

- [ ] No secrets committed (check `.env`, config files)
- [ ] Input validation on all user-provided data
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (encoded output, safe rendering)
- [ ] CSRF protection maintained
- [ ] Rate limiting considered for public endpoints
- [ ] Sensitive operations require authentication

### 11. Performance

- [ ] No N+1 query problems (use eager loading or batching)
- [ ] Database queries use indexes
- [ ] Large collections paginated
- [ ] Caching used where appropriate
- [ ] Async/await used for I/O operations
- [ ] No blocking calls on main thread/event loop

### 12. Dependencies

- [ ] New packages justified
- [ ] Package versions pinned (not wildcards)
- [ ] No conflicting dependency versions
- [ ] Security vulnerabilities checked

## Security Deep Dive

Extended security criteria for healthcare applications under HIPAA. Apply when changes touch authentication, authorization, patient data, audit logging, encryption, or entitlements.

### HIPAA & PHI

#### Data Classification

| Classification | Examples | Handling |
|---------------|---------|----------|
| **PHI** (Protected Health Information) | Patient name + diagnosis, SSN, DOB, insurance ID, appointment details | Encrypted at rest and in transit, access logged, never in logs/errors |
| **PII** (Personally Identifiable Information) | Name, email, phone, address (without health context) | Encrypted in transit, access controlled, minimal logging |
| **Internal** | Tenant config, feature flags, provider schedules | Standard access controls, no special encryption required |
| **Public** | Marketing content, pricing tiers, office hours | No restrictions |

#### PHI Review Checklist

- [ ] PHI never appears in log messages, error responses, or stack traces
- [ ] PHI not stored in browser localStorage/sessionStorage
- [ ] PHI not included in URL parameters (use POST body or encrypted tokens)
- [ ] PHI not cached in CDN or browser cache (appropriate Cache-Control headers)
- [ ] PHI access restricted to authenticated users with appropriate role/tenant
- [ ] PHI queries filtered by tenant ID (no cross-tenant data leakage)
- [ ] PHI exports (CSV, PDF) respect the same access controls as the UI

#### Multi-Tenant Data Isolation

- [ ] All database queries include tenant ID filter
- [ ] No endpoint returns data across tenants without explicit admin authorization
- [ ] Tenant ID derived from authenticated session, never from request parameters
- [ ] Shared tables (lookups, config) don't contain tenant-specific PHI
- [ ] Background jobs/workers scope to single tenant per execution

### Authentication Lifecycle

#### Token Management

- [ ] JWTs validated on every request (not just at login)
- [ ] Token expiration enforced server-side (don't trust client clocks)
- [ ] Refresh tokens rotated on use (one-time use)
- [ ] Token revocation supported (logout invalidates all sessions)
- [ ] Token payload contains minimal claims (no PHI, no full permissions list)

#### Cognito Patterns (neb-specific)

- [ ] `userSecurity` middleware applied to all authenticated routes
- [ ] `SECURITY_SCHEMA_KEYS` used for permission validation
- [ ] Cognito user pool ID not hardcoded (from environment)
- [ ] Pre-token-generation Lambda not leaking sensitive attributes
- [ ] MFA enforcement checked for admin/elevated operations

#### Session Security

- [ ] Session cookies marked HttpOnly, Secure, SameSite=Strict
- [ ] Session timeout enforced (idle and absolute)
- [ ] Session invalidated on password change
- [ ] Concurrent session limits enforced (if required by policy)

### Authorization Patterns

#### Role-Based Access

- [ ] Permissions checked at the route/endpoint level (middleware)
- [ ] Permissions also checked at the service level (defense in depth)
- [ ] No client-side-only permission checks (always server-validated)
- [ ] Permission changes take effect immediately (no stale cached permissions)
- [ ] Elevation of privilege requires re-authentication

#### Entitlement Checks

- [ ] Feature entitlements checked server-side, not just UI gating
- [ ] Entitlement cache invalidated on subscription changes
- [ ] Downgrade paths handle graceful feature removal (no data loss)
- [ ] Entitlement checks use the facade/abstraction layer (e.g., `hasEntitlement()`), not direct addon checks

### Audit Logging

#### What Must Be Logged

| Event | Required Fields | Severity |
|-------|----------------|----------|
| Login success/failure | userId, tenantId, IP, timestamp, method | Info/Warn |
| PHI access (read) | userId, tenantId, patientId, resource, timestamp | Info |
| PHI modification | userId, tenantId, patientId, resource, before/after, timestamp | Info |
| Permission changes | adminId, targetUserId, oldPerms, newPerms, timestamp | Warn |
| Failed authorization | userId, resource, requiredPerm, timestamp | Warn |
| Data export | userId, tenantId, exportType, recordCount, timestamp | Info |
| Account lockout | userId, failedAttempts, lockDuration, timestamp | Warn |

#### Audit Log Rules

- [ ] Audit logs are append-only (no modification or deletion)
- [ ] Audit logs stored separately from application logs
- [ ] Audit log entries include correlation ID for request tracing
- [ ] PHI in audit logs is minimized (patient ID, not patient name)
- [ ] Audit logs retained per HIPAA retention policy (minimum 6 years)
- [ ] Audit log access itself is logged

### Encryption

#### At Rest

- [ ] Database encryption enabled (Aurora/RDS encryption)
- [ ] S3 buckets use SSE (server-side encryption)
- [ ] Backups encrypted with separate key from production
- [ ] Encryption keys managed via KMS (not application-managed)

#### In Transit

- [ ] TLS 1.2+ enforced on all endpoints
- [ ] Internal service-to-service communication encrypted
- [ ] Database connections use SSL
- [ ] No sensitive data in query strings (use headers or body)

#### Application-Level

- [ ] Passwords hashed with bcrypt/scrypt/argon2 (not MD5/SHA)
- [ ] API keys and secrets in environment variables or secrets manager (not code)
- [ ] Encryption/signing keys rotated on schedule
- [ ] No custom cryptography (use established libraries)

### Input Validation (Extended)

Beyond the basic checklist:

- [ ] File uploads validated (type, size, content — not just extension)
- [ ] File uploads scanned or sandboxed before processing
- [ ] JSON payloads size-limited (prevent DoS via large payloads)
- [ ] Nested object depth limited (prevent prototype pollution)
- [ ] URL/redirect parameters validated against allowlist (prevent open redirect)
- [ ] GraphQL queries depth-limited (if applicable)
- [ ] Batch endpoints have item count limits

### Dependency Security

- [ ] `npm audit` / `yarn audit` shows no high/critical vulnerabilities
- [ ] Dependencies with known CVEs have upgrade path or mitigation documented
- [ ] No dependencies pulled from unofficial registries
- [ ] Lock file committed and reviewed for unexpected changes
- [ ] Transitive dependencies reviewed for known supply chain risks

### Security Severity Quick Reference

| Finding | Severity |
|---------|----------|
| PHI in logs or error responses | **Critical** |
| Missing tenant ID filter on PHI query | **Critical** |
| Missing authentication on endpoint | **Critical** |
| Missing authorization check (permissive) | **Critical** |
| Token not validated on request | **Critical** |
| Missing audit logging for PHI access | **Important** |
| PHI in URL parameters | **Important** |
| Missing input validation on user data | **Important** |
| Session cookie missing security flags | **Important** |
| Stale dependency with known CVE | **Important** |
| Missing rate limiting on public endpoint | **Minor** |
| Audit log missing correlation ID | **Minor** |

## Issue Severity Definitions

### Critical (Must Fix Before Merge)

Issues that:
- Introduce security vulnerabilities
- Cause data loss or corruption
- Break existing functionality
- Skip required authentication/authorization
- Commit secrets or credentials

### Important (Should Fix)

Issues that:
- Violate architecture patterns
- Have inadequate test coverage
- Include code quality problems (commented code, untracked TODOs)
- Miss required documentation updates
- Have potential performance issues

### Minor (Nice to Have)

Issues that:
- Could improve readability
- Suggest minor refactoring opportunities
- Note style inconsistencies
- Recommend additional documentation

## Anti-Patterns

- Reviewing only the diff without understanding surrounding context
- Nitpicking style when there are substantive issues
- Approving without checking test coverage
- Skipping security review on "internal" endpoints
- Reviewing only the happy path
