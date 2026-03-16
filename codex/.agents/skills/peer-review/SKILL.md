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

### Step 0: Clean Slate

If `.peer-review/` exists from a previous run, ask the user before removing it. Stale `session-id`, `scope-files`, or `round-N.md` files will corrupt the new run, but the user may want to inspect prior results first. If the user confirms, `rm -rf .peer-review`.

### Step 1: Verify Changes and Record Scope

Determine the **diff scope** from user input. Default: `git diff --staged`, falling back to `git diff` if staged is empty. Branch-mode scopes use range syntax (`main...HEAD`, `<ref1>..<ref2>`).

Create `.peer-review/` (`mkdir -p .peer-review`), then check that changes exist and record the file list:

```bash
rtk proxy git diff --staged --name-only --no-color   # if rtk is installed
git diff --staged --name-only --no-color              # otherwise (Codex, CI, etc.)
```

When rtk is installed, its Claude Code hook rewrites `git` commands to add compact formatting. Use `rtk proxy` to bypass the filtering and get raw output (see RTK.md). In environments without rtk (Codex, CI), plain `git` already produces raw output. Adjust diff arguments for the requested scope.

In working-tree mode (default), also collect untracked files via `git ls-files --others --exclude-standard`, excluding `.peer-review/`.

If both are empty, report "No changes to review" and stop.

Save the combined file list to `.peer-review/scope-files` (one path per line). This is the source of truth for which files the review covers — re-review diffs in rounds 2+ are scoped to these files so unrelated local changes don't leak in.

Display: `Peer review: [M files] ([scope description])`

### Step 2: Build the Review Prompt

Use the platform-native file-creation tool to create `.peer-review/prompt-1.md`. Do not use bash redirects — they may be blocked by shell hooks.

The prompt tells Codex to invoke the `self-review` skill, which already handles diff capture, pr-analysis criteria, defensive audit, naming scan, and severity-formatted output. The prompt only needs to specify the scope and add the exhaustive single-pass requirement:

```
Run $self-review [scope].

Report ALL findings in a single pass. Do not hold back issues for later rounds —
each round costs real time and compute. Check every edge case, every assumption,
every interaction between changes before concluding.
```

Replace `[scope]` with the user's requested scope (e.g., `staged`, `main...HEAD`). That's the entire prompt — self-review handles everything else including the `FINDINGS:` summary line.

### Step 3: Dispatch to Codex

```bash
cat .peer-review/prompt-1.md | codex exec - \
  --full-auto \
  -o .peer-review/round-1.md \
  --json > .peer-review/events-1.jsonl
```

**Extract the session ID.** Read `.peer-review/events-1.jsonl` using the platform-native file-read capability and find the `thread_id` from the first `thread.started` event. Do not use `python3 -c` or other shell-based JSON parsing — it may be blocked by hooks.

Save the thread ID to `.peer-review/session-id` using the platform-native file-write capability.

**Verify round output.** Codex `-o` may write a brief summary rather than the full review. Read `.peer-review/round-1.md` — if it lacks the `FINDINGS:` summary line or is suspiciously short (under 1KB), the actual review is in the events JSONL. Search the events file for the review content (look for the `FINDINGS:` line in message events) and rewrite `round-1.md` with the full review.

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

**Expand the file scope.** If you edited or created any files not already in `.peer-review/scope-files`, append those paths now. Only add files you actually touched during this fix — do not scan `git diff HEAD --name-only`, as that would pull in unrelated local changes. The scope grows monotonically — files are never removed.

If a finding is unclear or requires a design decision, ask the user before proceeding.

### Step 6: Re-Review via Resume

Recapture the diff for re-review, **scoped to the tracked file list.** Read `.peer-review/scope-files` and pass the paths as pathspecs:

```bash
rtk proxy git diff HEAD --no-color -U3 -- file1 file2 file3   # if rtk is installed
git diff HEAD --no-color -U3 -- file1 file2 file3              # otherwise
```

This ensures unrelated local changes don't leak into the re-review. Both working-tree and branch modes use `git diff HEAD` here — the original range (e.g., `main...HEAD`) wouldn't include uncommitted fixes.

Use `rtk proxy` when rtk is installed (see Step 1 note). Plain `git` works in environments without rtk.

For untracked files, filter `git ls-files --others --exclude-standard` to only paths in `scope-files`.

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
| `scope-files` | File paths in review scope (grows monotonically) |

Inform the user these files exist for debugging. Do not delete them automatically:

```bash
rm -rf .peer-review/
```

## Platform Compatibility

Shell hooks (Claude Code) or sandbox rules (Codex) may block common patterns:

| Blocked pattern | Use instead |
|----------------|-------------|
| `cat > file`, `echo ... > file`, heredocs | Platform-native file-write capability |
| `python3 -c "..."`, `node -e "..."` | Platform-native file-read + in-context parsing |
| `git diff` (raw output needed) | `rtk proxy git diff` if rtk installed, plain `git diff` otherwise |

When a command is blocked, do not retry — switch to the platform-native equivalent.

## Constraints

- **Local only.** Do not call `gh`. This reviews local diffs, not PRs.
- **No criteria drift.** All review standards come from `pr-analysis`. This skill defines no review criteria of its own.
- **Fix scope.** Only address findings from the current review round. No drive-by improvements.
- **No false confidence.** Don't claim findings are resolved without the reviewer confirming via re-review.
- **Session reuse.** Always resume the existing Codex session for rounds 2+. Fresh sessions lose prior context and waste startup time — that's the whole point of resume.
