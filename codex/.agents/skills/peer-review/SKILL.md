---
name: peer-review
description: >-
  ALWAYS invoke for multi-round code review using an isolated reviewer.
  Runs implement-review-fix cycles until the reviewer approves or circuit breaker trips.
  Triggers on peer review, codex review my changes, review cycle, iterative review.
  Not for single-pass local review (use self-review) or GitHub PR review (use review).
argument-hint: "[diff-command] [--max-rounds N]"
---

# Peer Review

Multi-round review cycle with enforced context isolation. You implement, an isolated reviewer with zero implementation context reviews, you fix, the same reviewer re-reviews — repeat until approved or the circuit breaker trips.

## Why This Works

The implementer is blind to their own assumptions. A separate reviewer with zero implementation context catches what familiarity bias hides. Context isolation is the mechanism — the reviewer never sees implementation history, only the diff. Session continuity across rounds lets the reviewer remember prior findings without cold-start overhead.

## Input

- **Diff scope** (optional): `git diff --staged`, `git diff main...HEAD`, etc. Default: `git diff --staged`, falling back to `git diff` if staged is empty.
- **`--max-rounds N`** (optional): Circuit breaker. Default: 6.

## Workflow

### Transport Detection

Before starting the review cycle, determine the **orchestrator** and select a **review transport**. The transport is the mechanism for dispatching prompts to an isolated reviewer and receiving results.

| Transport | Dispatch | Resume |
|-----------|----------|--------|
| `codex-exec` | `codex exec` subprocess | `codex exec resume $ID` |
| `native-subagent` | Spawn named agent | Send input to same agent |

**Step 1: Identify the active orchestrator.**

Determine which runtime is executing this skill right now — Claude Code or Codex. This is not capability detection; you already know what you are.

**Step 2: Select transport by orchestrator preference.**

| Orchestrator | Transport | Rationale |
|-------------|-----------|-----------|
| **Codex** | `native-subagent` | Codex cannot exec itself. Never attempt `codex exec` from Codex. |
| **Claude Code** (Codex CLI available) | `codex-exec` | Reviewer runs on Codex's token budget — cheaper than an orchestrator-side sub-agent. |
| **Claude Code** (no Codex CLI) | `native-subagent` | Fallback to Agent tool when Codex CLI is not installed. |

For Claude Code, test Codex CLI availability with `command -v codex`.

**Step 3: Hold values in memory.**

Do not write metadata yet — `.peer-review/` does not exist until Step 1 creates it, and Step 0 may delete a stale directory first. Carry the orchestrator and transport values forward; they are persisted in Step 1 after directory creation.

All subsequent dispatch steps branch on `transport`.

### Step 0: Clean Slate

If `.peer-review/` exists from a previous run, ask the user before removing it. Stale session state or round artifacts will corrupt the new run, but the user may want to inspect prior results first. If the user confirms, `rm -rf .peer-review`.

### Step 1: Verify Changes and Record Scope

Determine the **diff scope** from user input. Default: `git diff --staged`, falling back to `git diff` if staged is empty. Branch-mode scopes use range syntax (`main...HEAD`, `<ref1>..<ref2>`).

Create `.peer-review/` (`mkdir -p .peer-review`), then check that changes exist and record the file list:

```bash
rtk proxy git diff --staged --name-only --no-color   # if rtk is installed
git diff --staged --name-only --no-color              # otherwise (Codex, CI, etc.)
```

When rtk is installed, its Claude Code hook rewrites `git` commands to add compact formatting. Use `rtk proxy` to bypass the filtering and get raw output (see RTK.md). In environments without rtk (Codex, CI), plain `git` already produces raw output. Adjust diff arguments for the requested scope.

In working-tree mode (default fallback), also collect untracked files via `git ls-files --others --exclude-standard`, excluding `.peer-review/`.

If both are empty, report "No changes to review" and stop.

Save the combined file list to `.peer-review/scope-files` (one path per line). This is the source of truth for which files the review covers — re-review diffs in rounds 2+ are scoped to these files so unrelated local changes don't leak in.

**Record scope mode.** Write one of `staged`, `working-tree`, or `branch` to `.peer-review/scope-mode`. This determines how diffs are captured throughout the cycle and whether fixes must be re-staged (see Step 5).

