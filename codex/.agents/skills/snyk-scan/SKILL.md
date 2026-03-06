---
name: snyk-scan
description: Use when scanning a repository for security vulnerabilities and applying fixes. Triggers on "run snyk", "scan for vulnerabilities", "fix security issues", "remediate dependencies", "snyk scan", "security scan this repo", or any request to find and fix known vulnerabilities in dependencies, container images, or source code. Not for interpreting results or advisory — use snyk-expert for that.
---

# Snyk Scan

Automated scan-assess-fix workflow for Node.js repositories using Snyk CLI. Scans dependencies (SCA), source code (SAST), and container images, then applies approved fixes as atomic commits.

## When to Use

- Scanning a repo for known vulnerabilities
- Remediating dependency vulnerabilities with upgrades
- Assessing container base image security
- Running a security scan before a release or as periodic hygiene

## When NOT to Use

- Interpreting a specific vulnerability or Snyk output — use `snyk-expert`
- Implementing security controls in code — use `secure-code-guardian`
- Deep security audit or threat modeling — use `security-reviewer`

## Prerequisites

- Snyk CLI installed: `brew tap snyk/tap && brew install snyk`
- Authenticated: `snyk auth` (or `SNYK_TOKEN` env var)
- Verify with: `snyk whoami --experimental`

If prerequisites fail, stop and help the user set up before proceeding.

## Workflow

### Phase 1: SCAN

Run all applicable scan types. Capture JSON output for parsing.

```bash
# SCA — dependency vulnerabilities
snyk test --json --all-projects > /tmp/snyk-sca.json 2>/tmp/snyk-sca.log

# SAST — source code issues (report-only in v1)
snyk code test --json > /tmp/snyk-sast.json 2>/tmp/snyk-sast.log

# Container — only if Dockerfile exists
# Detect image name from Dockerfile's FROM line, or ask user
snyk container test <image> --json --file=Dockerfile > /tmp/snyk-container.json 2>/tmp/snyk-container.log
```

**Exit codes:** 0 = no vulns, 1 = vulns found, 2 = CLI error. Exit code 1 is expected — parse the JSON, don't treat it as failure.

Skip container scanning if no Dockerfile exists. If multiple Dockerfiles exist, scan each.

### Phase 2: ASSESS

Parse JSON results and build a unified assessment. Load `snyk-expert` knowledge for interpretation.

**SCA results — group by package:**
- Package name + current version + fix version
- Severity (Critical/High/Medium/Low)
- Number of CVEs fixed by upgrading
- Upgrade type (patch/minor/major)
- Direct vs transitive dependency
- Whether an upgrade path exists (`isUpgradable`)

**Verify every upgrade path before presenting it.** Snyk's `isUpgradable` and `upgradePath` fields can be misleading — an "upgradable" transitive dependency may require a major version bump of its parent. For each fixable vuln:

1. Check `.upgradePath` in the JSON — if it jumps a major version of any package in the chain, flag it as a major bump, not a safe upgrade
2. For minor bumps spanning 3+ versions, check the changelog for breaking changes — semver compliance is not guaranteed
3. For transitive deps locked behind `@neb/*` or other internal packages, mark as "blocked by upstream" rather than "fixable"
4. Only label an upgrade "safe" if it is a direct dependency patch/minor bump with no documented breaking changes, or a transitive patch with a verified upgrade chain

**SAST results — report only:**
- File path + line number
- CWE and rule ID
- Severity
- Present for awareness — no auto-fix in v1

**Container results — group by recommendation:**
- Current base image vs recommended alternatives
- Number of vulns fixed by upgrading
- Present upgrade options with vuln count reduction

**Present the assessment as a grouped summary:**

```
## SCA Findings: X vulnerabilities across Y packages

### Critical/High (N findings)
| Package | Current | Fix | Type | CVEs Fixed | Direct? |
|---------|---------|-----|------|------------|---------|

### Medium (N findings)
...

### Low (N findings)
...

## SAST Findings: X issues (report-only)
| File | Line | CWE | Severity | Description |
|------|------|-----|----------|-------------|

## Container Findings
| Current Image | Recommended | Vulns Removed |
|---------------|-------------|---------------|
```

**Prioritization order** (from `snyk-expert` knowledge):
1. Critical/High + direct dependency + patch/minor upgrade = fix first
2. Critical/High + transitive + upgradable = fix second
3. Medium + semver-compatible fix = batch
4. Major version bumps = individual review
5. No fix available = ignore with expiry or accept

### Phase 3: APPROVE (Human Gate)

