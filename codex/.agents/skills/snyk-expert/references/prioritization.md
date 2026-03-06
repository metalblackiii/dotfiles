# Vulnerability Prioritization

## The Priority Matrix

Raw severity alone creates noise — hundreds of "high" vulns with no differentiation. Combine multiple signals:

| Signal | Source | What It Tells You |
|--------|--------|-------------------|
| **CVSS** (0-10) | Snyk JSON `CVSSv3` field | Theoretical worst-case severity |
| **EPSS** (0-1.0) | FIRST.org / enrichment | Probability of exploitation in the wild within 30 days |
| **Reachability** | Snyk (Enterprise) | Whether your code actually calls the vulnerable function |
| **Upgradability** | Snyk JSON `isUpgradable` | Whether a fix exists |
| **Dependency Depth** | Snyk JSON `from` array | Direct (you control) vs deep transitive (harder to fix) |
| **Publication Age** | Snyk JSON `publicationTime` | How long the vuln has been known and unpatched |

## Risk Tiers

### Tier 1: Act Now
- Critical or High severity AND
- Upgradable (fix exists) AND
- Direct dependency OR reachable

**Action:** Fix immediately. These are the highest-value fixes.

### Tier 2: Plan This Sprint
- Critical or High severity AND
- Upgradable BUT major version bump required
- OR: Medium severity + high EPSS + reachable

**Action:** Schedule fix, review breaking changes, test thoroughly.

### Tier 3: Batch When Convenient
- Medium severity AND upgradable AND semver-compatible fix
- OR: Low severity with easy fix

**Action:** Batch with other maintenance work. Good candidates for automated PRs.

### Tier 4: Accept and Monitor
- No fix available (any severity)
- OR: Low severity, not reachable, transitive dependency
- OR: Disputed vulnerability

**Action:** Document the decision with `snyk ignore --reason='...' --expiry='...'`. Set expiry to resurface periodically.

## HIPAA Elevation Rule

In healthcare applications, certain vulnerability types get elevated priority regardless of CVSS:

- **Data exposure** (CWE-200, CWE-209, CWE-532) — could leak PHI
- **Authentication bypass** (CWE-287, CWE-306) — unauthorized access to patient data
- **Injection** (CWE-89, CWE-79, CWE-78) — could enable data exfiltration
- **Broken access control** (CWE-862, CWE-863) — tenant isolation failure

If a vulnerability matches these CWEs in a neb service, treat it as Tier 1 regardless of other signals.

## Presentation Format

When presenting scan results to a human, group by tier, not by raw severity:

```
TIER 1 — Act Now (2 vulnerabilities)
  lodash@4.17.20 → 4.17.21 (patch) — Prototype Pollution (CVE-2021-23337)
    CVSS: 9.8 | Reachable: YES | Direct dependency

  express@4.17.1 → 4.18.0 (minor) — Open Redirect (CVE-2024-XXXXX)
    CVSS: 9.1 | Reachable: YES | Direct dependency

TIER 2 — Plan This Sprint (3 vulnerabilities)
  axios@0.21.1 → 1.6.0 (MAJOR) — SSRF, ReDoS, Header Injection
    CVSS: 8.1 | Reachable: PARTIAL | Breaking changes likely

TIER 3 — Batch When Convenient (12 vulnerabilities)
  ... grouped by package, showing count and top CVSS ...

TIER 4 — Accept and Monitor (31 vulnerabilities)
  ... summary count only ...

SUMMARY: 48 total | 5 actionable now | 12 batchable | 31 accept/monitor
```

### Presentation Principles

1. **Lead with the fix** — show the upgrade path alongside the vulnerability
2. **Flag breaking changes** — major version bumps need explicit callout
3. **Collapse noise** — individual details only for Tier 1/2; summary for Tier 3/4
4. **Show effort** — "patch" vs "minor" vs "MAJOR" vs "no fix"
5. **Include dependency depth** — "direct" vs "transitive via express"

## SSVC Decision Framework

For organizations wanting a more structured approach, SSVC (Stakeholder-Specific Vulnerability Categorization) uses a decision tree:

| Exploitation | Exposure | Impact | Decision |
|-------------|----------|--------|----------|
| Active | Internet-facing | Critical data | **Act** immediately |
| Active | Internal | Any | **Attend** within days |
| PoC exists | Any | Critical data | **Attend** within days |
| None known | Any | Non-critical | **Track** — monitor only |

Map to the tier system: Act = Tier 1, Attend = Tier 2, Track = Tier 3/4.

## Common Prioritization Mistakes

| Mistake | Reality |
|---------|---------|
| Treating all Critical CVSSes equally | A Critical in an unreachable transitive dep is lower priority than a High in your direct dependency |
| Ignoring medium-severity vulns | Mediums with high EPSS scores are actively exploited |
| Prioritizing by count | 50 vulns in one package fixed by one upgrade is easier than 3 vulns requiring 3 separate major bumps |
| Focusing on SAST over SCA | SCA fixes are faster, more reliable, and often higher impact |
| Ignoring publication age | A year-old unpatched High is a bigger signal than a week-old Medium |