**Persist transport metadata.** Now that `.peer-review/` exists, write the values determined in Transport Detection:
- `.peer-review/orchestrator` — `claude-code` or `codex`
- `.peer-review/transport` — `codex-exec` or `native-subagent`

Display: `Peer review: [M files] ([scope description]) | transport: [transport] | scope: [scope-mode]`

### Step 2: Build the Review Prompt

Use the platform-native file-creation tool to create `.peer-review/prompt-1.md`. Do not use bash redirects — they may be blocked by shell hooks.

The prompt must be **transport-agnostic**. Do not assume the reviewer can invoke `$self-review` directly — some isolated reviewer transports have no skill attachment or skill invocation support even when the parent session does. The prompt should prefer skill invocation when available, then fall back to reading the installed skill from the runtime skill roots.

Create this prompt:

```
Review the requested local changes for [scope].

If skill invocation is available, run:
$self-review [scope]

Otherwise, bootstrap from the installed skill files:
1. Check `~/.agents/skills/personal/self-review/SKILL.md`
2. If not found, check `~/.claude/skills/self-review/SKILL.md`
3. Read whichever exists and follow it exactly
4. When that workflow references sibling skills (for example `../pr-analysis/SKILL.md`), resolve them relative to the loaded skill file's directory

Review exhaustively in a single pass; do not defer findings to later rounds.
```

Replace `[scope]` with the user's requested scope (e.g., `staged`, `main...HEAD`). This keeps reviewer bootstrapping portable across Claude Code, Codex, and transports that only expose filesystem access. `self-review` still owns the review workflow and `FINDINGS:` summary format.

### Step 3: Dispatch to Reviewer

Read `.peer-review/transport` and branch.

#### Transport: `codex-exec`

```bash
cat .peer-review/prompt-1.md | codex exec - \
  --full-auto \
  -o .peer-review/round-1.md \
  --json > .peer-review/events-1.jsonl
```

**Dispatch-time downgrade.** If `codex exec` fails (non-zero exit, empty JSONL, or subprocess errors), downgrade is allowed **only if no reviewer session was established** — check whether a `thread.started` event exists in `.peer-review/events-1.jsonl`. If it does, a reviewer session exists and the transport is locked; surface the error to the user. If no `thread.started` event exists, downgrade:

1. Remove partial artifacts from the failed attempt: `events-1.jsonl`, `round-1.md` (if created).
2. Update `.peer-review/transport` to `native-subagent`.
3. Proceed with the `native-subagent` path below.

**Extract the reviewer ID.** Read `.peer-review/events-1.jsonl` using the platform-native file-read capability and find the `thread_id` from the first `thread.started` event. Do not use `python3 -c` or other shell-based JSON parsing — it may be blocked by hooks.

Save the thread ID to `.peer-review/reviewer-id`.

**Verify round output.** Codex `-o` may write a brief summary rather than the full review. Read `.peer-review/round-1.md` — if it lacks the `FINDINGS:` summary line or is suspiciously short (under 1KB), the actual review is in the events JSONL. Search the events file for the review content (look for the `FINDINGS:` line in message events) and rewrite `round-1.md` with the full review.

#### Transport: `native-subagent`

Spawn a named agent (name: `Reviewer`) with the contents of `.peer-review/prompt-1.md` as the task prompt. The agent must have zero implementation context — do not fork or share the current conversation.

Wait for the agent to complete. Write the agent's response to `.peer-review/round-1.md`.

Save the agent's ID to `.peer-review/reviewer-id`.

### Step 4: Apply Verdict Logic

Read `.peer-review/round-N.md`. Parse the `FINDINGS:` summary line for severity counts.

Apply progressive verdict thresholds:

| Rounds | APPROVED when | Rationale |
|--------|--------------|-----------|
| 1-3 | No findings at any severity | Early rounds: chase a clean review |
| 4-6 | No Critical or Important | Late rounds: minor-only findings are diminishing returns |

**APPROVED:** Display the review summary, note the round count. Proceed to Cleanup.

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