Present each risk tier as a batch. The human approves, skips, or modifies each batch.

```
Batch 1: Critical/High with verified safe upgrades (N packages)
  - lodash 4.17.20 -> 4.17.21 (patch, fixes 2 CVEs) — VERIFIED: direct patch bump
  - body-parser 1.20.3 -> 1.20.4 (patch, fixes qs) — VERIFIED: changelog reviewed
  Approve this batch? [y/n/edit]

Batch 2: Medium severity (N packages)
  ...

Batch 3: Major bumps / unverified upgrades (N packages)
  - glob 10.5.0 -> 12.0.0 (MAJOR — breaking API changes confirmed)
  - axios 1.7.9 -> 1.13.5 (minor but 6 versions gap — changelog review needed)
  ...

Batch 4: Container base image upgrades
  ...
```

**Do not proceed without explicit human approval for each batch.** Log which batches were approved and which were skipped.

After approval, before any changes: **ask the user for a branch name.** Suggest `fix/snyk-remediation-YYYY-MM-DD` but use whatever they provide. Create and switch to the branch only after they confirm the name.

### Phase 4: REMEDIATE

For each approved fix, apply as an atomic commit on the dedicated branch.

**Per-fix loop (SCA):**

1. Update version in `package.json`
2. Run `npm install` to regenerate lockfile
3. Run `snyk test --json` and verify the specific vuln is resolved
4. Run `npm test` (if test suite exists)
5. If both pass — stage the changes and present the commit message to the user for approval:
   ```
   fix(deps): upgrade <package> <old> -> <new> (<CVE-IDs>)
   ```
   Do not commit until the user explicitly approves.
6. If either fails — revert changes, report failure, continue to next fix

**Per-fix loop (Container):**

1. Update `FROM` line in Dockerfile
2. Run `snyk container test <new-image> --json --file=Dockerfile`
3. Verify improvement (fewer vulns)
4. Stage changes and present commit message for user approval:
   ```
   fix(docker): upgrade base image <old> -> <new>
   ```
   Do not commit until the user explicitly approves.

**Failure handling:** A failed fix does not block subsequent fixes. Report all failures at the end.

### Phase 5: REPORT

Summarize the session:

```
## Remediation Summary

Applied: X fixes across Y packages
Skipped: N batches (user choice)
Failed: M fixes (details below)

### Applied Fixes
- lodash 4.17.20 -> 4.17.21 (CVE-2021-23337) [commit abc1234]
- ...

### Failed Fixes
- axios 0.21.1 -> 1.7.0: npm test failed (test:integration suite)

### Remaining Vulnerabilities
- N unfixed SCA vulns (no upgrade path available)
- M SAST findings for manual review

### SAST Findings (Manual Review Needed)
- src/api/handler.js:42 — CWE-89 SQL Injection (High)
- ...

### Suggested Next Steps
- Create PR from fix/snyk-remediation-YYYY-MM-DD
- Review SAST findings manually
- Set snyk ignore with expiry for accepted risks
```

Offer to create the PR if the user wants.

## Constraints

### MUST DO
- Verify Snyk CLI is installed and authenticated before scanning
- Parse exit code 1 as "vulns found" not "error" — only exit code 2 is a real error
- Verify every upgrade path before presenting it — check `.upgradePath` for hidden major bumps, review changelogs for multi-version minor jumps, and flag transitive deps blocked by internal packages
- Present ALL findings before asking for approval — no partial assessments
- Get explicit human approval before every remediation batch
- Make each fix an atomic commit with CVE references
- Run tests after each fix — revert on failure
- Report SAST findings for awareness even though they aren't auto-fixed
- Ask the user for the branch name before creating one

### MUST NOT DO
- Auto-fix without human approval — the approval gate is non-negotiable
- Auto-fix SAST findings — code-level fixes require human judgment (only 5-11% of AI code fixes survive verification)
- Batch multiple package upgrades into a single commit — atomic commits enable clean reverts
- Continue after `snyk test` exit code 2 — that's a CLI error, investigate first
- Present semver assumptions as verified facts — "minor bump" does not mean "safe" without checking the actual upgrade path and changelog
- Assume container image names — read from Dockerfile or ask the user
- Create branches without asking the user for the name first

## Related Skills

- **snyk-expert** — vulnerability interpretation, CLI flags, prioritization knowledge
- **secure-code-guardian** — implementing security controls for SAST findings
- **security-reviewer** — deep security audits beyond dependency scanning
- **verification-before-completion** — verify fixes actually resolved the vulnerabilities
