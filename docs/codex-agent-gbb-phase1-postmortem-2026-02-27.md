# Autonomous Agent Performance Analysis: GBB Tenant Provisioning Phase 1

**Date**: 2026-02-27
**Tool**: `auto-agent-codex` (ptek-ai-playbook/experimental/auto-agent-codex)
**Model**: OpenAI `gpt-5.3-codex`
**Target**: `neb-ms-registry` — GBB provisioning v2 phase 1
**PRs**: #115, #116, #117, #118 (stacked)

## Executive Summary

The `auto-agent-codex` runner decomposed and implemented 4 stacked PRs (~1000 LOC, 19 files) in 1.5 hours with zero human intervention during execution. Business logic was correct throughout — bundle mappings, exclusivity rules, Doctible payloads all matched the PRD spec. However, **the agent never successfully ran the test suite** (MySQL/terminus not available in workspace), and this single gap cascaded into critical bugs in 3 of 4 PRs. The self-review loop caught 2 of 5 bugs but was blind to test assertion logic and coverage reachability. The tool is production-viable for additive greenfield work with CI backstop, but needs mandatory test-execution gating before it can handle behavior-preservation refactoring.

### Operator Context

The agent ran on a local developer machine. The test environment (MySQL, Kafka, terminus) **could have been started** before launching the agent — this was an avoidable operator error. A 30-second pre-flight smoke test (`npm test -- --bail`) would have confirmed the environment was ready and prevented the entire class of validation failures. This should be part of any future agent launch checklist, and the tool itself should enforce it.

---

## Scorecard

| Dimension | Rating | Justification |
|-----------|:------:|---------------|
| **PRD Quality (input)** | 5/5 | Exact function signatures, tier matrices, code findings with file:line, acceptance criteria. Zero ambiguity. |
| **Phase Decomposition** | 5/5 | 4 phases cleanly separated (schema → service → v1 refactor → v2 wiring). All under 12-file/400-LOC gates. Dependency order correct. |
| **Code Correctness (business logic)** | 4/5 | All bundle mappings, exclusivity logic, and Doctible payloads correct. Lost 1 point for missing `async`, transaction ordering. |
| **Test Quality** | 2/5 | Comprehensive coverage targets, but 2 of 4 PRs contained tests that would always fail in CI (reference equality on wrapped errors, unsupported matchers). |
| **Self-Review Effectiveness** | 3/5 | Caught `calledOnceWithMatch` and transaction ordering. Missed test assertion logic errors, coverage gaps, and model shape regression. |
| **CI Readiness** | 2/5 | Only PR #116 (pure additive service) was CI-clean. PRs #115, #117, #118 all required human fixes. |
| **Overall Autonomy Level** | 3/5 | Fully autonomous during execution, but 75% of PRs required human remediation. |

---

## What Worked Well

### 1. Phase Decomposition
Agent correctly identified a 4-phase dependency chain matching the PRD structure. All phases stayed within decomposition gates (2-7 files, 180-340 LOC). Phase ordering was dependency-correct.

### 2. Business Logic Implementation
- Tier-to-billing-flag mapping was **correct for all 12 combinations** (tier1/tier2/tier3 x chc/trizetto/waystar/none)
- Mutual exclusivity for ct-engage/ct-engage-pro/ct-remind enforced in both v1 runtime and v2 schema
- Doctible payload `engagePro: true` flag correctly added for ct-engage-pro
- Side-effect extraction preserved all existing behavior paths

### 3. Test Coverage Quantity
168 new assertions across 4 PRs. Bundle resolution tests covered all 12 tier x clearinghouse combinations exhaustively. The *intent* of coverage was thorough even when assertion mechanics were wrong.

### 4. Self-Remediation Loop
Phase 4 went through 3 self-review rounds and 2 remediation cycles — the agent caught the `calledOnceWithMatch` API issue and the transaction-coupling bug on its own. The task-memory-driven review-fix-review loop is a sound architectural pattern.

---

## What Didn't Work

### Test Validation Was Completely Blocked
Agent reported in **every phase summary**: "targeted mocha run remains environment-blocked by local MySQL connectivity (SequelizeConnectionRefusedError)". It never escalated this as a blocker — just continued implementing and marked tasks complete.

This was an avoidable operator error — the local test environment could have been started before launching the agent. But the tool also failed to enforce a pre-flight check or escalate after repeated failures.

### Test Assertion Logic Errors
- **PR #117**: `expect(caughtError).to.equal(expectedError)` — reference equality fails because `stubMsRequest` wraps errors as `MsRequestError`
- **PR #118**: `calledOnceWithMatch` doesn't exist in project's chai-sinon setup (3 occurrences)
- **PR #118**: `handleTierDowngradeSideEffects` not `async` -> `.catch()` on `undefined` -> TypeError

### Coverage Gaps from Control Flow Errors
- **PR #117**: `if (e.isDoctibleNotificationError)` false branch unreachable because RevAccel was in same try-catch -> 99.68% branch coverage vs 100% threshold
- **PR #118**: `if (req.log?.error)` guard creates uncovered branch since req.log always exists -> 99.68% branch coverage

### Cross-PR Regression
**PR #115**: Adding nullable `productBundle` and `numberOfClaims` to Tenant model broke 8 deep-equality tests in existing suite that expected exact model shape.

---

## Self-Review Gap Analysis

