---
name: ratchet
description: ALWAYS invoke for autonomous metric-driven iteration on a measurable goal. Do not iterate on metrics directly. Not for subjective goals without a mechanical proxy or one-shot changes.
disable-model-invocation: true
---

# Ratchet — Metric-Driven Iteration

Autonomous iteration on any task with a measurable outcome. One atomic change, verify against a mechanical metric, keep improvements, restore failures. Repeat.

Core insight from Karpathy's autoresearch: constraint + mechanical metric + iteration = compounding gains. Ratchet adapts this to work within existing process skills — it never touches git, never claims completion, and always hands off for review.

## When to Use

- Any task where "better" equals a number a command can produce
- Improving test coverage, reducing bundle size, eliminating lint warnings, optimizing benchmarks, reducing LOC while keeping tests green, improving readability scores, tightening type safety

## When NOT to Use

- Subjective goals without a proxy metric ("make it cleaner" — unless you can define a number)
- Tasks requiring human judgment at each step
- One-shot changes where iteration adds no value

## Output Contract

The verify command must produce `SCORE: <number>` somewhere in its output. The interview phase helps craft this.

```bash
# Example: extract coverage percentage
npm test -- --coverage 2>&1 | grep "All files" | awk '{print "SCORE:", $4}'
```

The skill parses for the first `SCORE:` match. Everything else in the output is ignored.

## Phase 1: Interview

Interactive. Always runs. Always ends with explicit user confirmation before any iteration begins.

Read `references/interview-protocol.md` for the full workflow.

### What the interview validates

| Check | Purpose | If it fails |
|---|---|---|
| Metric clarity | Is the goal measurable by a command? | Suggest proxy metrics |
| Verify command | Run it — does it produce `SCORE: <number>`? | Help craft the command |
| Stability | Run verify twice — do scores match? | Surface variance, let user decide |
| Scope | How many files? Is it bounded? | Suggest narrowing |
| Goal | Realistic given baseline? | Note ambition, suggest intermediate target |
| Iterations | Default 10. Surface as adjustable. | Suggest based on verify speed |

### Setup summary

After all checks pass, present and wait for confirmation:

```
=== Ratchet Setup ===
Goal:       <what we're improving>
Baseline:   SCORE: <number>
Direction:  <higher/lower> is better
Verify:     <the exact command>
Scope:      <file patterns>
Iterations: <N>
Stability:  ✓ (<score1>, <score2> — <variance>%)

Proceed? (confirm or adjust)
```

Do NOT enter the loop until the user confirms.

## Phase 2: The Loop

```
LOOP (N iterations):
  1. REVIEW   — Log history + in-scope files
  2. SNAPSHOT — Store current contents of files about to change
  3. MODIFY   — One atomic change (explainable in one sentence)
  4. VERIFY   — Run verify command (with timeout)
  5. DECIDE   — Parse SCORE, compare to best
  6. LOG      — Append to .ratchet-log.tsv
  7. STATUS   — Brief line every 5 iterations
```

### Decision logic

| Outcome | Action |
|---|---|
| Score improved | Keep the change |
| Score same or worse | Restore from snapshot, log **discard** |
| No `SCORE:` in output | **Stop loop** — setup is broken |
| Verify timed out | Restore snapshot, log **skip**, flag approach |
| 2 consecutive no-parse or timeout | **Stop loop** — systemic problem |
| Score barely improved but adds significant complexity | Treat as **discard** |
| Score unchanged but code is simpler | Treat as **keep** |

### Ideation priority

When choosing the next change:

1. **Exploit successes** — last change improved the metric? Try variants in that direction
2. **Explore untried** — check the log for what hasn't been attempted
3. **Combine near-misses** — two individually-neutral changes might compound
4. **Simplify** — remove code while maintaining metric
5. **Go radical** — when incremental changes stall, try something different

After 5 consecutive discards: re-read ALL in-scope files, review the full log, shift strategy.

### Revert mechanism

File snapshots, not git. Before each change:

1. Record the full filesystem state of in-scope files:
   - Contents of files about to be modified
   - List of files that exist (to detect new files created by the change)
2. Make the change
3. If the change doesn't improve the metric, restore completely:
   - Write original contents back to modified files
   - Delete any files created during this iteration that didn't exist before
   - If a file was deleted during this iteration, restore it from the snapshot

Constraint: each iteration should only modify existing in-scope files. Creating or deleting files is allowed but the agent must track these for clean restore. If an iteration requires changes outside the declared scope, skip it — don't silently expand scope.

No git operations during the loop. The working tree accumulates only net improvements.

## Phase 3: Finish

After all iterations complete (or early stop):

```
=== Ratchet Complete (N/N) ===
Baseline: <start> → Final: <end> (<delta>)
Keeps: X | Discards: Y | Skips: Z
Best change: #N — <description>

Run self-review or commit when ready.
```

Ratchet never claims completion. It presents results and hands off.

## Log Format

`.ratchet-log.tsv` in the working directory. Surface this in the interview: "I'll create a `.ratchet-log.tsv` file in the working directory to track iterations. This is outside your declared scope — I'll clean it up or you can delete it after." If `.gitignore` exists and doesn't already cover it, mention adding it.

```tsv
# metric_direction: higher_is_better
# goal: coverage above 90%
# verify: npm test -- --coverage 2>&1 | grep "All files" | awk '{print "SCORE:", $4}'
iteration	score	delta	status	description
0	84.2	0.0	baseline	initial state
1	86.1	+1.9	keep	add tests for auth middleware edge cases
2	84.2	-1.9	discard	refactor test helpers
3	0.0	0.0	skip	verify timed out — integration test approach
```

## Composition

Ratchet is a tactic skill. It slots into existing sequences without replacing anything:

```
test-driven-development  →  define the metric via tests
         ↓
      ratchet             →  iterate on the metric
         ↓
    self-review           →  review accumulated changes
         ↓
verification-before-completion  →  final check
```

## What Ratchet Does NOT Do

- Touch git (no commit, no reset, no stash)
- Run unbounded (always requires an iteration count)
- Claim completion
- Replace TDD, debugging, or review skills
- Auto-invoke (requires explicit `/ratchet`)