**Maintain index integrity.** When `scope-mode` is `staged`, re-stage all files listed in `.peer-review/scope-files` plus any new files touched during this fix round. This keeps the index current with the worktree so the reviewer always evaluates exactly what will be committed. Skip re-staging for `working-tree` and `branch` scope modes — those review the worktree, not the index.

**Stage untracked files flagged by the reviewer.** If a finding flags an untracked file that code depends on, `git add` it now — staging is the fix, not a deferred concern.

Display a brief summary of which findings you addressed and how.

**Expand the file scope.** If you edited or created any files not already in `.peer-review/scope-files`, append those paths now. Only add files you actually touched during this fix — do not scan `git diff HEAD --name-only`, as that would pull in unrelated local changes. The scope grows monotonically — files are never removed.

If a finding is unclear or requires a design decision, ask the user before proceeding.

### Step 6: Re-Review via Resume

Recapture the diff for re-review, **scoped to the tracked file list.** Read `.peer-review/scope-files` and pass the paths as pathspecs. The diff command depends on scope-mode:

| Scope mode | Diff command | Why |
|-----------|-------------|-----|
| `staged` | `git diff --staged --no-color -U3 -- <files>` | Reviews exactly what will be committed (fixes were re-staged in Step 5) |
| `working-tree` | `git diff HEAD --no-color -U3 -- <files>` | Reviews all uncommitted changes against HEAD |
| `branch` | `git diff HEAD --no-color -U3 -- <files>` | Original range wouldn't include uncommitted fixes |

Prefix with `rtk proxy` when rtk is installed (see Step 1 note). Plain `git` works in environments without rtk.

For untracked files, filter `git ls-files --others --exclude-standard` to only paths in `scope-files`.

Write the re-review prompt to `.peer-review/prompt-N.md`. **Prompts are self-contained** — include the full diff and context every round. Session memory should help, not be required.

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

Read `.peer-review/transport` and branch.

#### Transport: `codex-exec`

Resume the existing session — this preserves the reviewer's memory of prior findings:

```bash
REVIEWER_ID=$(cat .peer-review/reviewer-id)
cat .peer-review/prompt-N.md | codex exec resume "$REVIEWER_ID" - \
  --full-auto \
  -o .peer-review/round-N.md \
  --json > .peer-review/events-N.jsonl
```

Verify round output as in Step 3.

#### Transport: `native-subagent`

Send the contents of `.peer-review/prompt-N.md` as input to the existing reviewer agent (read agent ID from `.peer-review/reviewer-id`). Wait for the response and write it to `.peer-review/round-N.md`.

Return to Step 4.

### Circuit Breaker

If round 6 (or `--max-rounds`) is reached and findings remain:

- Summarize what was addressed across all rounds
- List remaining unresolved findings as an **advisory** — these are informational, not blocking
- Do not ask for further action; the review cycle is complete
- Proceed to Cleanup

### Cleanup

After the review cycle completes (APPROVED or circuit breaker), offer to remove `.peer-review/`:

> Review complete. Remove `.peer-review/` working directory? (y/n)

If the user confirms, `rm -rf .peer-review`. If declined, leave it in place — the user may want to reference results. Either way, the review is done.

## Working Files

`.peer-review/` contains session artifacts:

| File | Purpose |
|------|---------|
| `orchestrator` | Active runtime: `claude-code` or `codex` |
| `transport` | Review transport: `codex-exec` or `native-subagent` |
| `reviewer-id` | Thread ID (`codex-exec`) or agent ID (`native-subagent`) for resume |
| `scope-mode` | `staged`, `working-tree`, or `branch` — controls diff capture and re-staging |
| `scope-files` | File paths in review scope (grows monotonically) |
| `prompt-N.md` | Prompt sent each round |
| `round-N.md` | Reviewer output each round |
| `events-N.jsonl` | Raw JSONL events (`codex-exec` transport only) |

These files exist for debugging. Cleanup is offered at the end of each run (see Cleanup step).

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
- **Session reuse.** Always resume the existing reviewer for rounds 2+. Fresh sessions lose prior context and waste startup time — that's the whole point of resume.
- **Index integrity.** When scope-mode is `staged`, every re-review evaluates the staged payload, not the worktree. Re-stage after every fix round.
