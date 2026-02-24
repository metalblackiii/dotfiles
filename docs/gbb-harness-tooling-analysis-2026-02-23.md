# GBB Harness Tooling Analysis (Codex Autonomous Loop)

Date: 2026-02-23  
Author: Codex (analysis for Martin Burch)

## 1. Objective

Compare three candidate approaches for autonomous Codex-driven PRD execution against your provisioning-v2 use case:

1. `iannuttall/ralph`
2. `mikeyobrien/ralph-orchestrator`
3. `ptek-ai-playbook/experimental/auto-agent-codex` (in-house)

This doc also evaluates whether current GBB docs are missing information that would block harness engineering.

## 2. Context: Initial Use Case

Primary target flow is the GBB provisioning-v2 work in `neb-www` docs, especially:

- Backend phase design and phased rollout (`Phase 1` through `Phase 5`)
- Support app internal validation path
- Open provisioning/product questions impacting endpoint behavior and tier mapping

Key references:

- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/provisioning-v2-phase1-backend.md`
- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/provisioning-v2-phase2-support-app.md`
- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/open-questions-for-product.md`

## 3. Evaluation Criteria

1. Codex compatibility and backend flexibility
2. Loop maturity (planning, execution, review/remediation, resume)
3. Backpressure controls (scope gates, tests, stop conditions)
4. Operability (setup friction, observability, non-interactive operation)
5. Security posture controls (sandbox/approval defaults, policy controls)
6. Fit for your specific GBB phased rollout

## 4. Summary Comparison

| Criterion | iannuttall/ralph | ralph-orchestrator | ptek experimental |
|---|---|---|---|
| Codex support | Strong (explicit Codex modes/commands) | Strong (explicit `codex` backend via backend config) | Native (Codex SDK loop) |
| Loop maturity | Medium | High | Medium (good design, some missing pieces) |
| Backpressure | Medium (prompt/test driven) | High (retry/backoff/limits, policy controls) | Medium-High (strict phase and LOC gates in command spec) |
| Setup speed | High | Medium | Medium |
| Security controls | Medium | High | Medium-Low by default (`danger-full-access`, `approvalPolicy: never`) |
| In-house control | Low | Low | High |
| Current blocker count | Low | Low | Medium (notably missing `review-pr.md` dependency) |
| Best use | Fast lightweight pilot | Durable org-scale orchestrator | Internal custom workflow, if hardened |

## 5. Approach Analysis

### 5.1 `iannuttall/ralph`

What it is:

- Lightweight autonomous loop harness with direct Codex examples (`--agent=codex`, `AGENT_CMD="codex exec --yolo -"`), plus fast setup path.

Strengths:

- Fastest path to run a realistic autonomous loop.
- Minimal abstraction overhead; easy to reason about failure modes.
- Good option for proving your GBB harness assumptions quickly.

Gaps:

- Less out-of-the-box enterprise orchestration than orchestrator-style systems.
- You will still need project-specific policy and eval wrapping for HIPAA-adjacent repos.

Fit for your use case:

- Strong for a 1-2 week proof run on one bounded phase (GBB Phase 1 backend).

### 5.2 `mikeyobrien/ralph-orchestrator`

What it is:

- Full orchestrator focused on backpressure/reliability. Supports multiple backends, with docs listing `codex` as a configurable backend.

Strengths:

- Most mature execution control plane among the three.
- Better operational guardrails for long-running autonomous loops.
- Better long-term candidate if you want shared team infrastructure.

Gaps:

- Heavier to stand up and tune for a first pilot.
- You may need adaptation to map your existing PRD/task-memory conventions.

Fit for your use case:

- Best long-term if you want a platform, not just a script.
- Could be overkill for immediate Phase 1 proof.

### 5.3 `ptek-ai-playbook/experimental/auto-agent-codex` (in-house)

What it is:

- In-house Codex SDK loop with strong PRD decomposition patterns:
  - single-repo/single-service phase constraint
  - explicit per-phase scope budgets
  - mandatory review/remediation loop insertion
  - optional Playwright validation cycles

Strengths:

- Domain fit is excellent for your current PRD-driven workflow.
- In-house code lowers external security/compliance surface area.
- Already aligned with your desired planning->execution->review loop behavior.

Gaps (current):

1. Functional dependency gap:
   - `review-pr-codex.md` requires `resources/commands/review-pr.md`, but that file is not present.
2. Safety defaults are permissive:
   - runner thread starts with `approvalPolicy: "never"` and `sandboxMode: "danger-full-access"`.
3. CLI/operability maturity:
   - onboarding is mostly interactive; limited non-interactive automation knobs.
4. Documentation quality issues:
   - stale naming references (`autonomous_agent 2`) increase setup confusion.

Fit for your use case:

- Very good if you want to keep ownership internal.
- Needs a hardening pass before treating it as “ready default”.

## 6. Recommended Decision Pattern

Given your constraints (you do not admin playbook, but prefer in-house when possible):

1. Short-term pilot runner: `iannuttall/ralph` for speed and low friction.
2. In parallel: submit focused hardening issues/PRs for ptek experimental.
3. Re-evaluate in 2-3 weeks:
   - If ptek hardening lands, consolidate on in-house.
   - If not, either continue on ralph or move to orchestrator for platform-grade controls.

## 7. Pilot Plan Using Your Initial Use Case

### 7.1 Scope the Pilot to Phase 1

Pilot only `Phase 1: Tier Mapping + Side Effects Extraction + DB Schema` from provisioning-v2.

Reason:

- It is explicitly bounded and does not require unresolved Salesforce decisions.
- It is high-value but low external dependency compared to later phases.

### 7.2 Pilot Matrix

Run the same bounded pilot across all 3 approaches.

#### Pilot A: Planning Quality

Input:

- `provisioning-v2-phase1-backend.md` and linked mapping docs.

Expected output:

- Phase plan with file list, risk list, tests, and stop conditions.

Pass criteria:

- No multi-repo phase bleed.
- Explicit test commands and data setup.
- Open questions either resolved or explicitly deferred with assumptions.

#### Pilot B: Execution Quality

Input:

- Approved pilot plan.

Expected output:

- Working branch with:
  - side-effect extraction scaffold
  - bundle resolution service
  - DB migration for `productBundle`/`insuranceBundle`
  - unit tests for mapping + side effects

Pass criteria:

- Local tests pass.
- Change stays within agreed scope budget.
- No unresolved critical review findings.

#### Pilot C: Review/Remediation Loop

Input:

- Pilot B PR.

Expected output:

- Review report with severity classes and remediation patch cycle.

Pass criteria:

- At least one remediation cycle executes cleanly.
- Final PR has no Critical/Important issues.

### 7.3 Metrics to Compare Tools

Capture these for each approach:

1. Time to first valid plan
2. Time to first reviewable PR
3. Number of human interventions required
4. Number of loop stalls/retries
5. Defect density found in review
6. Rework volume after review

Use a simple scorecard (`1-5`) on speed, quality, and operational burden.

## 8. GBB Docs Readiness for Harness Engineering

Short answer: **not fatally broken**, but there are a few high-impact gaps that will cause loop thrash if not pinned before execution.

### 8.1 High-Impact Gaps (can kill autonomous execution if unresolved)

1. Unresolved mapping/API decisions in provisioning doc:
   - Salesforce product code mapping
   - standalone add-on API handling
   - downgrade behavior and RCM removal semantics
   - PATCH vs PUT compatibility
   - PROCLEAR/WAYSTAR tier placement
2. External side-effect behavior not fully executable in local harness:
   - Doctible/partner notifications
   - Kafka downgrade side effects

Why this matters:

- Autonomous loops need deterministic acceptance criteria and mock/integration strategy.
- Ambiguous endpoint semantics drive repeated “plan -> replan” churn.

### 8.2 Medium Gaps (won’t kill pilot if scoped tightly)

1. Missing explicit “commands to run” by phase/repo in docs.
2. Missing machine-readable acceptance criteria per phase.
3. Migration-wave details intentionally deferred (acceptable for Phase 1 pilot).

### 8.3 Mitigation Checklist Before Running Any Harness

1. Freeze pilot scope to Phase 1 only.
2. Add an assumption block for open items (explicitly out-of-scope in pilot).
3. Define exact verification commands per touched repo.
4. Define mock strategy for side effects (partner/Kafka).
5. Define stop conditions and “escalate to human” conditions.

## 9. Practical Recommendation

If you want progress this week:

1. Pilot with `iannuttall/ralph` immediately for Phase 1 only.
2. Open a small hardening request set for ptek experimental:
   - add missing `resources/commands/review-pr.md`
   - safer default execution policy
   - non-interactive setup flags
   - README cleanup
3. Re-run the same pilot with hardened ptek and compare scorecard.

If hardened ptek matches or beats ralph on intervention count + review quality, move in-house.

## 10. Evidence and Sources

### Internal (local repos)

- `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/run-agent-codex.mjs`
- `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/resources/commands/implement-prd-planning-codex.md`
- `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/resources/commands/implement-prd-execution-codex.md`
- `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/resources/commands/review-pr-codex.md`
- `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/bootstrap-agent.mjs`
- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/provisioning-v2-phase1-backend.md`
- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/provisioning-v2-phase2-support-app.md`
- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/open-questions-for-product.md`

