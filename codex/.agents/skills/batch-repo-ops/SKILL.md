---
name: batch-repo-ops
description: ALWAYS invoke when performing any operation — change, check, audit, upgrade, or migration — across multiple repositories. Triggers on "update all neb-ms-* repos", "check X in every repo", "batch upgrade", "apply across services", "do this for every repo", "create PRs for all repos", "run this across all microservices", "what version of X in each repo", "check the status of Y across repos", or any request to repeat, check, or verify something across a set of repositories. Even simple read-only checks across repos benefit from structured discovery, batching, and reporting. Not for single-repo work.
---

# Batch Repo Ops

Orchestrate the same operation across multiple repositories using parallel sub-agents with rate limit guardrails, batching, retry logic, and status tracking.

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

### Phase 2: PLAN

Classify the operation weight to determine execution strategy:

| Weight | Characteristics | Strategy |
|--------|----------------|----------|
| **Light** | Single command, no branching, read-only or trivial write | Sequential Bash loop — no sub-agents needed |
| **Medium** | Multi-step but templatable (edit file, install, test, commit) | Sequential sub-agents — one at a time, reuse the same prompt |
| **Heavy** | Complex changes requiring exploration, multi-file edits, test iteration | Batched parallel sub-agents — groups of 3 |

Present the plan to the user:

```
## Batch Operation Plan

**Operation:** [what will happen in each repo]
**Repos (N):** [list or summary]
**Weight:** [Light / Medium / Heavy]
**Strategy:** [Sequential loop / Sequential sub-agents / Batched parallel (groups of 3)]
**Branch:** [branch name if creating commits]
**Estimated sub-agent prompt:** [show the prompt each sub-agent will receive]

Proceed? [y/n/edit]
```

Wait for explicit approval before continuing. If the user edits the plan, incorporate changes and re-present.

### Phase 3: EXECUTE

#### Light operations — Sequential Bash loop

Run directly in a loop. No sub-agents needed. Use absolute paths or subshells to avoid cwd drift.

```bash
for repo in <repo-list>; do
  (cd "$repo" && <command>)
done
```

WARNING: Never use `cd "$repo"` / `cd -` without a subshell — if `cd -` fails or the command changes cwd, subsequent iterations run in the wrong directory. The subshell `(cd ... && ...)` guarantees cwd resets.

For npm specifically, prefer `npm --prefix "$repo" <command>` over cd-based approaches.

Collect output per repo. Move to Phase 5.

#### Medium operations — Sequential sub-agents

Spawn one sub-agent per repo, sequentially. Wait for each to complete before starting the next. This avoids rate limits entirely while keeping operations isolated.

**Sub-agent configuration (adapt to your platform):**

| Setting | Claude Code | Codex |
|---------|-------------|-------|
| Spawn | `Task` tool | `spawn_agent` |
| Wait | `TaskOutput` | `wait` |
| Type | `subagent_type: "general-purpose"` | `agent_type: "general-purpose"` |

- `model`: `"sonnet"` (default — sufficient for templatable work)
- Each sub-agent gets a self-contained prompt with: repo path, operation spec, branch name, and success criteria

**Between sub-agents:** No artificial delay needed since sequential execution naturally avoids rate limits. However, if a sub-agent uses `gh` CLI commands heavily (creating PRs, posting comments), add a 5-second pause before the next launch to respect GitHub's secondary rate limits.

#### Heavy operations — Batched parallel sub-agents

Spawn sub-agents in batches of 3. Wait for the entire batch to complete before launching the next.

**Why 3?** Claude API concurrency limits and GitHub secondary rate limits (which throttle rapid successive API calls from the same token) make larger batches unreliable. 3 is the sweet spot — meaningful parallelism without triggering throttling.

**Sub-agent configuration:** Same platform table as Medium operations above.
- `model`: `"sonnet"` for standard work, `"opus"` only if the operation requires complex reasoning (e.g., non-trivial refactoring with judgment calls)
- Each sub-agent gets a self-contained prompt — no conversation context is available to sub-agents

**Batch loop:**
1. Take the next 3 repos from the queue
2. Launch 3 sub-agents in parallel
3. Wait for all 3 to complete
4. Record results per repo (success/failure/PR URL)
5. If any failed due to rate limits, move them to a retry queue
6. Pause 10 seconds between batches
7. Repeat until queue is empty

### Phase 4: RETRY

After all batches complete, process the retry queue:

1. Wait 30 seconds before first retry (rate limits need cooldown)
2. Retry failed repos one at a time (sequential — no more parallelism for retries)
3. If a repo fails twice, mark it as failed and move on — don't burn context on a flaky operation
4. Record retry outcomes

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

### Failed Repos (manual follow-up needed)
- neb-ms-auth: [error details]
```

If any repos failed, suggest next steps (manual fix, re-run with adjusted params, etc.).

## Branch Safety

Always branch from `main` unless the user explicitly specifies a different base. Before creating a branch in each repo, verify the current base:

```bash
git checkout main && git pull origin main
```

Sub-agents that branch from a stale or wrong base (e.g., an existing feature branch) can silently inherit unrelated changes and cause cascading test failures across the batch.

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

Template:

```
You are operating on the repository at: [repo path]
GitHub repo slug: [owner/repo]

## Task
[Operation description — what to do]

## Steps
1. cd [repo path] && git checkout main && git pull origin main
2. cd [repo path] && git checkout -b [branch-name]
3. cd [repo path] && [Step N — the actual work]
...

IMPORTANT: Every step must start with `cd [repo path] &&` because cwd does not persist between tool calls.

## Branch
Create branch: [branch-name]
Base: always main. The `cd && git checkout main && git pull` in step 1 ensures this. Never branch from whatever HEAD happens to be — it may be a stale feature branch with unrelated changes.

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

## Constraints
- Do not modify files outside the scope of this task
- Every shell command must begin with `cd [repo path] &&` — cwd does not persist between tool calls
- For npm commands, use `cd [repo path] && npm ...` or `npm --prefix [repo path] ...`
- Run tests after changes: [test command]
- If tests fail, attempt to fix up to 2 times before reporting failure
- For repo-scoped `gh` commands (`pr`, `issue`, `run`, etc.), use the repo slug: `gh ... -R [owner/repo]` — do not rely on cwd for repo resolution

## On Completion
Report back with:
- Files changed (list)
- Test results (pass/fail)
- PR URL (if created)
- Any issues encountered
```

The orchestrator must fill in both `[repo path]` (local filesystem path) and `[owner/repo]` (GitHub slug, e.g., `Chiropractic-CT-Cloud/neb-ms-billing`) before dispatching each sub-agent. Resolve slugs during Phase 1 (DISCOVER) using `gh repo view --json nameWithOwner -q .nameWithOwner` in each repo, or derive from the `gh repo list` output if using remote discovery.

Adapt the template based on the operation. Light operations don't need all sections.

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

- **10+ repos with heavy operations**: Consider running `handoff` after Phase 5 to preserve results for a follow-up session
- **Sub-agent failures generating long error output**: Summarize errors rather than including full output in the tracking table
- **Mid-batch context pressure**: Complete the current batch, write results to a file (`batch-results.md`), then run `handoff`

## Red Flags — STOP

- About to launch more than 3 parallel sub-agents — reduce batch size
- No user approval for the plan — never skip the approval gate
- Sub-agent prompt references conversation context — prompts must be self-contained
- Same repo failing repeatedly — stop after 2 attempts, don't burn context
- Rate limit errors on consecutive batches — pause and reassess with the user
