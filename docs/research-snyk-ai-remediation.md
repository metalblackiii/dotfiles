# AI + Snyk CLI Automated Vulnerability Remediation: Research Summary

> Researched 2026-03-06. Based on web research and codebase analysis of neb-ms-core, neb-ms-billing, neb-microservice, and neb-www.

## Executive Summary

Snyk CLI provides rich, machine-readable JSON/SARIF output from `snyk test` (SCA), `snyk code test` (SAST), and `snyk container test` that an AI agent can parse, prioritize, and act on. The ecosystem is moving toward AI-assisted remediation (Snyk Agent Fix, Copilot Autofix, Semgrep Assistant), but no tool covers the full scan → assess → approve → remediate loop well — especially not in a CLI/agent context. Your four surveyed repos have **zero Snyk integration today** (no `.snyk` files, no Snyk in CI/CD, no security scanning in GitHub Actions), which means there's a clean greenfield opportunity. The recommended approach is a Claude Code skill that orchestrates Snyk CLI scans, presents a risk-tiered assessment, gates on human approval, then applies fixes as atomic commits on a dedicated branch.

## Key Concepts

### Snyk Scan Types

| Scan Type | Command | What It Finds | Output Format |
|-----------|---------|---------------|---------------|
| **SCA** (dependencies) | `snyk test --json` | Known vulns in npm/pip/etc packages | JSON with `vulnerabilities[]` array |
| **SAST** (source code) | `snyk code test --json` | Code-level security issues (SQLi, XSS, etc.) | SARIF 2.1.0 |
| **Container** | `snyk container test --json` | OS package vulns + base image issues | JSON with `docker.baseImageRemediation` |

### Exit Codes (consistent across all commands)

| Code | Meaning |
|------|---------|
| 0 | No vulnerabilities found |
| 1 | Vulnerabilities found (actionable) |
| 2 | CLI error |
| 3 | No supported projects detected |

### Key JSON Fields for AI Prioritization

**SCA (`snyk test --json`):** `severity`, `isUpgradable`, `isPatchable`, `upgradePath`, `from` (dependency chain), `identifiers.CVE`/`identifiers.CWE`, `CVSSv3`, `publicationTime`

**SAST (`snyk code test --json`):** `ruleId`, `level` (error=High, warning=Medium, note=Low), `locations[].physicalLocation` (file, line, column), `message.text`, `properties.CWE`

**Container:** All SCA fields plus `docker.baseImage`, `docker.baseImageRemediation` (minor/major upgrade options with vuln count deltas)

## Ecosystem Landscape

| Tool/Approach | Maturity | AI Method | Strengths | Weaknesses |
|---------------|----------|-----------|-----------|------------|
| **Snyk Agent Fix** | GA (IDE), EA (PR) | Self-hosted LLM + CodeReduce | ~80% accuracy, pre-validated fixes | IDE/PR only — not available via CLI |
| **Copilot Autofix** | GA | CodeQL + GPT-4o | >66% fix rate, integrated in GitHub | Requires GHAS, GitHub-only |
| **Semgrep Assistant** | GA | Prompt chains + RAG + self-eval | 95% remediation guidance on true positives | Semgrep ecosystem only |
| **Snyk MCP Server** | EA | Bridges Snyk CLI to AI agents | Natural language security scanning | Early access, limited docs |
| **`snyk fix` CLI** | Deprecated/Beta | Rule-based (not AI) | Direct CLI remediation | Python only, superseded |
| **npm audit fix** | Stable | Rule-based | Built-in, zero config | Fragile on complex trees, no prioritization |
| **Renovate/Dependabot** | Stable | Rule-based | PR-based approval, mature | No intelligent prioritization, no SAST |
| **Claude Code Skill** (proposed) | New | Claude + Snyk JSON | Full loop, human-in-the-loop, any repo | Needs building |

## Best Practices

### From Production Tools

1. **Code minimization is the #1 technique.** Snyk's CodeReduce improved fix accuracy from ~19% to ~82% by reducing code sent to the LLM to the minimal context needed. When building prompts for fixes, strip to the relevant function + vulnerability context.

2. **Re-scan after every fix.** Run the same Snyk command on the generated fix to verify it resolves the alert and doesn't introduce new ones. Meta's AutoPatchBench showed 60% of AI fixes compile, but only 5-11% survive full verification.

3. **Triage before fix.** Filter false positives before generating fixes — otherwise the LLM "fixes" correct code. Use severity + reachability + EPSS to prioritize.

4. **Before/after blocks, not diffs.** GitHub found that asking LLMs for before/after code blocks yields better results than standard diff format.

5. **Atomic commits per fix.** Each dependency upgrade or code fix gets its own commit. Enables `git revert` of individual fixes, `git bisect` for regressions, and clean audit trail.