### External

- Awesome Ralph list: https://github.com/snwfdhmp/awesome-ralph
- iannuttall/ralph repo: https://github.com/iannuttall/ralph
- iannuttall/ralph releases: https://github.com/iannuttall/ralph/releases
- mikeyobrien/ralph-orchestrator repo: https://github.com/mikeyobrien/ralph-orchestrator
- ralph-orchestrator docs: https://ralph-orchestrator.readthedocs.io/en/latest/

## 11. Head-to-Head Evaluation Plan: `ralph-orchestrator` vs `ptek-ai-playbook`

This section defines the immediate next step: run one controlled evaluation cycle for each tool on the same bounded scenario and score results with weighted criteria.

### 11.1 Scope Lock (must be identical for both tools)

- Target: `GBB provisioning-v2 Phase 1` only
- Repos in scope: only repos required by Phase 1 implementation
- Hard stops:
  - no Phase 2+ changes
  - no multi-repo expansion unless explicitly pre-approved
  - no unresolved product decision implementation; use documented assumptions only

### 11.2 Readiness Gate (before any execution run)

Pass/fail checks per tool:

1. Can start non-interactively from CLI/script (no manual prompt dependency)
2. Has explicit command path for planning, execution, and review/remediation
3. Can persist state and resume after interruption
4. Can enforce or at least report scope limits (files/LOC)
5. Uses acceptable safety defaults (or can be safely overridden for pilot)
6. No missing functional dependency for review loop

