# Eval Workflow

Detailed step-by-step guide for running eval-driven iteration on skills. For an overview, see the main SKILL.md.

## Workspace Layout

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a descriptively named directory. Create directories as you go.

## Step 1: Spawn all runs in the same turn

For each test case, spawn two subagents in the same turn — one with the skill, one without (baseline). Launch everything at once so it finishes around the same time.

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Baseline run** (same prompt, depends on context):
- **Creating a new skill**: no skill at all. Save to `without_skill/outputs/`.
- **Improving an existing skill**: the old version. Snapshot first (`cp -r <skill-path> <workspace>/skill-snapshot/`), point baseline at snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case (assertions can be empty initially). Give each eval a descriptive name based on what it's testing — not just "eval-0":

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

## Step 2: Draft assertions while runs are in progress

Don't wait for runs to finish. Draft quantitative assertions for each test case. Good assertions are objectively verifiable and have descriptive names that read clearly in the benchmark viewer. Don't force assertions onto subjective outputs — those are better evaluated qualitatively.

Update `eval_metadata.json` and `evals/evals.json` with assertions once drafted.

For programmatically checkable assertions, write and run a script rather than eyeballing — scripts are faster, more reliable, and reusable across iterations.

## Step 3: Capture timing data as runs complete

When each subagent task completes, the notification contains `total_tokens` and `duration_ms`. Save immediately to `timing.json` in the run directory — this data isn't persisted elsewhere and cannot be recovered after the fact:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

## Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run** — spawn a grader subagent that reads `agents/grader.md` and evaluates assertions against outputs. Save to `grading.json` in each run directory. The expectations array must use fields `text`, `passed`, and `evidence` (not `name`/`met`/`details` or other variants) — the viewer depends on these exact names.

2. **Aggregate benchmark data** — collect grading results across all runs into a `benchmark.json` file (see `references/schemas.md` for the schema). Include pass_rate, time, and tokens per configuration, with mean +/- stddev and the delta. Put each with_skill version before its baseline counterpart.

3. **Analyst pass** — read benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` for what to look for: assertions that always pass regardless of skill (non-discriminating), high-variance evals (possibly flaky), and time/token tradeoffs.

4. **Present results to the user** — use the HTML viewer (`eval-viewer/viewer.html`) to review test outputs and leave feedback. For iteration 2+, include previous iteration data for comparison.

### What the user sees in the viewer

**Outputs tab** (one test case at a time):
- Prompt, Output, Previous Output (iteration 2+, collapsed)
- Formal Grades (collapsed, if grading ran)
- Feedback textbox (auto-saves as they type), Previous Feedback (iteration 2+)

**Benchmark tab**: Pass rates, timing, token usage per configuration with per-eval breakdowns and analyst observations.

Navigation via prev/next buttons or arrow keys. "Submit All Reviews" saves all feedback to `feedback.json`.

## Step 5: Read feedback and iterate

Read `feedback.json` when the user is done:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the user thought it was fine. Focus improvements on test cases with specific complaints.

After improving the skill:
1. Rerun all test cases into `iteration-<N+1>/`, including baseline runs
2. Launch viewer with `--previous-workspace` pointing at previous iteration
3. Wait for user review, read feedback, improve, repeat

Keep going until the user is happy, feedback is all empty, or no meaningful progress.

## Advanced: Blind Comparison

For rigorous A/B comparison between two skill versions, read `agents/comparator.md` and `agents/analyzer.md`. The approach: give two outputs to an independent agent without revealing which is which, let it judge quality, then analyze why the winner won. Optional — human review is usually sufficient.

## Reference

See `references/schemas.md` for JSON schemas (evals.json, grading.json, benchmark.json, etc.). The viewer depends on exact field names — always reference the schema when generating JSON manually.
