# Security Deep Dive

Extended security review criteria for healthcare applications operating under HIPAA. Load this reference when reviewing PRs that touch authentication, authorization, patient data, audit logging, or encryption.

## HIPAA & PHI

### Data Classification

| Classification | Examples | Handling |
|---------------|---------|----------|
| **PHI** (Protected Health Information) | Patient name + diagnosis, SSN, DOB, insurance ID, appointment details | Encrypted at rest and in transit, access logged, never in logs/errors |
| **PII** (Personally Identifiable Information) | Name, email, phone, address (without health context) | Encrypted in transit, access controlled, minimal logging |
| **Internal** | Tenant config, feature flags, provider schedules | Standard access controls, no special encryption required |
| **Public** | Marketing content, pricing tiers, office hours | No restrictions |

### PHI Review Checklist

- [ ] PHI never appears in log messages, error responses, or stack traces
- [ ] PHI not stored in browser localStorage/sessionStorage
- [ ] PHI not included in URL parameters (use POST body or encrypted tokens)
- [ ] PHI not cached in CDN or browser cache (appropriate Cache-Control headers)
- [ ] PHI access restricted to authenticated users with appropriate role/tenant
- [ ] PHI queries filtered by tenant ID (no cross-tenant data leakage)
- [ ] PHI exports (CSV, PDF) respect the same access controls as the UI

### Multi-Tenant Data Isolation

- [ ] All database queries include tenant ID filter
- [ ] No endpoint returns data across tenants without explicit admin authorization
- [ ] Tenant ID derived from authenticated session, never from request parameters
- [ ] Shared tables (lookups, config) don't contain tenant-specific PHI
- [ ] Background jobs/workers scope to single tenant per execution

## Authentication Lifecycle

### Token Management

- [ ] JWTs validated on every request (not just at login)
- [ ] Token expiration enforced server-side (don't trust client clocks)
- [ ] Refresh tokens rotated on use (one-time use)
- [ ] Token revocation supported (logout invalidates all sessions)
- [ ] Token payload contains minimal claims (no PHI, no full permissions list)

### Cognito Patterns (neb-specific)

- [ ] `userSecurity` middleware applied to all authenticated routes
- [ ] `SECURITY_SCHEMA_KEYS` used for permission validation
- [ ] Cognito user pool ID not hardcoded (from environment)
- [ ] Pre-token-generation Lambda not leaking sensitive attributes
- [ ] MFA enforcement checked for admin/elevated operations

### Session Security

- [ ] Session cookies marked HttpOnly, Secure, SameSite=Strict
- [ ] Session timeout enforced (idle and absolute)
- [ ] Session invalidated on password change
- [ ] Concurrent session limits enforced (if required by policy)

## Authorization Patterns

### Role-Based Access

- [ ] Permissions checked at the route/endpoint level (middleware)
- [ ] Permissions also checked at the service level (defense in depth)
- [ ] No client-side-only permission checks (always server-validated)
- [ ] Permission changes take effect immediately (no stale cached permissions)
- [ ] Elevation of privilege requires re-authentication

### Entitlement Checks

- [ ] Feature entitlements checked server-side, not just UI gating
- [ ] Entitlement cache invalidated on subscription changes
- [ ] Downgrade paths handle graceful feature removal (no data loss)
- [ ] Entitlement checks use the facade/abstraction layer (e.g., `hasEntitlement()`), not direct addon checks

## Audit Logging

### What Must Be Logged

| Event | Required Fields | Severity |
|-------|----------------|----------|
| Login success/failure | userId, tenantId, IP, timestamp, method | Info/Warn |
| PHI access (read) | userId, tenantId, patientId, resource, timestamp | Info |
| PHI modification | userId, tenantId, patientId, resource, before/after, timestamp | Info |
| Permission changes | adminId, targetUserId, oldPerms, newPerms, timestamp | Warn |
| Failed authorization | userId, resource, requiredPerm, timestamp | Warn |
| Data export | userId, tenantId, exportType, recordCount, timestamp | Info |
| Account lockout | userId, failedAttempts, lockDuration, timestamp | Warn |

### Audit Log Rules

- [ ] Audit logs are append-only (no modification or deletion)
- [ ] Audit logs stored separately from application logs
- [ ] Audit log entries include correlation ID for request tracing
- [ ] PHI in audit logs is minimized (patient ID, not patient name)
- [ ] Audit logs retained per HIPAA retention policy (minimum 6 years)
- [ ] Audit log access itself is logged

## Encryption

### At Rest

- [ ] Database encryption enabled (Aurora/RDS encryption)
- [ ] S3 buckets use SSE (server-side encryption)
- [ ] Backups encrypted with separate key from production
- [ ] Encryption keys managed via KMS (not application-managed)

### In Transit

- [ ] TLS 1.2+ enforced on all endpoints
- [ ] Internal service-to-service communication encrypted
- [ ] Database connections use SSL
- [ ] No sensitive data in query strings (use headers or body)

### Application-Level

- [ ] Passwords hashed with bcrypt/scrypt/argon2 (not MD5/SHA)
- [ ] API keys and secrets in environment variables or secrets manager (not code)
- [ ] Encryption/signing keys rotated on schedule
- [ ] No custom cryptography (use established libraries)

## Input Validation (Extended)

Beyond the basic SKILL.md checklist:

- [ ] File uploads validated (type, size, content — not just extension)
- [ ] File uploads scanned or sandboxed before processing
- [ ] JSON payloads size-limited (prevent DoS via large payloads)
- [ ] Nested object depth limited (prevent prototype pollution)
- [ ] URL/redirect parameters validated against allowlist (prevent open redirect)
- [ ] GraphQL queries depth-limited (if applicable)
- [ ] Batch endpoints have item count limits

## Dependency Security

- [ ] `npm audit` / `yarn audit` shows no high/critical vulnerabilities
- [ ] Dependencies with known CVEs have upgrade path or mitigation documented
- [ ] No dependencies pulled from unofficial registries
- [ ] Lock file committed and reviewed for unexpected changes
- [ ] Transitive dependencies reviewed for known supply chain risks

## Quick Reference: Severity Mapping

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
