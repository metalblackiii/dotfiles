---
name: analyzing-prs
description: Domain knowledge for PR review checklists and quality criteria. Consumed by the review and self-review skills — not invoked directly.
user-invocable: false
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
- [ ] No ORM/database queries inside loops — fetch data before the loop or use bulk operations
- [ ] No sequential `await` in loops where iterations are independent — use `Promise.all` or batched concurrency
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

## Security Deep Dive (Escalation Boundary)

`analyzing-prs` provides baseline security checks for standard `review` and `self-review` workflows.

For dedicated security audits and tool-assisted deep analysis, escalate to `security-reviewer`.

### Baseline Healthcare Addendum (Apply When Relevant)

Apply these checks when a diff touches PHI, auth/authz, tenant scoping, or audit logging:

- [ ] PHI never appears in log messages, error responses, or stack traces
- [ ] PHI not stored in browser localStorage/sessionStorage and not included in URL parameters
- [ ] PHI endpoints enforce authentication and tenant-scoped authorization
- [ ] Tenant ID derived from authenticated session, never directly from request parameters
- [ ] No cross-tenant data access paths (queries, exports, background jobs)
- [ ] `userSecurity` middleware applied on authenticated neb routes (if applicable)
- [ ] `SECURITY_SCHEMA_KEYS` used for permission validation in neb routes (if applicable)
- [ ] Cognito/user-pool identifiers and token settings come from configuration, not hardcoded values
- [ ] Audit logging exists for PHI access/modification with minimally necessary data
- [ ] Session cookies use HttpOnly/Secure/SameSite when cookie-based sessions are used

### Use `security-reviewer` For Deep-Dive Checks

- OWASP-class vulnerability analysis (SQLi, XSS, IDOR, deserialization, etc.)
- Secrets scanning, SAST, dependency/CVE, and IaC security scanning
- Pen-testing or adversarial validation workflows
- Infrastructure/Kubernetes/cloud hardening and compliance automation

### Baseline Security Severity Quick Reference

| Finding | Severity |
|---------|----------|
| PHI in logs or error responses | **Critical** |
| Missing tenant scoping on PHI query/export | **Critical** |
| Missing authentication/authorization on sensitive endpoint | **Critical** |
| PHI in URL parameters or browser storage | **Important** |
| Missing audit logging for PHI access/modification | **Important** |
| Session cookie missing required security flags | **Important** |
| Missing rate limiting on public high-risk endpoint | **Minor** |
| Audit log missing request/correlation identifier | **Minor** |

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
