---
name: peer-review
description: >-
  ALWAYS invoke for multi-round code review using Codex as an isolated reviewer.
  Runs implement-review-fix cycles until the reviewer approves or circuit breaker trips.
  Triggers on peer review, codex review my changes, review cycle, iterative review.
  Not for single-pass local review (use self-review) or GitHub PR review (use review).
argument-hint: "[diff-command] [--max-rounds N]"
---

# Peer Review

Multi-round review cycle with enforced context isolation. You implement, a fresh Codex subprocess reviews, you fix, the same Codex session re-reviews — repeat until approved or the circuit breaker trips.

## Why This Works

The implementer is blind to their own assumptions. A separate reviewer process with zero implementation context catches what familiarity bias hides. Codex provides natural isolation: separate process, separate context window. Re-reviewing via session resume keeps the reviewer's memory of prior findings without cold-start overhead.

## Input

- **Diff scope** (optional): `git diff --staged`, `git diff main...HEAD`, etc. Default: `git diff --staged`, falling back to `git diff` if staged is empty.
- **`--max-rounds N`** (optional): Circuit breaker. Default: 6.

## Workflow

### Step 1: Capture the Diff

Determine the **diff mode** from the requested scope:

- **Working-tree mode** (default): `git diff --staged`, `git diff`, `git diff HEAD`, or no scope specified. Any scope that includes uncommitted local changes.
- **Branch mode**: `git diff main...HEAD`, `git diff <ref1>..<ref2>`, or any scope comparing only committed ranges. The key signal is the triple-dot or double-dot range syntax — these never include working-tree state.

Run the diff command.

**Working-tree mode only:** Also collect untracked files via `git ls-files --others --exclude-standard`, excluding `.peer-review/`. Untracked files are part of local work-in-progress but irrelevant when reviewing committed branch history.

If both diff and untracked list (if applicable) are empty, report "No changes to review" and stop.

Display: `Peer review: [N lines across M files] (working-tree mode)` or `(branch mode)`

### Step 2: Build the Review Prompt

Create `.peer-review/` if it doesn't exist: `mkdir -p .peer-review`

Write the prompt to `.peer-review/prompt-1.md`. It must be self-contained — Codex has no prior context.

The prompt instructs Codex to:

1. Read `~/.agents/skills/pr-analysis/SKILL.md` for review categories and severity definitions
2. Review the inlined diff against those criteria
3. Read full files for surrounding context on each changed file
4. Run a defensive code audit: empty catches, silent fallbacks, unchecked null/undefined, ignored promise rejections
5. Run a naming scan: vague names (`data`, `result`, `temp`, `handle*`, `process*`, `manager`, `helper`, `utils`) and "what" comments
6. For each finding, report: **Severity** (Critical/Important/Minor), **Location** (file:line), **Issue**, **Fix**
7. List what looks good
8. End with a summary line: `FINDINGS: X critical, Y important, Z minor`

Include the full diff output and untracked file contents inline in the prompt. The prompt file may be large — that's expected.

### Step 3: Dispatch to Codex

```bash
cat .peer-review/prompt-1.md | codex exec - \
  --full-auto \
  -o .peer-review/round-1.md \
  --json > .peer-review/events-1.jsonl
```

Extract and save the session ID for resume:

```bash
head -1 .peer-review/events-1.jsonl  # → {"type":"thread.started","thread_id":"<UUID>"}
```

Save the thread ID to `.peer-review/session-id`.

### Step 4: Apply Verdict Logic

Read `.peer-review/round-N.md`. Parse the `FINDINGS:` summary line for severity counts.

Apply progressive verdict thresholds:

| Rounds | APPROVED when | Rationale |
|--------|--------------|-----------|
| 1-3 | No findings at any severity | Early rounds: chase a clean review |
| 4-6 | No Critical or Important | Late rounds: minor-only findings are diminishing returns |

**APPROVED:** Display the review summary, note the round count, and stop.

**REVISE:** Display the full review output. Proceed to Step 5.

**No findings line found:** Show the raw output and ask the user whether to treat as REVISE or stop.

### Step 5: Fix

Address findings based on the current round's threshold:

- **Rounds 1-3:** Address all findings (Critical, Important, and Minor).
- **Rounds 4-6:** Address Critical and Important only. Minor findings are noted but not blocking.

For each finding:

1. Read the relevant files
2. Make targeted fixes
3. Stay within the scope of the findings — don't refactor, don't gold-plate

Display a brief summary of which findings you addressed and how.

If a finding is unclear or requires a design decision, ask the user before proceeding.

### Step 6: Re-Review via Resume

Recapture the diff for re-review. The diff command changes from round 1 — fixes are uncommitted local edits, so we need `git diff HEAD` to see them regardless of the original scope:

- **Working-tree mode:** Use `git diff HEAD` to capture all local changes (both staged and unstaged) against the last commit.
- **Branch mode:** Use `git diff HEAD` as well — the original branch range (e.g., `main...HEAD`) wouldn't include uncommitted fixes.

In both cases, also collect untracked files (exclude `.peer-review/`) since fixes may create new files.

**Scope caveat:** `git diff HEAD` captures *all* local changes, which may be broader than what round 1 reviewed if unrelated edits exist. If this is a concern, stash unrelated work before starting peer-review. Tracking per-file scope across rounds is a future enhancement.

Write the re-review prompt to `.peer-review/prompt-N.md`:

```
The implementer addressed your previous findings. Here is the updated diff:

<diff>
{updated diff output}
</diff>

<untracked-files>
{list and content of untracked files, if any}
</untracked-files>

Re-review:
1. Verify previously flagged issues are actually resolved
2. Check for new issues introduced by the fixes
3. Apply the same review criteria as before

End with: FINDINGS: X critical, Y important, Z minor
```

Resume the existing Codex session — this preserves the reviewer's memory of prior findings and avoids cold-start overhead:

```bash
SESSION_ID=$(cat .peer-review/session-id)
cat .peer-review/prompt-N.md | codex exec resume "$SESSION_ID" - \
  --full-auto \
  -o .peer-review/round-N.md \
  --json > .peer-review/events-N.jsonl
```

Return to Step 4.

### Circuit Breaker

If round 6 (or `--max-rounds`) is reached and findings remain:

- Summarize what was addressed across all rounds
- List remaining unresolved findings as an **advisory** — these are informational, not blocking
- Do not ask for further action; the review cycle is complete

## Working Files

`.peer-review/` contains session artifacts:

| File | Purpose |
|------|---------|
| `prompt-N.md` | Prompt sent each round |
| `round-N.md` | Codex review output each round |
| `events-N.jsonl` | Raw JSONL events (contains session ID) |
| `session-id` | Thread ID for resume |

Inform the user these files exist for debugging. Do not delete them automatically:

```bash
rm -rf .peer-review/
```

## Constraints

- **Local only.** Do not call `gh`. This reviews local diffs, not PRs.
- **No criteria drift.** All review standards come from `pr-analysis`. This skill defines no review criteria of its own.
- **Fix scope.** Only address findings from the current review round. No drive-by improvements.
- **No false confidence.** Don't claim findings are resolved without the reviewer confirming via re-review.
- **Session reuse.** Always resume the existing Codex session for rounds 2+. Fresh sessions lose prior context and waste startup time — that's the whole point of resume.
