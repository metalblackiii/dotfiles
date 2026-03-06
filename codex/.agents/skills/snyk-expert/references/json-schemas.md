# Snyk JSON Output Schemas

## SCA Output (`snyk test --json`)

### Top-Level Structure

```json
{
  "ok": false,
  "vulnerabilities": [ ... ],
  "dependencyCount": 123,
  "org": "chirotouch-cloud",
  "licensesPolicy": null,
  "isPrivate": true,
  "packageManager": "npm",
  "summary": "5 vulnerable dependency paths",
  "filtered": {
    "ignore": [],
    "patch": []
  },
  "uniqueCount": 3
}
```

Key top-level fields:
- `ok` — `false` if vulnerabilities found
- `uniqueCount` — deduplicated vulnerability count
- `dependencyCount` — total dependencies scanned
- `filtered.ignore` — vulnerabilities suppressed by `.snyk` policy or dashboard ignores

### Vulnerability Object

```json
{
  "id": "SNYK-JS-LODASH-567746",
  "title": "Prototype Pollution",
  "description": "...",
  "severity": "high",
  "CVSSv3": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H",
  "moduleName": "lodash",
  "packageName": "lodash",
  "version": "4.17.15",
  "language": "js",
  "packageManager": "npm",
  "from": ["my-app@1.0.0", "express@4.17.1", "lodash@4.17.15"],
  "upgradePath": [false, "express@4.17.2", "lodash@4.17.21"],
  "isUpgradable": true,
  "isPatchable": false,
  "semver": {
    "unaffected": [">=4.17.21"],
    "vulnerable": ["<4.17.21"]
  },
  "identifiers": {
    "CWE": ["CWE-1321"],
    "CVE": ["CVE-2021-23337"]
  },
  "creationTime": "2021-02-18T00:00:00.000Z",
  "publicationTime": "2021-02-18T00:00:00.000Z",
  "isDisputed": false
}
```

### Fields for AI Prioritization

| Field | Why It Matters |
|-------|---------------|
| `severity` | Primary triage dimension (critical/high/medium/low) |
| `isUpgradable` | Is there a fix via dependency upgrade? |
| `isPatchable` | Is there a Snyk-maintained patch? |
| `upgradePath` | Exact upgrade chain needed — `[false, ...]` means the first package can't be upgraded |
| `from` | Dependency chain from root to vulnerable package — deeper = harder to fix |
| `identifiers.CVE` / `identifiers.CWE` | Cross-reference with NVD, exploit databases |
| `CVSSv3` | Granular severity vector beyond the label |
| `publicationTime` | How long the vuln has been public (urgency signal) |
| `isDisputed` | Whether the vuln classification is contested |
| `semver.vulnerable` | Affected version ranges |

### Useful jq Patterns

```bash
# Count vulnerabilities by severity
snyk test --json | jq '.vulnerabilities | group_by(.severity) | map({severity: .[0].severity, count: length})'

# List only upgradable vulns (actionable)
snyk test --json | jq '[.vulnerabilities[] | select(.isUpgradable)] | unique_by(.packageName) | sort_by(.severity)'

# Extract upgrade recommendations
snyk test --json | jq '[.vulnerabilities[] | select(.isUpgradable) | {
  id, severity, packageName, version,
  upgradeTo: .upgradePath[-1],
  cve: .identifiers.CVE[0]
}] | unique_by(.packageName)'

# Filter to critical/high only
snyk test --json | jq '[.vulnerabilities[] | select(.severity == "critical" or .severity == "high")]'

# Summary table: id, severity, package, fixable
snyk test --json | jq '[.vulnerabilities[] | {id, severity, packageName, version, isUpgradable, isPatchable}]'

# Group by package (see all vulns per package)
snyk test --json | jq '[.vulnerabilities[] | {packageName, id, severity}] | group_by(.packageName)'
```

## SAST Output (`snyk code test --json`)

Uses SARIF 2.1.0 format. JSON and SARIF flags produce identical output.

### Top-Level Structure

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": { "driver": { "rules": [...] } },
      "results": [ ... ],
      "properties": { ... }
    }
  ]
}
```

### Result Object

```json
{
  "ruleId": "javascript/SqlInjection",
  "ruleIndex": 0,
  "level": "error",
  "message": {
    "text": "Unsanitized input from an HTTP parameter flows into sql..."
  },
  "locations": [
    {
      "physicalLocation": {
        "artifactLocation": { "uri": "src/routes/users.js" },
        "region": {
          "startLine": 42,
          "startColumn": 5,
          "endLine": 42,
          "endColumn": 60
        }
      }
    }
  ],
  "properties": {
    "categories": ["Security"],
    "CWE": ["CWE-89"],
    "priorities": [ ... ]
  }
}
```

### SARIF Severity Mapping

| SARIF `level` | Snyk Severity |
|---------------|---------------|
| `error` | High |
| `warning` | Medium |
| `note` / `info` | Low |

No `critical` severity exists for SAST findings.

### Useful jq Patterns for SAST

```bash
# Extract findings with file locations
snyk code test --json | jq '[.runs[].results[] | {
  ruleId,
  level,
  message: .message.text,
  file: .locations[0].physicalLocation.artifactLocation.uri,
  line: .locations[0].physicalLocation.region.startLine,
  cwe: .properties.CWE[0]
}]'

# Count by severity
snyk code test --json | jq '[.runs[].results[].level] | group_by(.) | map({level: .[0], count: length})'

# Filter to high severity only
snyk code test --json | jq '[.runs[].results[] | select(.level == "error")]'
```

## Container Output (`snyk container test --json`)

Follows the same structure as SCA (`vulnerabilities[]` array) with additional container-specific fields:

- `docker.baseImage` — detected base image
- `docker.baseImageRemediation` — upgrade recommendations (requires `--file=Dockerfile`)
  - Minor upgrade option with vuln count delta
  - Major upgrade option with vuln count delta
  - Alternative base image suggestions

```bash
# Extract base image recommendation
snyk container test myimage:latest --json --file=Dockerfile | jq '.docker.baseImageRemediation'
```
