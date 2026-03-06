# Snyk CLI Commands & Flags

## Quick Reference

| Command | Purpose | Output |
|---------|---------|--------|
| `snyk test` | SCA — dependency vulnerabilities | JSON (`vulnerabilities[]`) |
| `snyk code test` | SAST — source code issues | SARIF 2.1.0 |
| `snyk container test` | Container image vulns | JSON + base image remediation |
| `snyk monitor` | Upload snapshot for continuous monitoring | Project URL |
| `snyk ignore` | Suppress a vulnerability with policy | Updates `.snyk` file |
| `snyk sbom` | Generate SBOM (CycloneDX/SPDX) | SBOM document |

## Exit Codes (consistent across all test commands)

| Code | Meaning | Action |
|------|---------|--------|
| 0 | No vulnerabilities found | Clean scan |
| 1 | Vulnerabilities found | Parse and triage results |
| 2 | CLI error | Check auth, network, project config |
| 3 | No supported projects detected | Check manifest files exist |

To capture results regardless of exit code: `snyk test --json || true`

## `snyk test` (SCA)

Scans dependency manifests for known vulnerabilities in third-party packages.

### Essential Flags

| Flag | When to Use |
|------|-------------|
| `--json` | Always — machine-readable output for parsing |
| `--json-file-output=<PATH>` | Save JSON to file (works with or without `--json` on stdout) |
| `--all-projects` | Monorepos or repos with multiple manifests |
| `--detection-depth=<N>` | Limit subdirectory search depth (use with `--all-projects`) |
| `--severity-threshold=<low\|medium\|high\|critical>` | Only report vulns at this level or above |
| `--fail-on=<all\|upgradable\|patchable>` | Exit 1 only when fixable vulns exist |
| `--org=<ORG_ID>` | Target specific Snyk org (default: configured org) |
| `--dev` | Include devDependencies in scan |
| `--print-deps` | Show dependency tree before results |
| `--prune-repeated-subdependencies` | Deduplicate transitive dependency paths |
| `--policy-path=<PATH>` | Custom `.snyk` policy file location |

### Recommended Scan Command

```bash
# Full scan with JSON output, all severity levels
snyk test --json --all-projects --json-file-output=snyk-sca-results.json || true

# Focused: only show fixable vulnerabilities
snyk test --json --fail-on=upgradable || true

# With org pinned
snyk test --json --org=chirotouch-cloud --all-projects || true
```

### Language-Specific Flags

**Node.js:**
- `--strict-out-of-sync=true` — fail if lockfile doesn't match package.json
- `--yarn-workspaces` — detect Yarn workspaces only

**Python:**
- `--command=python3` — specify Python version
- `--skip-unresolved=true` — skip packages that can't be resolved

**Java:**
- `--maven-aggregate-project` — scan Maven aggregate projects
- `--all-sub-projects` — test all Gradle sub-projects
- `--scan-unmanaged` — test individual JAR/WAR files

## `snyk code test` (SAST)

Scans source code for security anti-patterns (SQL injection, XSS, path traversal, etc.).

### Key Differences from SCA

- No `critical` severity level — only High, Medium, Low
- Output is SARIF 2.1.0 format (even with `--json`)
- No fix version — requires code changes
- `.snyk` file ignores do NOT work for SAST findings
- If no issues found, `--json-file-output` does NOT create the file

### Essential Flags

| Flag | When to Use |
|------|-------------|
| `--json` | Machine-readable output (SARIF format) |
| `--json-file-output=<PATH>` | Save to file |
| `--sarif` | Explicit SARIF output (same as `--json` for code) |
| `--severity-threshold=<low\|medium\|high>` | Filter by severity (no `critical`) |
| `--org=<ORG_ID>` | Target org |
| `--report` | Share results with Snyk web dashboard |

### Recommended Scan Command

```bash
# Full SAST scan
snyk code test --json --json-file-output=snyk-sast-results.json || true

# Only high severity
snyk code test --json --severity-threshold=high || true
```

### SAST Must Be Enabled

Snyk Code (SAST) must be enabled in the Snyk dashboard under Settings > Snyk Code. If disabled, `snyk code test` will fail even with valid auth.

## `snyk container test`

Scans container images for OS package vulnerabilities and application dependency issues.

### Essential Flags

| Flag | When to Use |
|------|-------------|
| `--json` | Machine-readable output |
| `--file=<DOCKERFILE>` | Link to Dockerfile for base image upgrade advice |
| `--platform=<PLATFORM>` | Target architecture (`linux/amd64`, `linux/arm64`) |
| `--exclude-base-image-vulns` | Only show app-layer vulnerabilities |
| `--app-vulns` | Include application dependency scanning (default in v1.1090+) |
| `--severity-threshold=<low\|medium\|high\|critical>` | Filter by severity |

### Recommended Scan Command

```bash
# Scan a locally built image with Dockerfile context
snyk container test myimage:latest --json --file=Dockerfile || true

# Scan an ECR image
snyk container test 082673049991.dkr.ecr.us-east-1.amazonaws.com/neb-ms-core:latest --json --file=Dockerfile || true
```

## `snyk ignore`

Programmatically suppress vulnerabilities by updating the `.snyk` policy file.

### Flags

| Flag | Purpose |
|------|---------|
| `--id=<ISSUE_ID>` | Snyk vulnerability ID (e.g., `SNYK-JS-LODASH-567746`) |
| `--expiry=<YYYY-MM-DD>` | Expiration date (default: 30 days) |
| `--reason=<REASON>` | Human-readable justification |
| `--path=<PATH>` | Narrow to specific dependency chain |

### Examples

```bash
# Ignore with reason and 90-day expiry
snyk ignore --id='SNYK-JS-LODASH-567746' \
  --expiry='2026-06-06' \
  --reason='Mitigated by WAF rules, tracking JIRA-1234'

# Ignore only for a specific dependency path
snyk ignore --id='SNYK-JS-LODASH-567746' \
  --path='neb-ms-core > express > lodash'
```

### Limitations

- `.snyk` file ignores do NOT work for Snyk Code (SAST) findings
- `--reason` not supported for Snyk Code
- File must be committed to repo for CI/CD to respect it

## `snyk monitor`

Uploads a project snapshot to Snyk for continuous monitoring. Alerts when new vulns are disclosed against your dependency tree.

```bash
snyk monitor --org=chirotouch-cloud --project-name=neb-ms-core
```

Note: `--project-environment` flag requires Org Admin or custom role — Org Collaborators cannot use it.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `SNYK_TOKEN` | Auth token for CI/CD (API token, PAT, or service account) |
| `SNYK_CFG_ORG` | Default org slug (overridden by `--org` flag) |
| `SNYK_API` | Custom API endpoint (Enterprise on-prem) |
| `SNYK_DISABLE_ANALYTICS` | Disable usage analytics |
