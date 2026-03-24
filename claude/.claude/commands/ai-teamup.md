---
command: ai-teamup
description: Implement a PRD using Agent Teams — parallel specialists with peer messaging and quality gates. Claude Code only.
argument-hint: <path-to-prd.md>
---

# AI Teamup

Implement a PRD using Claude Code Agent Teams. Creates a small team of specialists that decompose, implement, and review in parallel with worktree isolation.

**When to use:** Medium-complexity PRDs (4-8 files, cross-cutting, well-specced) where one-shot risks context rot but loop setup is overkill. Also excellent for multi-repo features where each repo is a natural implementer boundary. The `prd-triage` skill can help decide.

**Not for:** Small changes (one-shot is faster), convergence problems (loop is better), or Codex-only users (Agent Teams is Claude Code only).

## Prerequisites

- Agent Teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json
- A PRD file (from `create-prd` or manually written) with phases, acceptance criteria, and file scope

## Step 1 — Read and Validate the PRD

Read `$ARGUMENTS` as a path to a PRD file. If no path provided, look for `PRD.md` or `*.prd.md` in the current directory.

Validate the PRD has:
- [ ] Clear phases or task decomposition
- [ ] Acceptance criteria per phase
- [ ] File scope (which files/modules are affected)

If the PRD is missing file scope or task decomposition, suggest: "This PRD needs clearer task boundaries for team decomposition. Consider running `requirements-analyst` to identify gaps, or `create-prd` to rebuild it."

## Step 2 — Decompose into Tasks

Analyze the PRD and decompose into **non-overlapping tasks** suitable for parallel execution. The critical constraint: **no two tasks may modify the same file.**

### Multi-repo features

If the PRD spans multiple repositories, decompose by repo — each implementer owns an entire repo's changes. This is the strongest possible ownership boundary (zero file overlap by construction). Each implementer's dispatch message must include the repo path and any cross-repo contract (e.g., "the API endpoint you're adding in neb-ms-billing will be consumed by neb-www with this request shape: ...").

For each task, identify:
- **Task ID** (short slug)
- **Description** (what to implement)
- **Repo** (if multi-repo; omit for single-repo PRDs)
- **Files to modify** (explicit list — this is the ownership boundary)
- **Dependencies** (which tasks must complete first, if any)
- **Acceptance criteria** (from the PRD, scoped to this task)

Present the decomposition as a table:

```
| Task | Repo (if multi) | Description | Files | Depends On | AC |
|------|-----------------|-------------|-------|------------|-----|
```

Ask: "Does this decomposition look right? Any file ownership conflicts to resolve?"

Wait for confirmation.

## Step 3 — Mongoose Gate (Challenge the Decomposition)

Before spending tokens on a team, actively try to disprove the decomposition. This is a premise-check, not a rubber stamp.

Ask yourself these questions and report findings:

1. **File ownership conflicts:** Can task A truly avoid touching task B's files? Trace the imports — if task A changes a type that task B's files consume, that's a hidden dependency.
2. **Shared state:** Do any tasks touch shared state (database schemas, config files, shared types/interfaces, route definitions)? If yes, those files must be owned by exactly one task, with other tasks depending on it.
3. **Integration surface:** After all tasks merge, will the pieces actually fit together? Identify the integration points and who owns them. For multi-repo: define the cross-repo contract explicitly (API shape, event schema, shared types) — each implementer must build to the same contract.
4. **Simpler alternative:** Could this actually be done as a one-shot with handoff? If the tasks are sequential (A must finish before B starts), parallelism buys nothing — use one-shot.

**Decision:**
- If the decomposition survives the challenge → proceed to Step 4
- If hidden overlaps are found → revise the decomposition (merge conflicting tasks, reassign files) and re-present the table
- If the whole approach is wrong → recommend one-shot with handoff or loop instead, explain why, and stop

## Step 4 — Create the Team

### Team sizing

- **2-4 tasks with no dependencies:** 1 implementer per task + 1 reviewer = 3-5 teammates
- **5+ tasks or dependencies:** Group related tasks, max 4 implementers + 1 reviewer = 5 teammates
- **Never exceed 5 teammates** (coordination overhead exceeds parallel benefit)

