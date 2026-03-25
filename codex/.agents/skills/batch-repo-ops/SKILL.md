---
name: batch-repo-ops
description: ALWAYS invoke when performing any operation — change, check, audit, upgrade, or migration — across multiple repositories. Triggers on "update all neb-ms-* repos", "check X in every repo", "batch upgrade", "apply across services", "do this for every repo", "create PRs for all repos", "run this across all microservices", "what version of X in each repo", "check the status of Y across repos", or any request to repeat, check, or verify something across a set of repositories. Even simple read-only checks across repos benefit from structured discovery, batching, and reporting. Not for single-repo work.
---

# Batch Repo Ops

Orchestrate the same operation across multiple repositories using parallel sub-agents with rate limit guardrails, worktree isolation, batching, retry logic, and status tracking.

## When to Use

- Applying the same code change, config update, or migration across multiple repos
- Creating PRs across a set of repos (e.g., dependency upgrades, linter config changes)
- Running a command or check across multiple repos and collecting results
- Any "do X for every repo matching Y" request

## When NOT to Use

- Single-repo work — just do it directly
- Research across repos — use `co-research` with multi-repo survey
- Reviewing PRs across repos — use `pr-review-queue`

## Workflow

### Phase 1: DISCOVER

Identify the target repositories. Support two modes:

**Local discovery** — repos already cloned:
```bash
find ~/repos -maxdepth 1 -type d -name "neb-ms-*" 2>/dev/null
```

**Remote discovery** — via GitHub API:
```bash
gh repo list <org> --limit 200 --json nameWithOwner -q '.[].nameWithOwner' | grep '<pattern>'
```
The default `gh repo list` limit is 30 — always set `--limit` high enough to capture all matching repos. Always query `nameWithOwner` (not just `name`) — the sub-agent template requires the full `owner/repo` slug for `gh -R`.

If the user says "all neb-ms-*" or similar, try local first. Fall back to remote if local yields nothing. Always present the discovered list for confirmation.

If the user provides an explicit list (file path, inline list, or repos.md), use that directly.

**Validation (write operations only):**
1. **All repos must be cloned locally under `~/repos/`.** If any discovered repo is not cloned locally, fail immediately and list the missing repos so the user can clone them. Do not attempt to clone automatically — the user may have a reason for the repo not being local.
2. **All repo paths must be under `~/repos/`.** Repos outside this convention are rejected. This is a hard requirement for worktree path safety.

### Phase 2: PLAN

#### Operation classification

First, classify the operation as **read-only** or **write**:

| Type | Examples | Worktree |
|------|----------|----------|
| **Read-only** | Version checks, config audits, dependency listings, status queries | No — direct repo access |
| **Write** | Code changes, config edits, dependency upgrades, any commit/PR | Yes — worktree isolation |

**The rule is simple: if it writes, it gets a worktree. No exceptions.** Even "trivial" writes use worktrees — this avoids judgment calls and guarantees the user's working trees are never disturbed.

#### Weight classification

Then classify the operation weight to determine execution strategy:

| Weight | Characteristics | Strategy |
|--------|----------------|----------|
| **Light** | Single command or simple edit, templatable | Sequential Bash loop (read-only) or sequential Bash loop with worktrees (write) |
| **Medium** | Multi-step but templatable (edit file, install, test, commit) | Sequential sub-agents — one at a time, reuse the same prompt |
| **Heavy** | Complex changes requiring exploration, multi-file edits, test iteration | Batched parallel sub-agents — groups of 3 |

#### Approval gate

Present the plan to the user:

```
## Batch Operation Plan

**Operation:** [what will happen in each repo]
**Repos (N):** [list or summary]
**Type:** [Read-only / Write]
**Weight:** [Light / Medium / Heavy]
**Strategy:** [Sequential loop / Sequential sub-agents / Batched parallel (groups of 3)]
**Branch:** [branch name — required for write ops]
**Base:** [base-ref, default: main]
**Worktree base:** ~/repos/.batch-worktrees/<branch>/
**Estimated sub-agent prompt:** [show the prompt each sub-agent will receive]

Proceed? [y/n/edit]
```

Wait for explicit approval before continuing. If the user edits the plan, incorporate changes and re-present.

### Phase 3: EXECUTE

#### Stale worktree check (write operations only)

Before creating any worktrees, check for a stale batch directory:

```bash
BATCH_DIR=~/repos/.batch-worktrees/<branch>
if [ -d "$BATCH_DIR" ]; then
  echo "Stale batch worktree dir found: $BATCH_DIR"
  ls "$BATCH_DIR"
fi
```