If a tool fails 2 or more checks, do not run execution cycle yet; log it as `readiness-failed`.

### 11.3 Single-Cycle Trial Protocol (per tool)

Run this exact sequence once per candidate:

1. Planning run
   - Input: Phase 1 PRD + assumption block
   - Output required: phase plan with files, tests, stop conditions
2. Execution run
   - Input: approved plan
   - Output required: branch with implementation + tests
3. Review/remediation run
   - Input: execution PR
   - Output required: review report + remediation tasks (if needed) + post-remediation state

Capture timestamps and intervention notes for each step.

### 11.4 Scoring Rubric (weighted)

Score each category `1-5` (5 is best), then multiply by weight.

| Category | Weight | Scoring Guidance |
|---|---:|---|
| Reliability / Loop completion | 30% | Completes planning->execution->review without manual recovery |
| Human intervention burden | 25% | Fewer manual corrections, reruns, or prompt surgery |
| Review/remediation quality | 20% | Finds meaningful issues, inserts/executes remediation cleanly |
| Safety/operational control | 15% | Safe defaults, policy controls, clear stop conditions |
| Throughput (speed) | 10% | Time to first reviewable PR and final reviewed state |

Weighted score formula:

`total = sum(category_score * weight_percent)`

Example:

- Reliability `4` x `0.30` = `1.20`
- Intervention `3` x `0.25` = `0.75`
- Review quality `4` x `0.20` = `0.80`
- Safety `3` x `0.15` = `0.45`
- Speed `4` x `0.10` = `0.40`
- Total = `3.60 / 5.00`

### 11.5 Result Capture Template