### Teammate roles

| Role | Count | Model | Responsibility |
|------|-------|-------|----------------|
| **Lead** (you) | 1 | Opus | Decompose, dispatch, merge, open PR |
| **Implementer** | 1-4 | Sonnet | Own a task, implement in worktree, signal completion |
| **Reviewer** | 1 | Sonnet | Review completed tasks against AC |

### Create the team

```
TeamCreate(name: "teamup-<short-prd-name>")
```

### Dispatch implementers

For each task, send a message to a teammate. Each message MUST include:

1. The task description and acceptance criteria
2. The explicit file list (ownership boundary)
3. Instruction to work in an isolated worktree
4. Instruction to signal completion when done
5. The PRD context relevant to this task (not the full PRD — just the relevant phase)

Example dispatch:

```
SendMessage(
  recipient: "implementer-1",
  content: """
  ## Task: <task-id>

  <task description>

  ### Files you own (do not modify files outside this list):
  - src/components/foo.ts
  - src/components/foo.test.ts

  ### Acceptance criteria:
  - [ ] <criterion 1>
  - [ ] <criterion 2>

  ### Context from PRD:
  <relevant excerpt>

  Work in your own git worktree. Run tests for your files before signaling completion.
  Do NOT modify files outside your ownership list.

  **If context compaction occurs:** Re-read this message to recover your task assignment,
  file ownership list, and acceptance criteria. These are your operating instructions —
  do not proceed from memory alone after compaction.
  """,
  summary: "Task <task-id>: <one-line description>"
)
```

### Dispatch reviewer

```
SendMessage(
  recipient: "reviewer",
  content: """
  You are the code reviewer for this team. As implementers complete tasks, review their changes:

  1. Read the diff (git diff main...<branch>)
  2. Check against acceptance criteria
  3. Check for: correctness, test coverage, style consistency, no out-of-scope changes
  4. If issues found: message the implementer directly with specific feedback
  5. If approved: message the lead (me) that task <id> passed review

  PRD for reference:
  <full PRD content>

  Task ownership map:
  <task → file mapping table>

  **If context compaction occurs:** Re-read this message to recover the PRD, task ownership
  map, and your review responsibilities. Do not proceed from memory alone after compaction.
  """,
  summary: "Reviewer: review completed tasks against PRD acceptance criteria"
)
```

## Step 5 — Monitor and Gate

While teammates work:

1. **Monitor idle summaries** — check for stuck agents, permission prompts, or circular work
2. **Track task completion** — maintain a checklist of tasks and their review status
3. **Intervene if needed** — see escalation protocol below

### Completion checklist

```
- [ ] Task 1: implemented ☐ reviewed ☐
- [ ] Task 2: implemented ☐ reviewed ☐
- [ ] Task N: implemented ☐ reviewed ☐
```

### Escalation protocol

| Rejection Count | Action |
|-----------------|--------|
| **1st reject** | Implementer fixes based on reviewer feedback. Normal flow. |
| **2nd reject** | Lead reads the diff and reviewer comments. Sends implementer a targeted message with specific guidance on what's wrong and how to fix it. |
| **3rd reject** | Abort the task. Lead reassigns to a different implementer with clearer instructions and the reviewer's feedback inlined. If no implementers are available, ask the user to intervene. |

Other escalations:
- **Teammate goes silent for 3+ minutes** → check for permission prompts, then ping
- **Implementer reports file conflict** → resolve ownership, redirect
- **Implementer scope creeps** → reviewer catches in review; lead messages to stop and revert out-of-scope changes

Do not proceed to Step 6 until ALL tasks are implemented AND reviewed.

## Step 6 — Merge and Validate

Once all tasks pass review:

1. **Merge worktree branches** into a single branch
   - If merge conflicts arise, resolve them (the file ownership decomposition should prevent most conflicts)
   - If conflicts are non-trivial, ask the relevant implementer to resolve

2. **Run the full test suite** on the merged branch
   - If tests fail, identify which task's changes caused the failure
   - Message that implementer with the failure details

