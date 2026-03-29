---
name: snyk-expert
description: ALWAYS invoke for interpreting Snyk scan results, understanding CVEs or CWEs, prioritizing vulnerabilities, choosing Snyk CLI flags, configuring Snyk for a repo, evaluating dependency upgrade risk, assessing container base image security, or deciding whether to fix, ignore, or accept a vulnerability. Also triggers on "is this exploitable", "should I upgrade this package", "what does this snyk output mean", or general application security scanning questions. Not for running scans or applying fixes — use snyk-scan for that.
---

# Snyk Expert

Security scanning specialist for Node.js applications using Snyk CLI. Covers vulnerability interpretation, severity prioritization, dependency upgrade risk assessment, container image security, SAST vs SCA analysis, and Snyk CLI configuration across an Enterprise org.

## When to Use

- Interpreting `snyk test`, `snyk code test`, or `snyk container test` output
- Understanding a specific CVE, CWE, or Snyk vulnerability ID
- Deciding whether a vulnerability needs fixing, ignoring, or accepting
- Choosing the right Snyk CLI flags for a scan
- Evaluating whether a dependency upgrade is safe (breaking changes, transitive impact)
- Assessing container base image options and upgrade paths
- Configuring Snyk for a new repo (org settings, `.snyk` policy files)
- Prioritizing a list of vulnerabilities by real-world risk
- Understanding SAST findings (code-level issues vs dependency issues)

## When NOT to Use

- Running an automated scan-fix workflow — use `snyk-scan`
- General code review without security focus — use `review` or `self-review`
- Implementing security controls in code — use `secure-code-guardian`
- Deep security audit of a system — use `security-review`

## Core Concepts

### SCA vs SAST vs Container

| Scan Type | Command | Finds | Fix Type |
|-----------|---------|-------|----------|
| **SCA** (dependencies) | `snyk test` | Known CVEs in npm packages | Version upgrade |
| **SAST** (source code) | `snyk code test` | Security anti-patterns you wrote | Code rewrite |
| **Container** | `snyk container test` | OS package vulns + base image issues | Base image upgrade |

SCA fixes are deterministic (Snyk tells you the exact version). SAST fixes require understanding application logic. Always prioritize SCA — higher success rate, lower risk.

### Severity Is Not Priority

Raw severity (Critical/High/Medium/Low) is a starting point, not a decision. Real priority combines:

1. **Severity** (CVSS score) — how bad is it in theory?
2. **Exploitability** (EPSS score) — is anyone actually exploiting this?
3. **Reachability** — does your code call the vulnerable function?
4. **Upgradability** — is there a fix available? Is it semver-compatible?
5. **Dependency depth** — direct dependency (you control) vs deep transitive (harder)?

A Critical vuln in an unreachable transitive dependency is lower priority than a High vuln in a direct dependency that your code calls.

### The Upgrade Risk Spectrum

| Upgrade Type | Risk | Approach |
|-------------|------|----------|
| Patch bump (1.2.3 → 1.2.4) | Minimal | Batch freely, auto-approve candidate |
| Minor bump (1.2.3 → 1.3.0) | Low | Review changelog, batch with caution |
| Major bump (1.2.3 → 2.0.0) | Significant | Read migration guide, test thoroughly, individual review |
| No fix available | N/A | Accept risk, document, set ignore with expiry |

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| CLI Commands & Flags | `references/cli-commands.md` | Choosing scan flags, understanding CLI options, exit codes |
| JSON Output Schemas | `references/json-schemas.md` | Parsing scan output, building jq filters, understanding fields |
| Vulnerability Prioritization | `references/prioritization.md` | Triaging results, CVSS vs EPSS, reachability, risk frameworks |
| Container Scanning | `references/container-scanning.md` | Docker image security, base image selection, Dockerfile scanning |
| SAST Interpretation | `references/sast-guide.md` | Understanding code-level findings, CWE patterns, false positives |
| Auth & Configuration | `references/auth-config.md` | Setting up Snyk, org config, tokens, permissions, `.snyk` policy |
| Remediation Strategies | `references/remediation.md` | Fix vs ignore vs accept decisions, upgrade strategies, rollback |

## Constraints

### Vulnerability Lookup Order

When investigating a specific vulnerability (Snyk ID, CVE, or CWE):

1. **Run `snyk test --json` in the affected repo** and filter with jq — this gives your actual dependency chain, upgrade paths, and whether it's fixable in your context. Always prefer this over web lookups.
2. **`WebSearch` for the Snyk ID or CVE** — search snippets from snyk.io return severity, affected versions, and fix versions without needing to render the page.
3. **Do NOT rely on `WebFetch` for Snyk advisory pages** — they are JS-rendered and return empty CSS. The first two steps provide better data anyway.

```bash
# Look up a specific vuln in your repo
snyk test --json | jq '[.vulnerabilities[] | select(.id == "SNYK-JS-EXAMPLE-123") | {id, title, severity, CVSSv3, packageName, version, from, upgradePath, isUpgradable, identifiers, semver}] | .[0]'
```

### MUST DO
- Get vulnerability context from the CLI (`snyk test --json`) first — it includes your actual dependency chain, not generic advisory info
- Assess reachability before recommending urgency — an unreachable vuln is not urgent
- Flag breaking changes explicitly when recommending major version upgrades
- Distinguish between direct and transitive dependency vulnerabilities
- Account for the neb ecosystem — `@neb/*` packages from private registry may have interdependencies
- Elevate patient data exposure vulns regardless of CVSS — HIPAA context applies
- Recommend `snyk ignore` with expiry and reason for accepted risks — not silent skips

### MUST NOT DO
- Recommend upgrading without checking if the fix version exists and is compatible
- Treat all Critical/High vulns as equally urgent — prioritize by exploitability and reachability
- Ignore transitive dependency chains — a vuln in `lodash` via `express` is different from `lodash` direct
- Dismiss SAST findings as false positives without examining the data flow
- Recommend `--severity-threshold=high` as a default — this hides medium-severity vulns that may matter

## Related Skills

- **snyk-scan** — automated scan-assess-fix workflow
- **secure-code-guardian** — implementing security controls in application code
- **security-review** — deep security audits and threat modeling
- **neb-ms-conventions** — neb service patterns (relevant for understanding dependency usage)
