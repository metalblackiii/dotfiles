# Remediation Strategies

## The Decision Framework

For each vulnerability, choose one of three paths:

| Decision | When | Action |
|----------|------|--------|
| **Fix** | Upgrade available, acceptable risk of breakage | Apply the upgrade |
| **Ignore** | No fix available, or accepted risk with expiry | `snyk ignore` with reason and expiry |
| **Accept** | False positive, disputed, or risk-mitigated elsewhere | Document and move on |

## Fix Strategies

### Dependency Upgrades (SCA)

**Patch bump** (1.2.3 → 1.2.4):
- Safest. Should be backward-compatible.
- Apply freely, batch with other patches.
- If tests pass, ship it.

**Minor bump** (1.2.3 → 1.3.0):
- Usually backward-compatible, may add new features.
- Review changelog for unexpected changes.
- Batch with caution — test each package's bump.

**Major bump** (1.2.3 → 2.0.0):
- Breaking changes expected. Read migration guide.
- Test thoroughly. Review individually, not batched.
- May require code changes to accommodate new API.
- For `@neb/*` packages: check if other neb services depend on the same version — coordinate upgrades.

**Transitive dependency with no direct upgrade:**
- The vulnerable package is deep in your dependency tree.
- Check if upgrading the direct parent package pulls in the fixed version.
- If not, consider `npm overrides` (npm 8.3+) to force a specific version:
  ```json
  {
    "overrides": {
      "lodash": "4.17.21"
    }
  }
  ```
- Use overrides as a last resort — they bypass the dependency resolver.

### Code Fixes (SAST)

SAST fixes require code changes. Do NOT auto-fix — present to human for review.

Common fix patterns:
- **SQL Injection:** Use parameterized queries (Sequelize does this by default — check for raw queries)
- **XSS:** Sanitize output, use template escaping
- **Path Traversal:** Validate and normalize paths, use `path.resolve()` + check against allowed directory
- **Command Injection:** Use `execFile` instead of `exec`, avoid string interpolation in commands
- **Hardcoded Secrets:** Move to environment variables or secrets manager

### Container Fixes

**Base image upgrade:**
- Highest-impact single change — often fixes dozens of OS vulns.
- Update the `FROM` line in Dockerfile.
- Rebuild and rescan to verify improvement.

**Remove unnecessary packages:**
- Multi-stage builds: keep build tools in builder stage only.
- `apt-get remove` or `apk del` after build steps.
- Use `--no-install-recommends` with apt.

## Ignore Strategy

### When to Ignore

- No fix is available from the maintainer
- The vulnerability is in a function your code never calls (unreachable)
- The vulnerability is disputed (`isDisputed: true`)
- Risk is mitigated by other controls (WAF, network segmentation, input validation)
- Internal tool where the "untrusted input" is actually trusted (CLI args for internal CLI)

### How to Ignore

```bash
# With expiry (re-evaluate in 90 days) and audit reason
snyk ignore --id='SNYK-JS-LODASH-567746' \
  --expiry='2026-06-06' \
  --reason='No fix available. Unreachable in our code. Re-evaluate next quarter.'
```

Always include:
- **Reason** — why this is acceptable
- **Expiry** — when to re-evaluate (30-90 days is typical)
- **Ticket reference** — if tracked in Jira, include the ticket number in the reason

### Dashboard vs `.snyk` File

The neb team uses dashboard ignores. This is fine — the skill should respect whatever ignore method is in place. Dashboard-ignored vulns won't appear in `snyk test --json` results (they show in `filtered.ignore`).

## Rollback Safety

### Atomic Commits

Each fix should be its own commit:

```
fix(deps): upgrade lodash 4.17.20 → 4.17.21 (CVE-2021-23337)
fix(deps): upgrade express 4.17.1 → 4.18.0 (CVE-2024-XXXXX)
fix(docker): upgrade base image node:24-trixie-slim → node:24.1-trixie-slim
```

Benefits:
- `git revert <hash>` cleanly undoes one fix
- `git bisect` identifies which upgrade broke something
- Each commit references the CVE for audit trail

### Branch Strategy

```bash
git checkout -b fix/snyk-remediation-2026-03-06
# Apply fixes as atomic commits
# Run tests after each commit
# PR for review
```

### Validation After Each Fix

1. Update package.json
2. `npm install` (regenerate lockfile)
3. `snyk test --json` (verify vuln is gone, no new vulns)
4. `npm test` (existing tests pass)
5. If pass → commit. If fail → revert and report.

## Batch Remediation

### Grouping by Risk Tier

| Batch | Contents | Approval |
|-------|----------|----------|
| 1 | Critical/High + upgradable + direct | Fix first, individually if needed |
| 2 | Medium + semver-compatible fix | Batch approve |
| 3 | Major version bumps | Individual review per package |
| 4 | Low severity / no fix | Skip or ignore |

### Per-Package Grouping

When one package upgrade fixes multiple CVEs, present as a single action:

```
axios 0.21.1 → 1.6.0 (MAJOR)
  Fixes: SNYK-JS-AXIOS-1234 (SSRF), SNYK-JS-AXIOS-5678 (ReDoS), SNYK-JS-AXIOS-9012 (Header Injection)
  Breaking changes: response.data structure changed, interceptor API modified
```

## AI Remediation Landscape

Current state of AI-assisted vulnerability fixing (for context when evaluating tools):

| Approach | Success Rate | Notes |
|----------|-------------|-------|
| SCA (version bump) | High | Deterministic — Snyk provides exact version |
| SAST (code fix) via Snyk Agent Fix | ~80% (IDE only) | Uses CodeReduce to minimize context |
| SAST (code fix) via Copilot Autofix | >66% | CodeQL + GPT-4o, GitHub-only |
| SAST (code fix) via raw LLM | ~5-11% | Meta's AutoPatchBench — most fail full verification |

Key insight: SCA remediation is reliable enough to automate. SAST remediation is not — always present for human review.
