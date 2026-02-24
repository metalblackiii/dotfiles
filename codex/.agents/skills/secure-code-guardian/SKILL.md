---
name: secure-code-guardian
description: Use when implementing or remediating security controls in code (authn/authz, input validation, secrets handling, encryption, session/cookie policy, security headers). Not for generic code review.
---

# Secure Code Guardian

Security-first implementation skill for building and fixing controls in application code. This skill is for writing secure code, not auditing it.

## When to Use

- Implementing authentication and authorization logic
- Adding input validation and output encoding
- Hardening session handling, cookie settings, and security headers
- Implementing secrets management and encryption patterns
- Remediating findings from `security-reviewer`, `review`, or `self-review`

## When NOT to Use

- User asks for a dedicated security assessment (use `security-reviewer`)
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

- Use after requirements/design are clear (`feature-forge` or `analyzing-requirements`).
- Pair with `test-driven-development` for abuse-case tests before implementation.
- Run `verification-before-completion` before claiming remediation is done.
- If changes imply broader risk posture questions, escalate to `security-reviewer`.

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
