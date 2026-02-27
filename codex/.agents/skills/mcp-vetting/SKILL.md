---
name: mcp-vetting
description: Use when evaluating whether to install a new MCP server, reassessing an existing one, or determining whether a specific MCP is appropriate for use in a HIPAA-adjacent environment.
---

# MCP Vetting

Security evaluation before installing or trusting any MCP server. MCPs run with your session credentials and process your full context — treat them as production dependencies, not plugins.

## Core Threat Model

Three attacks that are non-theoretical:

- **Tool description poisoning** — malicious instructions embedded in tool metadata that Claude executes; model safety alignment catches <3% of these in benchmarks
- **Supply chain compromise** — malicious npm packages impersonating legitimate MCPs (Sandworm_Mode, Feb 2026: harvested SSH keys, AWS credentials, npm tokens directly from Claude Code configs)
- **Data/command blur** — tools that read external content (docs, issues, DB rows) can receive injected instructions and execute them with your credentials

## Checklist

### 1. Source & Publisher

- [ ] Publisher is a known organization with meaningful commit history and community presence
- [ ] Package name is exact — check for typosquatting (one-character-off variants)
- [ ] Listed in the official MCP Registry (`registry.modelcontextprotocol.io`) — note: this confirms namespace ownership, not code safety

### 2. Tool Descriptions (Critical)

- [ ] Read every tool description in the raw source — this is the primary poisoning surface
- [ ] Descriptions contain no instructions, conditionals, or "also do X" clauses — only functional documentation
- [ ] Parameter descriptions are typed field docs, not hidden directives

### 3. Source Code

- [ ] Review source for: outbound network calls to external URLs, `child_process.exec`, `eval`, obfuscated or minified code, hardcoded external URLs
- [ ] All outbound calls go to documented, expected endpoints — no undocumented exfiltration paths
- [ ] No writes to credential paths (`~/.ssh/`, `~/.aws/`, `.env` files)

> **Hosted MCPs (closed source):** If source is unavailable, mark this section N/A and weight Section 6 (egress policy) and publisher reputation more heavily in the verdict.

### 4. Dependencies

- [ ] `npm audit` (or `pip audit`, `cargo audit`, etc.) passes with no high or critical findings
- [ ] Versions are pinned (not `^x.y.z` or `@latest`)
- [ ] Dependency tree is shallow and recognizable — no surprise transitive packages

### 5. Permissions & Scope

- [ ] Credentials are least-privilege — no `admin:*`, `service_role`, or wildcard scopes
- [ ] You can enumerate exactly what the MCP can access given its credentials

### 6. Data Egress — HIPAA

- [ ] Provider's logging and data retention policy is stated explicitly
- [ ] If any prompt context adjacent to PHI, schema names, table names, or patient data patterns could be present when this MCP is active: require zero-egress (local or self-hosted only)
- [ ] MCP is opt-in per invocation — does not intercept every prompt automatically

## Red Flags — Reject Immediately

- Tool descriptions contain conditional logic, references to "previous messages," or instructions to "also..."
- Source is minified, obfuscated, or the repo is brand new with no history
- Requests `admin:*`, `*`, `service_role`, or equivalent credential scopes
- `npm audit` shows high or critical CVEs with no upstream fix
- Provider cannot state clearly where queries are logged and for how long
- Version constraint is `@latest` or `^x.y.z` — loose pinning is an auto-update attack surface

## Verdict

| Verdict | Criteria | Action |
|---|---|---|
| **Proceed** | All checks pass; egress documented and acceptable | Install, pin exact version, commit to dotfiles |
| **Proceed with mitigations** | Minor gaps, no red flags; manageable egress concerns | Install with scoped credentials + manual update policy |
| **Reject** | Any red flag; unclear egress in HIPAA-adjacent use; unverifiable source | Do not install; consider self-written or local alternative |

## Post-Install Controls

Regardless of verdict:

- Pin exact version — never `@latest`
- Manual update policy — re-run this checklist on every version bump before upgrading
- Re-evaluate if the MCP's scope, credentials, or behavior change
