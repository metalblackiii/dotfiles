---
name: prd-triage
description: ALWAYS invoke when deciding how to implement a PRD — whether to one-shot it, use a loop, or use agent teams. Triggers on "how should I implement this PRD", "triage this prd", "one-shot or loop", "should I use teams for this", or any decision about PRD execution strategy. Not for creating PRDs — use create-prd.
---

# PRD Triage

Analyze a PRD and recommend the best execution strategy. Platform-aware — recommends only strategies available on the current runtime.

## Input

A path to a PRD file, or the PRD content in the conversation context.

Read the PRD first. Do not recommend a strategy without reading the full spec.

If the PRD has obvious gaps (missing file scope, vague acceptance criteria, open questions), note them but still recommend a strategy. Suggest running `requirements-analyst` to close gaps before implementation.

## Step 1 — Platform Detection

Determine which runtime is executing this skill:

| Runtime | Detection | Available Strategies |
|---------|-----------|---------------------|
| **Claude Code** | You have access to `TeamCreate`, `SendMessage`, Agent tool | One-shot, Loop, Agent Teams (`/ai-teamup`) |
| **Codex** | You do NOT have `TeamCreate` or `SendMessage` | One-shot, Loop |

State the detected platform and available strategies before proceeding.

## Step 2 — Complexity Assessment

Score the PRD on five dimensions:

| Dimension | Low (1) | Medium (2) | High (3) |
|-----------|---------|------------|----------|
| **File scope** | 1-3 files | 4-8 files | 9+ files |
| **Cross-cutting** | Single module | 2-3 modules or repos, clear boundaries | Shared state, cross-service schema changes, tight coupling |
| **Ambiguity** | Clear AC, no open questions | Minor gaps, inferrable | Major gaps, needs clarification |
| **Test complexity** | Existing patterns, add cases | New test infrastructure needed | E2E, integration, multi-service |
| **Risk** | Cosmetic, additive-only | Behavioral change, existing callers | Data model, auth, financial, breaking |

Present the scores as a table. Compute the total (5-15).

## Step 3 — Strategy Recommendation

### Decision matrix

| Total Score | File Overlap Risk | Recommendation |
|-------------|-------------------|----------------|
| 5-8 | Any | **One-shot** — manageable complexity, no orchestration needed. Use `/handoff` if context degrades. |
| 9-11, clear file boundaries | Low | **Agent Teams** (Claude Code) or **One-shot with handoff** (Codex) |
| 9-11, overlapping files | High | **One-shot with handoff** — can't safely parallelize |
| 12-14, multi-repo with clear per-repo boundaries | Low | **Agent Teams** (Claude Code) — repo boundaries guarantee no overlap. Score is high due to breadth, not complexity per task. |
| 12-14, single-repo or tight coupling | Any | **Loop** — needs iteration, test/fix cycles, phased delivery |
| 15 | Any | **Loop** — and consider splitting the PRD into smaller PRDs first |

### File overlap check

For scores 9-11, check whether the PRD's tasks can be decomposed into non-overlapping file sets. This is the deciding factor between Teams and One-shot:

- **Non-overlapping:** Tasks modify distinct files → Teams can parallelize safely
- **Overlapping:** Multiple tasks modify the same files → Teams will cause merge conflicts → One-shot with handoff is safer
- **Multi-repo:** Different repos = non-overlapping by construction. Multi-repo PRDs with clear per-repo boundaries are ideal for Teams even at higher scores, since repo boundaries are the strongest ownership guarantee. Score the cross-cutting dimension based on coupling (shared schemas, API contracts) rather than just repo count.

### Historical calibration

If prior teamup runs are logged in the Waypoint journal (from `/ai-teamup` post-mortems), reference them:

- Check if similar PRDs (same repo, similar scope) were triaged before
- Note whether the prior strategy recommendation held up ("Strategy validation" from post-mortem)
- Adjust confidence based on track record — if past teamup runs for this repo had merge conflicts, bias toward one-shot

If no history exists, state: "No prior teamup data available — recommendation is based on static analysis only."

### Confidence and caveats

State your confidence in the recommendation (HIGH / MEDIUM / LOW) and any caveats:
- If the PRD has ambiguity gaps that could change the recommendation, flag them
- If the PRD could go either way, present both options with trade-offs
- If the PRD should be split before implementation, say so

## Step 4 — Output

Present the recommendation in this format:

```
## PRD Triage: <prd-name>

**Platform:** Claude Code / Codex
**Complexity score:** <N>/15
**File overlap risk:** Low / Medium / High
**Confidence:** HIGH / MEDIUM / LOW

### Recommendation: <One-shot / Loop / Agent Teams>

**Why:** <1-2 sentences explaining the reasoning>

**Execution path:**
- <specific next step — e.g., "Run `/ai-teamup PRD.md`" or "Start implementing directly" or "Run prd-loop with these phases">

**Caveats:**
- <any caveats, alternative strategies, or PRD gaps to resolve first>
```

If the recommendation is Agent Teams but the platform is Codex, state:

```
**Note:** Agent Teams is the ideal strategy for this PRD, but it requires Claude Code.
On Codex, the fallback is: <one-shot with handoff / loop>
```

## Strategy Reference

### One-shot
Best for small-to-medium, well-scoped changes (up to ~8 files). Implement directly in the current session. Use `/handoff` if context starts to degrade. Lowest token cost.

### Loop (prd-loop / ralph)
Best for convergence problems — implement, test, fix, iterate. Good when test feedback drives the implementation. Works on both platforms. Higher token cost but automated iteration. Setup overhead: needs clear phase definitions and test criteria.

### Agent Teams (/ai-teamup)
Best for parallelizable medium-to-large features with non-overlapping file boundaries. Avoids context rot by distributing work across specialists. Includes Mongoose gate (premise-challenging) and escalation protocol. ~7x token cost but avoids rework from context rot. Claude Code only.

## Anti-Patterns

- **Don't use Teams for 1-3 file changes** — the orchestration overhead exceeds the implementation work
- **Don't use One-shot for 9+ file cross-cutting changes** — context rot will degrade quality
- **Don't use Loop when there are no tests to drive iteration** — the loop has nothing to converge on
- **Don't force Teams when files overlap** — merge conflicts will cost more than sequential implementation