If the directory exists, surface it to the user:
> Stale batch worktree dir found for branch `<branch>` with N repos. Remove and continue, or abort?

If the user says remove:
```bash
for wt in "$BATCH_DIR"/*/; do
  repo=$(git -C "$wt" rev-parse --git-dir 2>/dev/null | sed 's|/\.git/worktrees/.*||')
  if [ -n "$repo" ]; then
    git -C "$repo" worktree remove "$wt" 2>/dev/null \
      || echo "PRESERVED (dirty): $wt"
  fi
done
# Prune dangling references
for repo in <repo-list>; do
  git -C "$repo" worktree prune
done
# Only remove the batch dir if all worktrees were successfully removed
rmdir "$BATCH_DIR" 2>/dev/null \
  || echo "Batch dir not empty (dirty worktrees preserved): $BATCH_DIR"
```

**Never `rm -rf` the batch directory.** Use `rmdir` — it only succeeds if empty, which means all worktrees were cleanly removed. If any dirty worktrees were preserved by `git worktree remove` (which correctly refuses dirty worktrees), `rmdir` fails and the directory stays intact.

Never silently remove — it may be from a partial run the user wants to inspect.

#### Read-only operations

Run directly against the repos. No worktrees. Use absolute paths or subshells to avoid cwd drift.

```bash
for repo in <repo-list>; do
  (cd "$repo" && <command>)
done
```

WARNING: Never use `cd "$repo"` / `cd -` without a subshell — if `cd -` fails or the command changes cwd, subsequent iterations run in the wrong directory. The subshell `(cd ... && ...)` guarantees cwd resets.

For npm specifically, prefer `npm --prefix "$repo" <command>` over cd-based approaches.

Collect output per repo. Move to Phase 5.

#### Light write operations — Sequential Bash loop with worktrees

Create worktrees and operate in them. No sub-agents needed.

```bash
BATCH_DIR=~/repos/.batch-worktrees/<branch>
mkdir -p "$BATCH_DIR"

for repo in <repo-list>; do
  basename=$(basename "$repo")
  wt="$BATCH_DIR/$basename"
  git -C "$repo" fetch origin <base-ref>
  if ! git -C "$repo" worktree add "$wt" -b <branch> origin/<base-ref> 2>/dev/null; then
    # Branch already exists — check for unpushed commits before reusing
    git -C "$repo" worktree add "$wt" <branch> || { echo "SKIP $basename: worktree setup failed"; continue; }
    local_ahead=$(git -C "$wt" log origin/<base-ref>..HEAD --oneline 2>/dev/null | wc -l)
    if [ "$local_ahead" -gt 0 ]; then
      echo "SKIP $basename: branch <branch> has $local_ahead unpushed commit(s) — refusing to reset"
      git -C "$repo" worktree remove "$wt" 2>/dev/null
      continue
    fi
    git -C "$wt" reset --hard origin/<base-ref>
  fi
  # <command> should include git add + git commit if changes are made
  (cd "$wt" && <command>)
  # Only push if there are commits ahead of the base
  if (cd "$wt" && git log origin/<base-ref>..HEAD --oneline | grep -q .); then
    (cd "$wt" && git push -u origin <branch>) || echo "PUSH FAILED for $basename"
  fi
done
```

