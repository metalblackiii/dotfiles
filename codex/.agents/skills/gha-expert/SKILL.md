---
name: gha-expert
description: ALWAYS invoke to create, generate, validate, lint, audit, fix, or diagnose GitHub Actions workflows (.github/workflows), custom actions (action.yml), and CI/CD pipeline failures. Covers workflow generation, static analysis, local testing, and runtime failure triage.
---

# GHA Expert

Generate, validate, and diagnose GitHub Actions workflows, custom actions, and CI/CD pipelines following current best practices, security standards, and naming conventions.

## When to Use

- Creating, generating, or scaffolding GitHub Actions workflows or custom actions
- Validating, linting, auditing, or fixing existing workflow files
- Investigating a failed workflow run (flakiness, root cause, breaking commit)
- Verifying action versions, deprecations, or security hardening
- Testing workflows locally with act before pushing

## Trigger Decision Tree

Route every request through this tree before loading references:

1. **"Create/generate/scaffold a workflow or action"** → [Generation Workflow](#generation-workflow)
2. **"Validate/lint/audit/fix a workflow file"** → [Validation Workflow](#validation-workflow)
3. **"Why did this workflow run fail?" / GHA URL** → [Failure Analysis Workflow](#failure-analysis-workflow)
4. If intent is ambiguous, ask: "Do you want to create, validate, or diagnose a failure?"

---

## Generation Workflow

### Route Selection

1. `.github/workflows/*.yml` CI/CD automation → **Workflow Generation**
2. `action.yml` or reusable step package → **Custom Action Generation**
3. `workflow_call` or shared pipelines → **Reusable Workflow Generation**
4. Security-only scanning (dependency review, SBOM, CodeQL) → **Workflow Generation** with security pattern

### Progressive Disclosure

Load only what is needed for the selected route:

| Route | Load First | Load Next (if needed) | Template |
|-------|-----------|----------------------|----------|
| Workflow | `references/best-practices.md` | `common-actions.md`, `expressions-and-contexts.md`, `modern-features.md` | `assets/templates/workflow/basic_workflow.yml` |
| Custom Action | `references/custom-actions.md` | `best-practices.md` | `assets/templates/action/{composite,docker,javascript}/` |
| Reusable Workflow | `references/advanced-triggers.md` | `best-practices.md`, `common-actions.md` | `assets/templates/workflow/reusable_workflow.yml` |

### Process

1. Understand requirements (triggers, runners, dependencies)
2. Define trust boundaries (internal branches vs fork PRs vs external triggers)
3. Set default `permissions` to read-only, then elevate only per job when required
4. Reference appropriate docs per the progressive disclosure table
5. Generate with: semantic names, SHA-pinned actions, explicit permissions, concurrency controls, caching, matrix strategies, fork-safe PR handling
6. **Validate** using the validation workflow below
7. Fix issues and re-validate until clean

### Mandatory Standards

| Standard | Implementation |
|----------|---------------|
| **Security** | Pin to SHA, minimal permissions, mask secrets, fork-safe PR guards |
| **Performance** | Caching, concurrency, shallow checkout |
| **Naming** | Descriptive names, lowercase-hyphen files |
| **Error Handling** | Timeouts, cleanup with `if: always()` |

### Third-Party Action Citation

For every `uses:` entry from outside the repository:

1. Pin to SHA with version comment: `actions/checkout@de0fac2e...dd # v6.0.2`
2. Cite source (repo URL), version (release/tag URL), SHA, and access date
3. Check `references/common-actions.md` for pre-verified versions

### Untrusted PR Guardrail (required for secret-using jobs)

```yaml
jobs:
  deploy:
    if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository
```

### Quick Reference: Generation

| Capability | Reference |
|------------|-----------|
| Workflows | `references/best-practices.md` |
| Composite/Docker/JS Actions | `references/custom-actions.md` |
| Reusable Workflows | `references/advanced-triggers.md` |
| Security Scanning | `references/best-practices.md` |
| Modern Features | `references/modern-features.md` |
| Action Versions | `references/common-actions.md` |
| Expressions | `references/expressions-and-contexts.md` |

---

## Validation Workflow

### Setup

```bash
SKILL_DIR="~/.claude/skills/gha-expert"
bash "$SKILL_DIR/scripts/install_tools.sh"    # One-time: installs actionlint + act
```

### Execution Flow

1. **Run validation:**
   ```bash
   SKILL_DIR="~/.claude/skills/gha-expert"
   bash "$SKILL_DIR/scripts/validate_workflow.sh" <workflow-file-or-directory>
   ```
   Modes: `--lint-only` (fastest), `--test-only` (act, requires Docker), default (both).

2. **Map each error to a reference** using the error mapping table below.

3. **Apply minimal-quote policy** — exact error line, smallest useful snippet (<=8 lines) from references, corrected code.

4. **Handle unmapped errors** — label as `UNMAPPED`, capture exact output, check `references/common_errors.md`, then official docs. Mark fix as `provisional`.

5. **Verify public action versions** — check `references/action_versions.md`. Mark unknown actions as `UNVERIFIED-OFFLINE` when offline.

6. **Mandatory post-fix rerun:**
   ```bash
   bash "$SKILL_DIR/scripts/validate_workflow.sh" <workflow-file-or-directory>
   ```

7. **Final summary** — issues found, fixes applied, unmapped/unverified items, rerun result.

### Error Mapping

| Error Pattern | Reference File | Section |
|---------------|---------------|---------|
| `runs-on:`, `runner`, `ubuntu`, `macos` | `references/runners.md` | Runner labels |
| `cron`, `schedule` | `references/common_errors.md` | Schedule Errors |
| `${{`, `expression`, `if:` | `references/common_errors.md` | Expression Errors |
| `needs:`, `job`, `dependency` | `references/common_errors.md` | Job Configuration |
| `uses:`, `action`, `input` | `references/common_errors.md` | Action Errors |
| `untrusted`, `injection`, `security` | `references/common_errors.md` | Script Injection |
| `syntax`, `yaml`, `unexpected` | `references/common_errors.md` | Syntax Errors |
| `docker`, `container` | `references/act_usage.md` | Troubleshooting |
| `@v3`, `@v4`, `deprecated` | `references/action_versions.md` | Version table |
| `workflow_call`, `reusable`, `oidc` | `references/modern_features.md` | Relevant section |
| `glob`, `path`, `paths:` | `references/common_errors.md` | Path Filter Errors |

### Fallback Behavior

- actionlint unavailable → `act` only (or manual YAML review with "not tool-validated" note)
- act/Docker unavailable → actionlint only
- Network unavailable → use `references/action_versions.md`, mark unknowns `UNVERIFIED-OFFLINE`

### Quick Reference: Validation

| Reference | Content |
|-----------|---------|
| `references/act_usage.md` | Act tool usage, limitations, troubleshooting |
| `references/actionlint_usage.md` | Actionlint categories, configuration |
| `references/common_errors.md` | Common errors catalog with fixes |
| `references/action_versions.md` | Current versions, deprecation timeline, SHA pinning |
| `references/modern_features.md` | Reusable workflows, SBOM, OIDC validation points |
| `references/runners.md` | GitHub-hosted runners (ARM64, GPU, deprecations) |

---

## Failure Analysis Workflow

Investigate why a GitHub Actions workflow run failed, using the `gh` CLI.

### When to Use

- User shares a workflow run URL or says "this workflow failed"
- Investigating flaky tests in CI
- Identifying which commit broke CI

### Process

1. **Get basic info and identify actual failure:**
   - What workflow/job failed, when, and on which commit?
   - Read full logs carefully — find what SPECIFICALLY caused exit code 1
   - Distinguish warnings/non-fatal errors from actual failures
   - Look for patterns: `failing:`, `fatal:`, script logic that triggers exit 1
   - If both non-fatal and fatal errors exist, focus on the actual failure trigger

2. **Check flakiness** — past 10-20 runs of THE EXACT SAME failing job:
   ```bash
   gh run list --workflow=<workflow-name> --limit 20
   gh run view <run-id> --json jobs
   ```
   - Check the SPECIFIC JOB that failed, not just the workflow
   - What's the success rate recently? When did it last pass?

3. **Identify breaking commit** (if recurring failures):
   - Find the first run where this job failed and the last where it passed
   - Identify the commit that introduced the failure
   - Verify: does this job fail in ALL runs after that commit? Pass in ALL runs before?
   - Report breaking commit with confidence level

4. **Root cause analysis:**
   - Focus on what ACTUALLY caused the failure, not just any errors in the logs
   - Cross-reference with validation references if the failure is configuration-related
   - Verify hypothesis against logs and failure logic

5. **Check for existing fix PRs:**
   ```bash
   gh pr list --state open --search "<keywords from error>"
   ```
   - If a fix PR exists, note it and skip the recommendation

### Report Format

Write a final report with:
- **Summary** — what specifically triggered the failure
- **Flakiness assessment** — one-time vs recurring, success rate
- **Breaking commit** — if identified and verified (with confidence level)
- **Root cause** — based on the actual failure trigger
- **Existing fix PR** — if found (include PR number and link)
- **Recommendation** — skip if fix PR already exists

---

## Done Criteria

Work is complete when all applicable checks pass:

**Generation:**
- [ ] Route selected via decision tree
- [ ] Minimum required references loaded
- [ ] Every third-party action SHA-pinned with source/version citation
- [ ] Validation run (or skip exception documented)
- [ ] Output includes assumptions, security decisions, file paths

**Validation:**
- [ ] Each mapped error has source reference and minimal quote
- [ ] Each unmapped error labeled `UNMAPPED` with exact output
- [ ] Public action versions verified (or marked `UNVERIFIED-OFFLINE`)
- [ ] Post-fix rerun executed and result reported

**Failure Analysis:**
- [ ] Actual failure cause identified (not just any error)
- [ ] Flakiness assessed with job-specific history
- [ ] Breaking commit identified (if pattern exists)
- [ ] Existing fix PRs checked
- [ ] Report delivered with all applicable sections

---

## All References

| Document | Content | Used by |
|----------|---------|---------|
| `references/best-practices.md` | Security, performance, patterns | Generation |
| `references/common-actions.md` | Action versions, inputs, outputs | Generation |
| `references/expressions-and-contexts.md` | `${{ }}` syntax, contexts, functions | Generation |
| `references/advanced-triggers.md` | workflow_run, dispatch, ChatOps | Generation |
| `references/custom-actions.md` | Metadata, structure, versioning | Generation |
| `references/modern-features.md` | Summaries, environments, containers | Generation |
| `references/act_usage.md` | Act tool usage, limitations | Validation |
| `references/actionlint_usage.md` | Actionlint categories, config | Validation |
| `references/common_errors.md` | Common errors catalog with fixes | Validation |
| `references/action_versions.md` | Current versions, deprecation timeline | Validation |
| `references/modern_features.md` | Reusable workflows, SBOM, OIDC validation | Validation |
| `references/runners.md` | GitHub-hosted runners, labels | Validation |

## Templates

| Template | Location |
|----------|----------|
| Basic Workflow | `assets/templates/workflow/basic_workflow.yml` |
| Reusable Workflow | `assets/templates/workflow/reusable_workflow.yml` |
| Composite Action | `assets/templates/action/composite/action.yml` |
| Docker Action | `assets/templates/action/docker/` |
| JavaScript Action | `assets/templates/action/javascript/` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install_tools.sh` | Install actionlint + act |
| `scripts/validate_workflow.sh` | Run validation (actionlint + act) |
| `scripts/test_generator.sh` | Regression tests for generation artifacts |
| `tests/test_validate_workflow.sh` | Regression tests for validation script |