6. **Human review is non-negotiable.** No production tool ships autonomous merge. The consensus is AI-suggested, human-approved.

### Common Failure Modes to Guard Against

| Failure | Mitigation |
|---------|------------|
| Semantic cheating (suppress symptom, not root cause) | Re-scan with same tool after fix |
| Hallucinated dependencies | Verify packages exist in registry before applying |
| False positive confusion | Triage step before fix generation |
| Multi-file blind spots | Flag multi-file vulns for manual review |
| Major version breaking changes | Separate batch, explicit human approval |

## Current State (Codebase Survey)

### Cross-Repo Summary

| Repo | Language/Framework | Direct Deps | Lockfile Packages | Dockerfile | Helm | `.snyk` File | Snyk in CI | Security Scanning |
|------|--------------------|-------------|-------------------|------------|------|-------------|------------|-------------------|
| **neb-ms-core** | Node.js/Express (CommonJS) | 30 prod + 30 dev | 1,168 | Yes (`node:24-trixie-slim`) | Yes (`helm/core/`) | **None** | **None** | **None** |
| **neb-ms-billing** | Node.js/Express (CommonJS) | ~30 prod + ~30 dev | 1,073 | Yes (root + `dockerfiles/billing835/`) | Yes (`helm/billing/`, `helm/billing835/`) | **None** | **None** | **None** |
| **neb-microservice** | Node.js shared lib | 38 prod + 26 dev + 2 peer | ~800 | No (library, not deployed) | No | **None** | **None** | **None** |
| **neb-www** | Lit/Web Components + Babel | 68 prod + 99 dev | 2,369 + 700 (ckeditor5) | Yes (`Dockerfile` + `integration-test-worker.Dockerfile`) | Yes (`helm/www/`, `helm/integrationtestworker/`) | **None** | **None** | **None** |

### Key Findings

- **Zero Snyk integration exists.** No `.snyk` policy files, no `snyk` in any npm scripts, no Snyk steps in any GitHub Actions workflow.
- **Snyk mentioned only in comments.** References appear in `.depcheckrc.yaml` comments (e.g., "Top level upgrade fixes snyk issue with sequelize-cli") and eslint rules ("Avoid using res.send (snyk)"), indicating past ad-hoc Snyk usage but no automation.
- **All repos have Dockerfiles** (except neb-microservice, which is a shared library). Container scanning is relevant for the deployed services.
- **All deployed repos use Helm charts** with ECR-hosted images — `snyk container test` can target these images.
- **GitHub Actions CI exists** in neb-ms-billing, neb-microservice, and neb-www (ci-validations, main, patch workflows). neb-ms-core has no `.github/workflows` directory. None include security scanning steps.
- **No depcheck/audit in CI.** The `depcheck` npm script exists in all repos but isn't wired into CI.
- **Bitbucket Pipelines legacy** exists in neb-www (transitioning to GitHub Actions). No security scanning there either.

## Gap Analysis

| Recommendation | Current State | Gap | Effort |
|----------------|---------------|-----|--------|
| Run `snyk test` on all repos | Not run anywhere | Full gap — no SCA scanning | Low: single CLI command per repo |
| Run `snyk code test` on all repos | Not run anywhere | Full gap — no SAST scanning | Low: single CLI command per repo |
| Run `snyk container test` on Dockerfiles | Not run anywhere | Full gap — no container scanning | Low: needs built image or Dockerfile reference |
| Create `.snyk` policy files | None exist | No way to track ignored/accepted vulns | Medium: create after initial scan triage |
| Add Snyk to CI/CD (GitHub Actions) | No security steps in any workflow | Full gap | Medium: add workflow steps (future phase) |
| Automated remediation workflow | Only ad-hoc manual Snyk runs | Full gap — this is the skill to build | This research |

## Trade-offs & Decision Points

### 1. Snyk MCP Server vs. Direct CLI Parsing

**MCP Server:** Snyk offers an early-access MCP server that lets AI agents invoke scanning via natural language. Pro: cleaner integration. Con: early access, limited control, opaque output formatting.

**Direct CLI Parsing (recommended for v1):** Run `snyk test --json` and parse the output yourself. Pro: full control over the workflow, stable CLI, well-documented JSON schemas. Con: more skill code to write.

**Recommendation:** Start with direct CLI parsing for reliability and control. Evaluate MCP server for v2 once it's GA.

### 2. Fix Strategy: Dependency Upgrades vs. Code Fixes

**SCA fixes** (dependency upgrades) are deterministic — Snyk tells you exactly which version to upgrade to. High success rate, low risk.

