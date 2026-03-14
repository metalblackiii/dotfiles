# Interview Protocol

Detailed workflow for the ratchet interview phase. Catch bad setups before burning iterations — every minute in the interview saves ten minutes of wasted loop time.

## Step 1: Parse User Input

Extract from the user's invocation:

- **Goal** — what they want to improve
- **Scope** — which files are in play
- **Metric** — what number defines success
- **Direction** — higher or lower is better
- **Verify command** — how to measure it
- **Iterations** — how many (default 10)

If any are missing, ask. Don't guess. Don't infer a metric from a vague goal — surface the ambiguity.

## Step 2: Validate Metric Clarity

The goal must be reducible to a number that a shell command can produce.

If the user's goal is subjective, suggest proxy metrics:

| Subjective goal | Proxy metric |
|---|---|
| "Make it cleaner" | Lint warning count (lower) |
| "Improve code quality" | Coverage % (higher), cyclomatic complexity (lower), `any` count (lower) |
| "Make it faster" | Benchmark time in ms (lower) |
| "Simplify this module" | LOC with tests still passing (lower) |
| "Better error handling" | Uncaught exception count in test suite (lower) |
| "More readable" | Flesch-Kincaid grade level (lower) — for docs/content |
| "Fewer bugs" | Failing test count (lower) or lint error count (lower) |

If no reasonable proxy exists, say so: "This goal doesn't reduce to a mechanical metric. Ratchet isn't the right tool — consider a manual iteration approach instead."

## Step 3: Validate Verify Command

### 3a: Construct the command

The verify command must produce `SCORE: <number>` in its output. Help the user build this.

Common patterns:

```bash
# Test coverage
npm test -- --coverage 2>&1 | grep "All files" | awk '{print "SCORE:", $4}'

# Lint warnings
npx eslint src/ --format compact 2>&1 | grep -c ":" | awk '{print "SCORE:", $1}'

# Bundle size (KB)
npm run build 2>&1 | grep "First Load JS" | awk '{print "SCORE:", $4}'

# TypeScript any count
rg ":\s*any\b" src/ --type ts -c | awk -F: '{s+=$2} END {print "SCORE:", s+0}'

# LOC count
find src/services -name "*.ts" | xargs wc -l | tail -1 | awk '{print "SCORE:", $1}'

# Benchmark (ms)
npm run bench 2>&1 | grep "p95" | awk '{print "SCORE:", $2}'

# Python test coverage
pytest --cov=src --cov-report=term 2>&1 | grep "TOTAL" | awk '{print "SCORE:", $NF}' | tr -d '%'
```

### 3b: Run it once

Execute the verify command. Check:

- Does it complete without hanging?
- Does the output contain `SCORE: <number>`?
- Is the number reasonable for the domain?

If it fails, diagnose and fix the command before proceeding. Common issues:

| Problem | Fix |
|---|---|
| Command not found | Check PATH, suggest `npx` prefix |
| No SCORE in output | The grep/awk pipeline doesn't match the actual output — run the base command alone first to see raw output, then adjust |
| SCORE: NaN or empty | Extraction pattern doesn't match the format |
| Hangs indefinitely | Add a timeout, or the underlying command needs `--no-watch` or similar |

### 3c: Run it again

Execute a second time. Compare the two scores.

- Identical scores: stable metric. Proceed.
- Variance under 2%: acceptable noise. Note it.
- Variance over 2%: surface it explicitly:

```
"Your metric varied from 84.2 to 81.7 across two runs — that's a 3% swing.
Changes improving by less than this margin will be indistinguishable from noise.

Options:
  1. Proceed anyway (expect noisier iterations)
  2. Adjust the verify command for stability
  3. Pick a different metric"
```

Let the user decide. Record the variance — it informs the "barely improved" threshold during the loop.

## Step 4: Validate Scope

Count the in-scope files via glob expansion.

| File count | Guidance |
|---|---|
| 1-20 | Focused scope — ideal |
| 21-50 | Acceptable |
| 51-100 | Warn: "Each iteration reads changed files. Consider narrowing to the module most likely to move the metric." |
| 100+ | Strongly suggest narrowing: "Which subdirectory matters most for this metric?" |

Also check: are any files in scope that shouldn't be modified? (Config files, generated code, vendored dependencies.) Surface these and confirm they should be writable or excluded.

## Step 5: Validate Goal

Compare the target to the baseline from the first verify run.

| Situation | Guidance |
|---|---|
| Gap > 50% of current value | "That's ambitious. Ratchet makes incremental progress — you may need multiple sessions or an intermediate target." |
| Baseline already meets target | "Baseline already exceeds your goal. Did you mean a tighter target?" |
| Direction ambiguous | Ask: "Should I minimize or maximize this number?" |
| No explicit target | That's fine — ratchet improves from baseline. Note "no fixed target, maximize improvement." |

## Step 6: Confirm Iterations

Default to 10. Always surface it as adjustable:

```
"I'll run 10 iterations by default. Each makes one atomic change and verifies.

Want more or fewer?"
```

Suggest adjustments based on verify speed:

| Verify duration | Suggestion |
|---|---|
| Under 5 seconds | "15-20 iterations is practical" |
| 5-30 seconds | "10 is a solid default" |
| Over 30 seconds | "Consider 5 iterations, or speeding up the verify command first" |

## Step 7: Surface the Log File

Before presenting the summary, mention the log file:

"I'll create a `.ratchet-log.tsv` file in the working directory to track iterations. This is outside your declared scope — you can delete it after the session."

If a `.gitignore` exists and doesn't already cover `.ratchet-log.tsv` or `*.tsv`, mention adding it.

## Step 8: Present Setup Summary

```
=== Ratchet Setup ===
Goal:       <human-readable goal>
Baseline:   SCORE: <number from first verify run>
Direction:  <higher/lower> is better
Verify:     <the exact command>
Scope:      <file glob patterns>
Iterations: <N>
Stability:  ✓ (<score1>, <score2> — <variance>%)
Log:        .ratchet-log.tsv (outside scope, deletable after)

Proceed? (confirm or adjust)
```

Wait for explicit confirmation. If the user adjusts anything, re-validate the changed inputs (re-run verify if the command changed, re-check scope if it widened, etc.) and present the summary again.
