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
