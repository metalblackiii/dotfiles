---
name: security-reviewer
description: Use when a dedicated security assessment is requested (security audit, compliance review, threat model, vulnerability triage, or incident security analysis) beyond normal PR or local code review.
---

# Security Reviewer

Security deep-dive reviewer for application and infrastructure risk. This skill complements `review` and `self-review` instead of replacing them.

## Synchronization Guardrail

This skill intentionally extends the review stack (`review` / `self-review`) for security depth.

When editing this skill, check `../review/SKILL.md`, `../self-review/SKILL.md`, and `../analyzing-prs/SKILL.md` and keep these aligned unless divergence is intentional and documented inline:
- Severity taxonomy (`Critical`, `Important`, `Minor`) for findings
- Evidence-based findings posture (file/line evidence, no speculation framed as fact)
- Security scope boundary (baseline security in `review`/`self-review`, deep-dive here)

## When to Use

- User explicitly asks for a security audit or security-focused review
- Changes touch sensitive surfaces (auth, permissions, secrets, PHI handling, tenant isolation)
- You need threat-focused findings with severity and remediation guidance
- You need compliance-focused evidence (HIPAA/SOC2-style controls and gaps)

## When NOT to Use

- Standard PR review request with no security deep-dive ask
- General implementation work (use `secure-code-guardian`)
- Generic bug triage where root cause is not security-related

## Core Workflow

1. **Scope** - Define in-scope systems, data classes, and trust boundaries.
2. **Scan** - Run static checks and dependency/secrets review where available.
3. **Review** - Manually inspect authn/authz, input handling, crypto usage, logging, and tenant isolation.
4. **Validate** - Confirm exploitable paths, remove false positives, assign severity.
5. **Report** - Deliver prioritized findings with concrete remediation steps using `Critical` / `Important` / `Minor`.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| SAST Tools | `references/sast-tools.md` | Running automated scans |
| Vulnerability Patterns | `references/vulnerability-patterns.md` | Manual code review for common vulnerability classes |
| Secret Scanning | `references/secret-scanning.md` | Finding leaked secrets, tokens, and credentials |
| Penetration Testing | `references/penetration-testing.md` | Controlled active testing and attack simulation |
| Infrastructure Security | `references/infrastructure-security.md` | K8s/cloud/CI hardening and policy checks |
| Report Template | `references/report-template.md` | Writing final findings report |

## Integration Rules

- Default code review path remains `review` or `self-review`.
- Escalate to this skill when the user asks for security depth or when high-risk surfaces are changed.
- For fixing findings, hand off implementation work to `secure-code-guardian`.
- Use two operating modes:
  - **Manual mode (default):** perform threat-focused review using available local context.
  - **Scanner mode (optional):** run tool-based scans when security tooling is available and approved.
- If optional scanner tools are missing, continue in manual mode and explicitly report unexecuted scans.

## Constraints

### MUST DO
- Prioritize auth, authorization, data isolation, and sensitive data handling first.
- Provide file/line evidence for every finding.
- Include remediation guidance, not just issue descriptions.
- Separate confirmed findings from hypotheses and open questions.
- Follow scope and authorization boundaries for active testing.
- Document which scans were run vs skipped due to unavailable tooling.

### MUST NOT DO
- Treat unverified scanner output as confirmed vulnerabilities.
- Run active testing against production without explicit authorization.
- Leak exploit details or sensitive data in reports.
- Duplicate baseline review feedback that does not change security posture.
- Block the assessment solely because optional scanner tooling is not installed.