| PR | Agent Verdict | Human Verdict | Bugs Found by Agent | Bugs Missed by Agent |
|----|:---:|:---:|:---:|:---:|
| #115 | Approved w/ Suggestions | Changes Requested | 0 | 1 (model shape regression) |
| #116 | Approved w/ Suggestions | Approved w/ Suggestions | 0 | 0 |
| #117 | **Approved** | **Changes Requested** | 0 | 2 (test logic, coverage gap) |
| #118 | Changes Req -> Approved | Changes Requested | 2 | 1 (missing async) |

**Worst miss**: Phase 3 self-review said "Approved" with zero issues found, but human review found 2 bugs and a coverage gap. The self-review was reading its own code without the skepticism that comes from actually running it.

**Pattern**: Agent self-review caught **structural** issues (wrong API name, wrong code location) but missed **semantic** issues (error wrapping behavior, branch reachability, async contract). Static analysis without execution evidence is insufficient for test correctness.

---

## Root Cause Analysis

### 1. No Test Execution (Deepest Cause)
The agent workspace had no MySQL, Kafka, or terminus bootstrapping. Every mocha attempt failed with `SequelizeConnectionRefusedError`. The agent noted this 18 times but never escalated. This single gap explains 3 of 5 bugs — all would have been caught by running `npm test`.

**Operator note**: This was avoidable. Starting the test environment before launching the agent would have resolved the issue. Future runs should include a pre-flight smoke test.

### 2. No Hard Gate on Test Execution in Workflow
The execution command says "Run build, tests, and lint" but has no enforcement. Agent interpreted "validation" as `npm run build` + scoped ESLint and continued to PR creation.

### 3. Self-Review Lacks Test-Evidence Requirement
The review command template (`review-pr-codex.md`) focuses on code structure and PR analysis categories. It never asks: "Were tests actually executed? Did they pass?"

### 4. Agent Didn't Detect Repeated Failure Pattern
Same environment error 18 consecutive times -> no strategy change, no escalation. The agent loop lacks meta-cognitive detection for systematic failures vs. code bugs.

---

## Improvement Recommendations

### P1: Make Test Execution a Hard Gate (Critical)

Add to `implement-prd-execution-codex.md` Step 4E.5: If test execution fails with **environment errors** (not code errors) for 2 consecutive attempts -> mark task `blocked`, output "VALIDATION BLOCKED", stop. Do not create PR without test evidence.

### P2: Environment Pre-Flight Check (High)

Two-pronged fix:

1. **Operator checklist**: Before launching agent, run `npm test -- --bail --timeout 5000` to confirm environment is ready. Document this in agent README as a mandatory pre-launch step.

2. **Tool enforcement**: Add startup validation to `run-agent-codex.mjs` — before entering task loop, run a smoke test. If it fails with environment errors, warn operator upfront rather than discovering it 18 tasks later.

### P3: Test-Focused Self-Review Checklist (High)

Add to review command template:
- For every new test: verify matcher exists in project (check 3+ existing test files for usage)
- For every new branch in implementation: verify both true/false paths are covered by tests
- For model schema changes: grep for deep-equality assertions in existing tests
- Require: "Were tests executed? If not, record `no-test-execution-evidence` as Important issue."

### P4: Repeated-Failure Circuit Breaker (Medium)

In agent runner: if same error signature appears in 3+ consecutive task summaries, pause loop and require human acknowledgment before continuing.

### P5: Validation Confidence in PR Description (Medium)

Template PR description with explicit validation status: `Tests: Passed / Blocked (reason) / Not Run`. Makes human reviewer immediately aware of confidence level.

---

## Cost-Benefit Assessment

### Investment

| Category | Cost |
|----------|-----------|
| Agent wall clock | 1.5 hours (automated) |
| Human PRD creation | ~2 hours |
| Human review + fixes | ~3 hours (PR #115: 30min, #116: 15min, #117: 45min, #118: 1.5hr) |
| **Total human time** | **~5 hours** |

### Output

| Metric | Value |
|--------|-------|
| PRs created | 4 |
| Files changed | 19 |
| LOC changed | ~1000 |
| CI-ready without fixes | 1 of 4 (25%) |

### By PR Type

| Type | Example | Agent ROI |
|------|---------|-----------|
| **Additive greenfield** | PR #116 (bundle service) | **High** — CI-clean, 15min review for 260 LOC |
| **Behavior-preservation refactor** | PR #117, #118 | **Negative without test execution** — human fixes exceeded time savings |
| **Schema migration** | PR #115 | **Marginal** — correct code, missed test regression |

### Break-Even Projection

If test execution had worked (achievable with a 30-second pre-flight check), an estimated 3 of 5 bugs would have been caught by the agent itself, reducing human remediation from ~3 hours to ~30 minutes. At that point: **2.5 hours human time for 1000 LOC across 4 PRs = strongly positive ROI**.

**Bottom line**: Fix P1 (test execution gate) and P2 (environment pre-flight). With those two fixes — one operator discipline, one tool enforcement — the agent becomes viable for refactoring work, not just additive greenfield.

---

## Artifacts

- Agent workspace: `neb-ms-registry/gbb-tenant-provisioning-phase-1/`
- Task memory: `.gbb-tenant-provisioning-phase-1/task_memory.json`
- Agent logs: `.gbb-tenant-provisioning-phase-1/agent_logs-codex/`
- Self-review reports: `.gbb-tenant-provisioning-phase-1/review_*.md`
- PRD: `gbb-tenant-provisioning-phase-1/PRD-gbb-tenant-provisioning-phase-1.md`
- Tool source: `ptek-ai-playbook/experimental/auto-agent-codex/`