The first `worktree add` (with `-b`) is expected to fail when the branch already exists — its stderr is suppressed. The fallback `worktree add` (without `-b`) checks out the existing branch, then **checks for unpushed commits before resetting.** If the branch has local-only commits (from prior manual work or a partial run that didn't push), the repo is skipped to prevent data loss. Only branches with no unpushed commits are reset to `origin/<base-ref>`. If the fallback `worktree add` itself fails (e.g., worktree path already registered from a crash), the `|| continue` skips that repo and surfaces the error.

The push is conditional — only runs if there are commits ahead of the base. Push failures are surfaced (not swallowed) so the orchestrator can include them in the batch report.

Collect output per repo. Move to Phase 5.

#### Medium write operations — Sequential sub-agents with worktrees

The orchestrator creates the worktree, then spawns a sub-agent to operate in it. Wait for each to complete before starting the next.

```bash
BATCH_DIR=~/repos/.batch-worktrees/<branch>
mkdir -p "$BATCH_DIR"
```

For each repo:
1. Create the worktree:
   ```bash
   basename=$(basename "$repo")
   wt="$BATCH_DIR/$basename"
   git -C "$repo" fetch origin <base-ref>
   if ! git -C "$repo" worktree add "$wt" -b <branch> origin/<base-ref> 2>/dev/null; then
     git -C "$repo" worktree add "$wt" <branch> || { echo "SKIP $basename: worktree setup failed"; continue; }
     local_ahead=$(git -C "$wt" log origin/<base-ref>..HEAD --oneline 2>/dev/null | wc -l)
     if [ "$local_ahead" -gt 0 ]; then
       echo "SKIP $basename: branch has $local_ahead unpushed commit(s)"
       git -C "$repo" worktree remove "$wt" 2>/dev/null; continue
     fi
     git -C "$wt" reset --hard origin/<base-ref>
   fi
   ```
2. Spawn a sub-agent with the worktree path (see Sub-Agent Prompt Template)
3. Wait for completion
4. If the sub-agent used `gh` CLI commands heavily, add a 5-second pause before the next launch

**Sub-agent configuration (adapt to your platform):**

| Setting | Claude Code | Codex |
|---------|-------------|-------|
| Spawn | `Task` tool | `spawn_agent` |
| Wait | `TaskOutput` | `wait` |
| Type | `subagent_type: "general-purpose"` | `agent_type: "general-purpose"` |

- `model`: `"sonnet"` (default — sufficient for templatable work)
- Each sub-agent gets a self-contained prompt with: worktree path, source repo path, GitHub slug, operation spec, branch name, and success criteria

#### Heavy write operations — Batched parallel sub-agents with worktrees

Same worktree setup as Medium, but spawn sub-agents in batches of 3. Wait for the entire batch to complete before launching the next.

**Why 3?** Claude API concurrency limits and GitHub secondary rate limits (which throttle rapid successive API calls from the same token) make larger batches unreliable. 3 is the sweet spot — meaningful parallelism without triggering throttling.

**Sub-agent configuration:** Same platform table as Medium operations above.
- `model`: `"sonnet"` for standard work, `"opus"` only if the operation requires complex reasoning (e.g., non-trivial refactoring with judgment calls)
- Each sub-agent gets a self-contained prompt — no conversation context is available to sub-agents

**Batch loop:**
1. Take the next 3 repos from the queue
2. Create worktrees for all 3 (orchestrator does this, not the sub-agents)
3. Launch 3 sub-agents in parallel, each targeting its worktree
4. Wait for all 3 to complete
5. Record results per repo (success/failure/PR URL)
6. If any failed due to rate limits, move them to a retry queue
7. Pause 10 seconds between batches
8. Repeat until queue is empty

### Phase 4: RETRY

After all batches complete, process the retry queue:

1. Wait 30 seconds before first retry (rate limits need cooldown)
2. Retry failed repos one at a time (sequential — no more parallelism for retries)
3. Worktrees already exist from the initial attempt — **skip worktree setup entirely** if the worktree directory exists at the expected path. Do not re-run the `git worktree add` + `reset --hard` sequence, as that would wipe any commits from the first attempt. The sub-agent operates in the existing worktree as-is.
4. If a repo fails twice, mark it as failed and move on — don't burn context on a flaky operation
5. Record retry outcomes

### Phase 5: REPORT

Present a summary table:

```
## Batch Results: [operation description]

| Repo | Status | PR | Notes |
|------|--------|----|-------|
| neb-ms-billing | success | #142 | — |
| neb-ms-patients | success | #87 | — |
| neb-ms-auth | failed | — | npm test failed: timeout in auth.spec.js |
| neb-ms-scheduler | retry-success | #34 | Rate limited on first attempt |

**Summary:** N/M repos succeeded, K PRs created, F failures
**Worktree base:** ~/repos/.batch-worktrees/<branch>/

### Failed Repos (manual follow-up needed)
- neb-ms-auth: [error details]
  Worktree preserved: ~/repos/.batch-worktrees/<branch>/neb-ms-auth
```

If any repos failed, suggest next steps (manual fix, re-run with adjusted params, etc.).

### Phase 6: CLEANUP (write operations only)

After reporting, clean up worktrees as a batch sweep.

```bash
for wt in "$BATCH_DIR"/*/; do
  # Derive the source repo from the worktree's git metadata
  repo=$(git -C "$wt" rev-parse --git-dir 2>/dev/null | sed 's|/\.git/worktrees/.*||')
  [ -n "$repo" ] || continue
  dirty=$(git -C "$wt" status --porcelain)
  # If the branch has no upstream, the push never succeeded — treat as unpushed
  if git -C "$wt" rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
    unpushed=$(git -C "$wt" log @{upstream}..HEAD --oneline 2>/dev/null)
  else
    unpushed="no-upstream"
  fi
  if [ -n "$dirty" ]; then
    echo "Worktree preserved (uncommitted changes): $wt"
  elif [ -n "$unpushed" ]; then
    echo "Worktree preserved (unpushed commits): $wt"
  else
    git -C "$repo" worktree remove "$wt"
  fi
done
```

**After all worktrees are processed:**

```bash
# Prune stale worktree references in each source repo
for repo in <repo-list>; do
  git -C "$repo" worktree prune
done

# Remove the batch directory if empty
rmdir ~/repos/.batch-worktrees/<branch> 2>/dev/null
rmdir ~/repos/.batch-worktrees 2>/dev/null
```

If any worktrees were preserved, remind the user:
> N worktrees preserved (uncommitted changes or unpushed commits) under ~/repos/.batch-worktrees/<branch>/. Inspect and remove manually when done.

## Worktree Isolation

Write operations use worktree isolation to avoid disturbing the user's working trees. This guarantees the user can work in repos concurrently with a batch operation without conflicts.

**Worktree directory convention:**
```
~/repos/.batch-worktrees/<branch>/<repo-basename>/
```

Example for branch `mjb-pho-NEB-1234` across 3 repos:
```
~/repos/.batch-worktrees/mjb-pho-NEB-1234/neb-ms-billing/
~/repos/.batch-worktrees/mjb-pho-NEB-1234/neb-ms-patients/
~/repos/.batch-worktrees/mjb-pho-NEB-1234/neb-ms-auth/
```

**Key rules:**
- **Never touch the source repo's working tree.** Use `git -C <repo> fetch` and `git -C <repo> worktree add` — these don't affect HEAD or the index.
- **Push immediately after commit.** Once pushed, the remote branch is the durable record and the worktree becomes disposable. If push fails, preserve the worktree.
- **Branch reuse with safety check.** If the branch already exists, `git worktree add` without `-b` checks it out, then the orchestrator checks for unpushed commits. If the branch has local-only commits, the repo is **skipped** — never reset a branch with unpublished work. Only branches with no unpushed commits are reset to `origin/<base-ref>`. On retry, skip worktree setup entirely if the worktree directory already exists.
- **Orchestrator creates worktrees, not sub-agents.** The orchestrator sets up worktrees before dispatching sub-agents. Sub-agents only operate within their assigned worktree — they never run `git worktree add` or `git checkout` in the source repo.

## Branch Safety

Default base is `main` unless the user explicitly specifies a different base (e.g., a release branch). The `<base-ref>` placeholder appears throughout the skill — the orchestrator replaces it with the actual base branch name at execution time.

```bash
git -C "$repo" fetch origin <base-ref>
git -C "$repo" worktree add "$wt" -b <branch> origin/<base-ref>
```

This guarantees a clean base without touching the repo's HEAD. No `git checkout` needed — the source repo stays on whatever branch it's on.

**The approval gate must show the base.** Include `**Base:** [base-ref]` in the plan so the user can verify before execution begins.

**Branch naming for auto-allow:** If bash-permissions rules auto-allow git/gh operations on branches matching a pattern (e.g., `^mjb-pho-NEB-`), use that pattern for batch branch names. This avoids a user confirmation prompt for every commit/push/PR across N repos. Ask the user for the branch name prefix before starting — a batch of 20 repos hitting the `ask` layer 3 times each means 60 prompts.

## CWD Discipline

After a batch operation touches many repos, the orchestrator's working directory may be anywhere. All follow-up commands — especially `gh` — must be repo-explicit.

**Rules for post-batch commands:**
- For repo-scoped `gh` commands (`pr`, `issue`, `repo view`, `run`, etc.), always use `-R owner/repo` — never bare `gh pr view 123` (it resolves against cwd, which is likely the wrong repo)
- If the user asks about a specific PR by number, resolve the repo from context (batch results table, conversation history) and use `-R`
- If repo can't be determined, ask — don't guess from cwd
- After the batch report, consider resetting cwd to the user's original working directory or a neutral location

**This also applies to the user's follow-up questions.** After a batch op, if the user says "check PR 142" without specifying a repo, look at the batch results table to find which repo created PR #142 and use `-R` accordingly. PR numbers are only unique within a repo, not across repos.

## Sub-Agent Prompt Template

Each sub-agent prompt must be self-contained. Sub-agents don't inherit CLAUDE.md, so every safeguard must be spelled out in the prompt.

**Write operations template** (with worktree):

```
You are operating in a worktree for: [owner/repo]
Worktree path: [worktree path]
Source repo path: [repo path] (DO NOT modify — used only for git references)
GitHub repo slug: [owner/repo]

## Task
[Operation description — what to do]

## Steps
1. cd [worktree path] && [Step 1 — the actual work]
2. cd [worktree path] && [Step N]
...
N. cd [worktree path] && git add <specific-files> && git commit -m "<message>"
N+1. cd [worktree path] && git push -u origin [branch-name]
N+2. gh pr create -R [owner/repo] --title "<title>" --body "<body>" -r Chiropractic-CT-Cloud/phoenix

IMPORTANT: Every step must start with `cd [worktree path] &&` because cwd does not persist between tool calls.

## Branch
Branch: [branch-name] (already checked out in the worktree — do not create or switch branches)
Base: origin/[base-ref]

## Jira Integration
If a Jira ticket number is detectable from the branch name (pattern: NEB-\d+):
- Include `https://practicetek.atlassian.net/browse/<ticket>` in the PR body
- After PR creation, comment on the Jira ticket with the PR URL using markdown link syntax: `[PR #N](url)`

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

## Constraints
- Do not modify files outside the scope of this task
- Work ONLY in the worktree path — never cd to or modify the source repo
- Every shell command must begin with `cd [worktree path] &&` — cwd does not persist between tool calls
- For npm commands, use `cd [worktree path] && npm ...` or `npm --prefix [worktree path] ...`
- Run tests after changes: [test command]
- If tests fail, attempt to fix up to 2 times before reporting failure
- Push immediately after committing — the remote branch is the durable record
- For repo-scoped `gh` commands (`pr`, `issue`, `run`, etc.), use the repo slug: `gh ... -R [owner/repo]` — do not rely on cwd for repo resolution

## On Completion
Report back with:
- Files changed (list)
- Test results (pass/fail)
- Push status (success/fail)
- PR URL (if created)
- Any issues encountered
```

**Read-only operations template:**

```
You are reading from the repository at: [repo path]
GitHub repo slug: [owner/repo]

## Task
[Operation description — what to check/read]

## Steps
1. cd [repo path] && [Step 1]
...

IMPORTANT: Every step must start with `cd [repo path] &&` because cwd does not persist between tool calls.

## Constraints
- READ ONLY — do not modify any files, create branches, or commit
- Every shell command must begin with `cd [repo path] &&`
- For repo-scoped `gh` commands, use: `gh ... -R [owner/repo]`

## On Completion
Report back with:
- [What was found/checked]
- Any issues encountered
```

The orchestrator must fill in `[repo path]`, `[worktree path]` (write ops), and `[owner/repo]` (GitHub slug, e.g., `Chiropractic-CT-Cloud/neb-ms-billing`) before dispatching each sub-agent. Resolve slugs during Phase 1 (DISCOVER) using `gh repo view --json nameWithOwner -q .nameWithOwner` in each repo, or derive from the `gh repo list` output if using remote discovery.

## Rate Limit Guidance

| Resource | Limit | Mitigation |
|----------|-------|------------|
| GitHub API (authenticated) | 5000 req/hr | Rarely hit with batch ops — monitor if doing 50+ repos |
| GitHub secondary rate limits | ~30 req/min for mutating calls | 5s pause between `gh pr create` calls; batch size of 3 |
| Claude API concurrency | Model-dependent | Batch size of 3 for parallel sub-agents; sequential for medium ops |
| npm registry | Varies | Rarely an issue; retry on 429s |

If a sub-agent reports a rate limit error (HTTP 429, "secondary rate limit", "API rate limit exceeded"):
1. Do not retry immediately
2. Wait at least 30 seconds
3. Retry sequentially (not in parallel)
4. If it fails again, stop and report — the user may need to wait or adjust timing

## Context Management

Batch operations consume significant context. Monitor and act:

- **10+ repos with heavy operations**: Consider running `handoff` after Phase 6 to preserve results for a follow-up session
- **Sub-agent failures generating long error output**: Summarize errors rather than including full output in the tracking table
- **Mid-batch context pressure**: Complete the current batch, write results to a file (`batch-results.md`), then run `handoff`

## Red Flags — STOP

- About to launch more than 3 parallel sub-agents — reduce batch size
- No user approval for the plan — never skip the approval gate
- Sub-agent prompt references conversation context — prompts must be self-contained
- Same repo failing repeatedly — stop after 2 attempts, don't burn context
- Rate limit errors on consecutive batches — pause and reassess with the user
- Sub-agent running `git checkout` or `git worktree add` in a source repo — only the orchestrator manages worktrees
