---
name: secure-code-guardian
description: ALWAYS invoke when implementing or remediating security controls (authn/authz, input validation, secrets handling, encryption, session/cookie policy, security headers). Do not implement security controls directly. Not for generic code review or security audits (use security-review).
---

# Secure Code Guardian

Security-first implementation skill for building and fixing controls in application code. This skill is for writing secure code, not auditing it.

## When to Use

- Implementing authentication and authorization logic
- Adding input validation and output encoding
- Hardening session handling, cookie settings, and security headers
- Implementing secrets management and encryption patterns
- Remediating findings from `security-review`, `review`, or `self-review`

## When NOT to Use

- User asks for a dedicated security assessment (use `security-review`)
- Routine feature coding with no security-sensitive changes
- PR quality gate tasks (use `review` or `self-review`)

## Core Workflow

1. **Threat model** - Identify attacker paths and sensitive assets for the change.
2. **Design controls** - Choose layered controls (validation, authz, rate limit, audit logging).
3. **Implement** - Apply secure defaults and least privilege patterns.
4. **Verify** - Add tests for abuse cases and failure paths.
5. **Harden** - Check logs/errors for data leakage and operational misconfiguration.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| OWASP Prevention | `references/owasp-prevention.md` | Mapping implementation choices to OWASP risks |
| Authentication | `references/authentication.md` | Password/JWT/session/OAuth patterns |
| Input Validation | `references/input-validation.md` | Validation, sanitization, and injection defenses |
| XSS & CSRF | `references/xss-csrf.md` | Browser-side and API-side protections |
| Security Headers | `references/security-headers.md` | Header policy and transport hardening |

## Integration Rules

- Use after requirements/design are clear (`create-prd` or `requirements-analyst`).
- Pair with `test-driven-development` for abuse-case tests before implementation.
- Run `verification-before-completion` before claiming remediation is done.
- If changes imply broader risk posture questions, escalate to `security-review`.

## Constraints

### MUST DO
- Validate all untrusted inputs server-side.
- Enforce authorization on every sensitive operation.
- Use parameterized queries and safe serialization/encoding.
- Keep secrets out of source, logs, and client-exposed payloads.
- Fail closed when security checks fail.

### MUST NOT DO
- Trust client-only validation.
- Expose PHI/PII in logs or error responses.
- Hardcode credentials, tokens, or cryptographic material.
- Bypass controls for convenience in production paths.

## Validation Checkpoints

After implementation, verify these before claiming done:

| Control | Verification |
|---------|-------------|
| Brute-force protection | Rate limiter active on auth endpoints; lockout triggers after threshold |
| Privilege escalation | No path lets a lower-role user reach admin-only operations |
| SQL injection | Parameterized queries only — search for string interpolation in queries |
| XSS | User-supplied data is encoded in HTML/JSON output; CSP header present |
| Secrets exposure | No tokens, keys, or PHI in logs, error responses, or client payloads |
| Transport | HSTS, Secure cookie flag, no mixed content |
| JWT validation | Algorithm allowlist enforced; issuer + audience claims verified; secret from env |

## Output Checklist

When delivering security implementation work, include:

1. Secure implementation code (with references to patterns in `references/`)
2. Security considerations — what threats this addresses and residual risks
3. Configuration requirements — env vars, secrets, infrastructure dependencies
4. Testing recommendations — abuse-case tests to add