| Metric | ralph-orchestrator | ptek-ai-playbook |
|---|---|---|
| Readiness gate status (pass/fail) |  |  |
| Time to first valid plan |  |  |
| Time to first reviewable PR |  |  |
| Time to reviewed/remediated state |  |  |
| Human interventions (#) |  |  |
| Loop stalls/retries (#) |  |  |
| Critical findings in review (#) |  |  |
| Important findings in review (#) |  |  |
| Rework volume after review (files/LOC) |  |  |
| Weighted score (out of 5.0) |  |  |

### 11.6 Decision Rule

1. If one tool fails readiness and the other passes, choose the passing tool for pilot continuation.
2. If both pass readiness, choose the higher weighted score.
3. Tie-breakers in order:
   - lower intervention count
   - stronger safety/operability posture
   - faster time to reviewed/remediated state

### 11.7 Immediate Next Action

Execute readiness gate for both tools first, then run the single-cycle trial for the tool(s) that pass.

## 12. Benchmark Wrappers (2026-02-24)

To standardize inputs across both tools, use these wrapper assets:

- Canonical benchmark spec:
  - `/Users/martinburch/repos/dotfiles/docs/gbb-phase1-benchmark-2026-02-24.md`
- Ralph wrappers:
  - `/Users/martinburch/repos/dotfiles/docs/ralph-gbb-phase1-prompt-2026-02-24.md`
  - `/Users/martinburch/repos/dotfiles/docs/ralph-gbb-phase1-config-2026-02-24.yml`
- ptek wrappers:
  - `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/PRD-gbb-phase1-benchmark.md`
  - `/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex/prd_list.json`

### 12.1 Suggested Execution Order

1. `Readiness` (tool install/auth/required files)
2. `Planning-only trial` on both tools
3. `Full cycle attempt` on both tools (planning -> execution -> review)
4. Capture metrics using Section 11.5 table

### 12.2 Notes

- These wrappers intentionally freeze Phase 1 assumptions and hard stops.
- If either tool exceeds scope guardrails, classify as intervention event and score accordingly.

## 13. Run Results (2026-02-24, sandbox)

Sandbox target repo:

- `/tmp/gbb-phase1-neb-ms-registry`

### 13.1 ptek-ai-playbook

Status: `partially passed` (planning complete, execution in progress)

Observed progress:

1. Root planning task completed:
   - output: `.gbb-phase1/phase_breakdown_mb/gbb-phase1-benchmark.md`
2. Phase planning task completed:
   - output: `.gbb-phase1/plan_mb/gbb-phase1-benchmark-phase1.md`
3. Execution task started and produced concrete code/test/migration changes in sandbox:
   - updated: `src/controllers/v1/tenants/:tenantId/addons/post.js`
   - updated: `src/controllers/v1/tenants/:tenantId/addons/util.js`
   - updated: `src/models/tenant.js`
   - added: `src/services/provisioning-v2/{tier-constants,apply-bundles,addon-side-effects}.js`
   - added: `migrations/20260224023000-alter-tenant-add-product-insurance-bundle.js`
   - added: `test/services/provisioning-v2/{apply-bundles,addon-side-effects}.test.js`

Known issues:

- Execution required dependency install in sandbox (`npm ci --cache .npm-cache`) before tests.
- Long-turn stability noise from Codex runtime:
  - repeated `failed to queue rollout items: channel closed`
  - occasional turn-level non-zero exits despite partial task-memory progress
- Execution was intentionally interrupted before any push/PR behavior to keep benchmark local-only.

### 13.2 ralph-orchestrator

Status: `blocked/incomplete` (planning-only trial did not produce plan artifact yet)

Observed behavior:

1. Runner starts with codex backend and iterates.
2. Progresses through source reading and task/memory management.
3. Did not emit planning artifact at `.ralph/gbb-phase1-plan.md` during this pass.
4. Session interrupted after prolonged run and repeated Codex runtime noise.

Known issues:

- Same Codex runtime noise pattern during execution:
  - repeated `failed to queue rollout items: channel closed`
  - `Operation not permitted` warnings for cache/path writes

### 13.3 Interpretation for Section 11 Protocol

- Readiness gate: both tools can start and route commands in sandbox.
- Single-cycle trial: ptek advanced further (planning complete + execution started with real file changes); ralph planning-only pass is still incomplete.
- Review/remediation stage is not yet executed in this sandbox cycle; scoring table (11.5) is therefore still preliminary.

## 14. Clean Reset A/B Pass (2026-02-24, strict timebox)

This section captures a second apples-to-apples pass run after sandbox reset.

Run setup:

- ptek sandbox: `/tmp/gbb-phase1-neb-ms-registry`
- ralph sandbox: `/tmp/gbb-phase1-neb-ms-registry-ralph`
- Same Phase 1 wrapper inputs and hard boundaries
- Ralph runtime budget: up to 2x ptek runtime budget

### 14.1 Evidence Snapshot

| Metric | ptek-ai-playbook | ralph-orchestrator |
|---|---|---|
| Readiness gate | `pass` (after relinking `resources` to in-house command set) | `pass` |
| Time to first valid plan | `~1m57s` (`02:31:48Z` -> `02:33:45Z`) | N/A (single loop model; no separate planning artifact) |
| Time to first implementation commit | `~19m42s` from run start (`bbe950d`) | `~5m51s` from loop start (`63909d0`) |
| Completed atomic tasks | 2 planning tasks complete; 1 execution task failed | 2 tasks closed with commits; 2 tasks still open |
| Execution end state | `failed` due push error (`remote unpack failed`); local commit exists | `in-progress` when timebox ended; no hard failure recorded |
| Commits produced | `bbe950d` | `63909d0`, `d6b3ba3` |
| Scope evidence | Side-effects extraction landed + tests | Migration/model + side-effects extraction landed |
| Review/remediation loop | Not completed end-to-end (self-review steps occurred inside execution) | Not completed end-to-end |
| Runtime stability signals | Codex rollout/cache warnings observed | Same warnings observed; internal retries recorded |

### 14.2 Commit-Level Output

`ptek-ai-playbook`:

- `bbe950d refactor(add-ons): extract v1 add-on side effects service`
- Files:
  - `src/controllers/v1/tenants/:tenantId/addons/post.js`
  - `src/services/add-ons/side-effects.js`
  - `test/services/add-ons/side-effects.test.js`

`ralph-orchestrator`:

- `63909d0 feat(tenant): add bundle columns for phase1 provisioning`
  - `migrations/20260224120000-alter-tenant-add-bundle-columns.js`
  - `src/models/tenant.js`
- `d6b3ba3 refactor: extract add-on side effects service`
  - `src/controllers/v1/tenants/:tenantId/addons/post.js`
  - `src/services/addon-side-effects.js`

### 14.3 Weighted Score (Section 11.4 rubric, preliminary)

Scores are `1-5`, then weighted. This is preliminary because neither run completed full review/remediation.

| Category | Weight | ptek | ralph |
|---|---:|---:|---:|
| Reliability / loop completion | 30% | 2.5 | 3.0 |
| Human intervention burden | 25% | 2.5 | 3.0 |
| Review/remediation quality | 20% | 2.5 | 1.5 |
| Safety/operational control | 15% | 2.0 | 4.0 |
| Throughput (speed) | 10% | 2.5 | 4.0 |
| Weighted total | 100% | **2.43 / 5.00** | **2.95 / 5.00** |

Interpretation:

- `ralph-orchestrator` leads on this pass due faster atomic delivery and stronger orchestration controls.
- `ptek-ai-playbook` showed stronger built-in phase planning shape, but this run was penalized by push-coupled failure semantics.
- Final tool choice should wait for one more pass where both tools complete full planning -> execution -> review/remediation with push behavior normalized.

### 14.4 Completion Pass (No-Push Wrapper, Raw vs Normalized)

This pass reran both tools with:

- clean reset sandboxes
- identical pre-provision (`npm install --cache .npm-cache --no-audit --no-fund`)
- push/PR decoupled for ptek execution benchmark wrapper
- Ralph runtime budget capped at 2x ptek runtime

Observed runtime windows:

- ptek run: `2026-02-24T03:26:46Z` -> `2026-02-24T03:42:05Z` (`~15m19s`)
- ralph run: `2026-02-24T03:42:31Z` -> `2026-02-24T04:07:26Z` (`~24m55s`)

Outcome snapshot:

- `ptek-ai-playbook`
  - completed: root planning, phase1 planning, phase1 execution
  - produced commit: `6a0d032`
  - pending at stop: `gbb-phase1-phase1-execution-pr-review`, phase2 planning, phase3 planning
  - stop cause: runner hit consecutive Codex runtime shutdown errors before continuing to review turn
- `ralph-orchestrator`
  - completed all four Phase 1 runtime tasks and emitted `LOOP_COMPLETE`
  - produced commits:
    - `70cc00f` (side-effect extraction)
    - `4bf4bb4` (tier resolver/apply + tests)
    - `9295f0d` (tenant bundle columns migration)
    - `787c2e1` (expanded bundle/side-effect test coverage)
  - events file recorded sequential `task.done` entries and final completion event

Raw vs normalized scoring:

- `Raw`: includes runtime friction/noise and harness instability effects
- `Normalized`: discounts environment/runtime artifacts (e.g., Codex shutdown recorder failures) to emphasize workflow behavior

| Category | Weight | ptek Raw | ptek Normalized | ralph Raw | ralph Normalized |
|---|---:|---:|---:|---:|---:|
| Reliability / loop completion | 30% | 2.6 | 3.4 | 4.3 | 4.5 |
| Human intervention burden | 25% | 2.5 | 3.3 | 3.8 | 4.1 |
| Review/remediation quality | 20% | 1.6 | 2.4 | 3.3 | 3.5 |
| Safety/operational control | 15% | 2.1 | 2.2 | 4.0 | 4.0 |
| Throughput (speed) | 10% | 2.8 | 3.0 | 4.0 | 4.1 |
| Weighted total | 100% | **2.36 / 5.00** | **2.97 / 5.00** | **3.87 / 5.00** | **4.09 / 5.00** |

Decision from this pass:

- Winner: `ralph-orchestrator` on both `Raw` and `Normalized` tracks.
- Main reason: it closed the complete Phase 1 objective with atomic task lifecycle and commits inside the 2x budget, while ptek did not reach its review/remediation turn before runtime failure stop.