3. **Run linting/type checking** on the merged branch

4. **Verify acceptance criteria** — walk through each PRD acceptance criterion and confirm it's met

## Step 7 — Deliver

1. **Open PR(s)** using `gh pr create`. After worktree and team operations, always verify the target repo (per AGENTS.md git rules):
   - **Single-repo:** Verify with `gh repo view --json nameWithOwner -q .nameWithOwner`, then create one PR with title from the PRD.
   - **Multi-repo:** One PR per repo, using `-R owner/repo`. Title: `<PRD title> (<repo-name>)`. Cross-link PRs in each body ("Related: <other PR URLs>").
   - Body summarizing: what was implemented, task decomposition, team size, any deviations from the PRD
   - Link to Jira ticket if detectable from branch name or PRD content
   - Default reviewers per AGENTS.md conventions

2. **Clean up:**
   - Remove worktree branches that were merged
   - Delete the team: the team will be cleaned up when the session ends, but note the team name for manual cleanup if the session crashes

3. **Report to user:**
   ```
   ## Teamup Summary

   **PRD:** <name>
   **Team size:** <N> teammates
   **Tasks:** <N> completed, <N> reviewed
   **PR:** <URL>
   **Deviations:** <any changes from the original PRD plan>
   ```

## Step 8 — Post-Mortem (Knowledge Accumulation)

After delivery, capture what the team learned. This feeds back into future triage decisions and decomposition quality.

Record the following in the PR body (under a `## Post-Mortem` section) and in the Waypoint journal:

1. **Decomposition accuracy** — Did the file ownership boundaries hold? Were there unexpected overlaps discovered during implementation or merge?
2. **Strategy validation** — Was Agent Teams the right call? Would one-shot or loop have been better in hindsight?
3. **Token cost** — Approximate total token spend (team size x session length). Was the parallelism worth the cost?
4. **Patterns discovered** — Any reusable decomposition patterns for similar PRDs? Any modules that are hard to split?
5. **Escalations** — How many reviewer rejections? Any tasks that needed lead intervention?

```bash
waypoint journal add --section learnings "<prd-name>: <key takeaway from this teamup run>"
```

If the Mongoose gate caught a bad decomposition (Step 3 revised the plan), log that too — it's a signal the triage or PRD was under-specified.

## Failure Modes and Mitigations

| Failure | Mitigation |
|---------|------------|
| Teammate edits files outside ownership | Reviewer catches in review; lead reassigns |
| Merge conflicts between worktrees | File ownership decomposition should prevent; resolve manually if needed |
| Teammate stuck on permission prompt | Check idle summaries; ping after 3 min; restart if needed |
| Orphan team from crashed session | Next session: `ls ~/.claude/teams/` and clean up before creating new team |
| PRD too large for one team session | Split into multiple teamup runs, one per PRD phase |
| Task dependencies create sequential bottleneck | Group dependent tasks into one implementer's scope |
| Reviewer rejects same task 3+ times | Escalation protocol: reassign to different implementer or escalate to user |
| Mongoose gate reveals bad decomposition | Revise or abort before burning team tokens |

## Context Compaction Recovery

Long team runs will trigger context compaction for the lead. When compaction occurs:

1. Re-read the PRD file to recover full acceptance criteria
2. Re-check the completion checklist — query each teammate's status rather than relying on pre-compaction memory
3. Re-derive the task ownership map from the original decomposition

Include this instruction in the lead's own operating loop: after any compaction event, treat the next turn as a fresh status check — don't assume pre-compaction state is accurate.

## Constraints

- **Never exceed 5 teammates** — diminishing returns beyond this
- **File ownership is sacred** — no two implementers touch the same file
- **The lead (you) never writes code** — only coordinates, merges, and opens PR
- **PRD is the spec** — deviations from the PRD must be flagged in the summary, not silently introduced
- **Worktree isolation is mandatory** — no implementer works in the base checkout
- **Mongoose gate is not optional** — challenge every decomposition before creating the team

## Reference: Agent Teams Internals

For messaging architecture, inbox paths, delivery timing, and debugging stuck teams:

@references/agent-teams-internals.md