**SAST fixes** (code changes) require the AI to understand application logic. Much higher failure rate (~5-11% survive full verification per Meta's research).

**Recommendation:** v1 focuses on SCA fixes (dependency upgrades) + container base image upgrades. SAST fixes are v2 — present findings for awareness but don't auto-fix code in v1.

### 3. Batch Granularity

**Per-vulnerability:** Maximum control, maximum approval fatigue.
**Per-package:** Natural grouping (one upgrade fixes multiple CVEs). Good balance.
**Per-risk-tier:** Critical/High/Medium/Low batches. Fastest for the human.

**Recommendation:** Group by risk tier for approval, apply as per-package atomic commits for rollback granularity.

### 4. Auth Model

**Personal token (`snyk auth`):** Works now, tied to your account. Fine for v1.
**Service account:** Enterprise feature, better for sharing with team. Future consideration.

**Recommendation:** v1 uses `SNYK_TOKEN` env var (works for both admin and collaborator). Document that `snyk test`, `snyk monitor`, and `snyk code test` all work with Org Collaborator permissions.

## Recommended Approach: Skill Design

### Skill Name: `snyk-guardian`

### Workflow: Scan → Assess → Approve → Remediate

```
Phase 1: SCAN
├── snyk test --json --all-projects → SCA results
├── snyk code test --json → SAST results
├── snyk container test <image> --json --file=Dockerfile → Container results
└── Merge all results into unified assessment

Phase 2: ASSESS (AI-powered)
├── Parse JSON/SARIF output
├── Deduplicate (same vuln via multiple paths)
├── Enrich: severity + upgradability + dependency depth
├── Classify into risk tiers:
│   ├── CRITICAL: High/Critical + upgradable + direct dependency
│   ├── HIGH: High + upgradable + transitive
│   ├── MEDIUM: Medium severity, semver-compatible fix available
│   ├── LOW: Low severity or no fix available
│   └── CONTAINER: Base image upgrade recommendations
├── For SAST: present findings with file/line for awareness (no auto-fix in v1)
└── Present grouped summary to human

Phase 3: APPROVE (Human gate)
├── Present each risk tier as a batch:
│   "Batch 1 of 4: Critical Fixes (2 packages)"
│   "  lodash 4.17.20 → 4.17.21 (patch, fixes CVE-2021-23337)"
│   "  express 4.17.1 → 4.18.0 (minor, fixes CVE-2024-XXXXX)"
│   "[A]pprove  [S]kip  [D]etails"
├── Human approves/skips each batch
└── Log decisions for audit trail

Phase 4: REMEDIATE (on dedicated branch)
├── Create branch: fix/snyk-remediation-YYYY-MM-DD
├── For each approved package upgrade:
│   ├── Update package.json version
│   ├── Run npm install (regenerate lockfile)
│   ├── Run snyk test --json (verify fix removes vuln)
│   ├── Run existing tests (npm test)
│   ├── If pass: atomic commit with CVE reference
│   ├── If fail: revert, report, continue to next
│   └── Commit message: "fix(deps): upgrade <pkg> X.Y.Z → A.B.C (CVE-XXXX-YYYY)"
├── For container fixes:
│   ├── Update Dockerfile FROM line
│   ├── Run snyk container test (verify improvement)
│   ├── Atomic commit
│   └── Commit message: "fix(docker): upgrade base image <old> → <new>"
└── Present summary: X fixes applied, Y skipped, Z failed

Phase 5: REPORT
├── Summary of all actions taken
├── Remaining unfixed vulnerabilities (with reasons)
├── SAST findings for manual review
└── Suggest: "Ready for PR? Branch: fix/snyk-remediation-YYYY-MM-DD"
```

### Key Skill Implementation Details

**Prerequisites check:**
```bash
# Verify snyk CLI is available and authenticated
snyk --version
snyk auth check  # or verify SNYK_TOKEN is set
```

**SCA scan with full context:**
```bash
snyk test --json --all-projects --severity-threshold=low 2>/dev/null || true
# Exit code 1 = vulns found (expected), capture JSON regardless
```

**Actionable vulnerability extraction (jq):**
```bash
snyk test --json | jq '[.vulnerabilities[] | select(.isUpgradable) | {
  id, severity, packageName, version,
  upgradeTo: .upgradePath[-1],
  from: .from,
  cve: .identifiers.CVE[0]
}] | unique_by(.packageName) | sort_by(.severity | if . == "critical" then 0 elif . == "high" then 1 elif . == "medium" then 2 else 3 end)'
```

**SAST finding extraction:**
```bash
snyk code test --json | jq '[.runs[].results[] | {
  ruleId, level,
  message: .message.text,
  file: .locations[0].physicalLocation.artifactLocation.uri,
  line: .locations[0].physicalLocation.region.startLine,
  cwe: .properties.CWE[0]
}]'
```

**Container scan with base image advice:**
```bash
snyk container test <image>:<tag> --json --file=Dockerfile
# JSON includes docker.baseImageRemediation with upgrade options
```

### Permission Compatibility

| Action | Org Admin | Org Collaborator |
|--------|-----------|-----------------|
| `snyk test` | Yes | Yes |
| `snyk code test` | Yes | Yes |
| `snyk container test` | Yes | Yes |
| `snyk ignore` | Yes | Yes |
| `snyk monitor` | Yes | Yes |
| `snyk monitor --project-environment` | Yes | **No** (needs custom role) |

The skill works identically for both roles. The only restriction is `--project-environment` on `snyk monitor`, which the skill doesn't need.

## References & Sources

### Snyk CLI Documentation
- [Test command](https://docs.snyk.io/developer-tools/snyk-cli/commands/test)
- [Code test command](https://docs.snyk.io/developer-tools/snyk-cli/commands/code-test)
- [Container test command](https://docs.snyk.io/developer-tools/snyk-cli/commands/container-test)
- [Ignore command](https://docs.snyk.io/snyk-cli/commands/ignore)
- [CLI commands summary](https://docs.snyk.io/developer-tools/snyk-cli/cli-commands-and-options-summary)
- [Authentication](https://docs.snyk.io/developer-tools/snyk-cli/authenticate-to-use-the-cli)
- [Service accounts](https://docs.snyk.io/implementation-and-setup/enterprise-setup/service-accounts)
- [Pre-defined roles](https://docs.snyk.io/snyk-platform-administration/user-roles/pre-defined-roles)
- [Snyk MCP server (EA)](https://docs.snyk.io/cli-ide-and-ci-cd-integrations/snyk-cli/developer-guardrails-for-agentic-workflows/snyk-mcp-early-access)

### AI Remediation Research
- [Snyk Agent Fix / CodeReduce](https://snyk.io/blog/building-ai-trust-with-snyk-code-and-snyk-agent-fix/)
- [GitHub Copilot Autofix architecture](https://github.blog/engineering/platform-security/fixing-security-vulnerabilities-with-ai/)
- [Semgrep Assistant internals](https://semgrep.dev/blog/2024/the-tech-behind-semgrep-assistant/)
- [Meta AutoPatchBench (5-11% full verification)](https://engineering.fb.com/2025/04/29/ai-research/autopatchbench-benchmark-ai-powered-security-fixes/)
- [Datadog LLM false positive filtering](https://www.datadoghq.com/blog/using-llms-to-filter-out-false-positives/)
- [GitHub Security Lab Taskflow Agent](https://github.blog/security/ai-supported-vulnerability-triage-with-the-github-security-lab-taskflow-agent/)

### JSON Parsing & Workflow
- [Using jq with Snyk results](https://dev.to/snyk/using-jq-to-manipulate-json-results-of-snyk-security-tests-2leo)
- [Getting the most out of snyk test](https://snyk.io/blog/getting-the-most-out-of-snyk-test/)

### Open Source References
- [LambdaSec AutoFix (Semgrep + StarCoder)](https://github.com/lambdasec/autofix)
- [GitHub seclab-taskflow-agent](https://github.com/github/seclab-taskflow-agent)
- [Snyk Studio MCP](https://github.com/snyk/studio-mcp)
- [Continue + Snyk MCP cookbook](https://docs.continue.dev/guides/snyk-mcp-continue-cookbook)

### Skill Design Patterns
- [Human-in-the-loop for AI agents](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo)
- [Atomic commits for AI agents](http://raine.dev/blog/atomic-commits-for-ai-agents/)
- [Root.io agentic remediation](https://www.root.io/blog/agentic-vulnerability-remediation-fix-in-place-at-scale)

## Open Questions

1. **Snyk org configuration** — What is the exact Snyk org slug for your Enterprise account? The skill needs `--org=<slug>` for consistent results.

2. **Container image availability** — Can the skill run `snyk container test` against locally-built images, or does it need to pull from ECR? This affects whether container scanning requires Docker running locally.

3. **Test suite reliability** — How stable are the existing test suites? If tests are flaky, the "run tests after fix" validation step may produce false negatives.

4. **Private registry packages** — The `@neb/*` packages come from a private registry (`.npmrc` configured). The skill needs to ensure `npm install` works after version bumps — this may require the `.npmrc` to be properly configured in the environment.

5. **Snyk MCP server evaluation** — Worth a separate spike once the MCP server exits EA. Could simplify the skill significantly by replacing direct CLI parsing with natural language invocation.

6. **SAST auto-fix (v2)** — When ready to tackle code-level fixes, the CodeReduce pattern (minimize code context sent to the LLM) should be the primary technique. This needs separate research into prompt engineering for each CWE type.

7. **CI/CD integration (future)** — Once the skill proves out locally, adding Snyk steps to GitHub Actions workflows would provide continuous scanning. This is a separate initiative from the skill itself.
