---
name: one-shot
description: >-
  Automated pipeline from requirements to PR in a single run — worktree setup,
  implementation, peer review, commit, PR creation, and CI fix loop. Accepts a PRD file or prose description.
  Not for creating PRDs (use create-prd) or multi-repo implementation.
  Manual invocation only; not invoked directly by the model.
argument-hint: "<prd-path or prose description>"
disable-model-invocation: true
---

# One-Shot

Automated pipeline from requirements to PR. Creates a worktree, implements the feature, runs peer review with fix cycles, commits, creates a PR with review findings, monitors CI and fixes failures, and cleans up.

Accepts two input types:
- **PRD file** — structured, with extractable metadata (branch, verification commands, repo scope)
- **Prose description** — freeform feature request, with metadata prompted or inferred

## When to Use

- You have requirements (PRD or prose) and want to implement them end-to-end
- Single-repo features only — reject any multi-repo request

## Pipeline

```
PARSE → VALIDATE → WORKTREE → IMPLEMENT → VERIFY → COMMIT → PEER-REVIEW → PR → CI WATCH → CLEANUP
```

## Step 0: Parse & Validate

### Detect input type

If the argument is a path to an existing `.md` file containing PRD frontmatter (`> Status:` or `> Branch:`), treat as **PRD mode**. Otherwise, treat as **prose mode**.

### PRD mode

Read the PRD file. **Hold the full content in memory** — the PRD may not exist in the worktree (it could be uncommitted or on another branch).

- **Branch**: Extract from `> Branch: [branch-name]`. If missing, prompt the user.
- **Repo validation**: Parse the `## Repositories` table. Count repos with code-change roles (`Primary implementation` or `Potential update`). If more than one:
  > This PRD spans multiple repositories. Stop and tell the user one-shot only supports single-repo work.

  Stop.
- **Verification commands**: Extract from `## Verification`. Hold for Step 3.
- **Jira ticket**: Extract from the branch name if present (pattern: `NEB-\d+`). Hold for Step 6.

### Prose mode

Hold the prose description in memory.

- **Branch**: Always prompt the user. Do not guess or generate one.
- **Repo validation**: Assume cwd repo is the target (single-repo by definition).
- **Verification commands**: Discovered in Step 3 from the project (`package.json` scripts, `Makefile`, CI config, etc.).
- **Jira ticket**: Extract from the branch name if present (pattern: `NEB-\d+`). Hold for Step 6.

## Step 1: Worktree Setup

```bash
ORIGINAL_DIR=$(pwd)
git fetch origin main
git worktree add ../<branch> -b <branch> origin/main
cd ../<branch>
```

The worktree is a sibling directory named after the branch. If `../<branch>` already exists (stale worktree from a prior run):

1. Check for uncommitted work:
   ```bash
   git -C ../<branch> status --porcelain
   ```
2. If the worktree is **clean** (no output), remove and recreate:
   ```bash
   git worktree remove ../<branch>
   ```
3. If the worktree is **dirty** (has changes), **stop**:
   > Worktree `../<branch>` exists with uncommitted changes. Clean it up manually or provide a different branch name.

Never force-remove a dirty worktree — it may contain in-progress work from a prior run.

Display: `Worktree created: ../<branch>`

## Step 2: Implement

**PRD mode**: Implement all requirements from the PRD, following:
- **Codebase Context** — respect existing patterns and conventions
- **Constraints** — follow the chosen approach and guardrails
- **Functional Requirements** — implement each FR
- **Non-Functional Requirements** — respect security, performance, compliance constraints

**Prose mode**: Explore the codebase to understand conventions, then implement the described feature. Follow existing patterns. When the prose is ambiguous, make reasonable choices and document them in the commit message.

Work methodically. This is the core implementation phase — take as many steps as needed.

## Step 3: Verify (Best Effort)

**PRD mode**: Run each verification command from the PRD's `## Verification` section.

**Prose mode**: Run the project's standard verification commands (discovered during worktree setup — e.g., `npm test`, `npm run build`, `npm run lint`, `make test`, etc.).

If a command fails:
1. Read the error output
2. Attempt to fix the root cause
3. Re-run the failing command
4. If it still fails after two attempts, note the failure and move on

Do not hard-stop on verification failures. The peer-review cycle is the quality gate.

## Step 4: Commit

Stage and commit changes using conventional commit style.

- **Single logical change:** One commit.
- **Multiple distinct changes:** Multiple commits (e.g., separate data model from API from UI).

```bash
git add <specific-files>
git commit -m "feat(<scope>): <description>"
```

## Step 5: Peer Review

Invoke the `peer-review` skill with branch scope:

```
$peer-review main...HEAD
```

This runs the full multi-round cycle: isolated reviewer evaluates the diff, you fix findings, reviewer re-reviews — until approved or circuit breaker (round 6).

**After peer-review completes** (before cleanup is offered), capture the results:

1. List all round files:
   ```bash
   ls .peer-review/round-*.md | sort -V
   ```
2. Read **every** round file — extract the `FINDINGS:` line from each. This builds the per-round history for the PR body.
3. Note the total round count and final verdict (APPROVED or circuit breaker).

**When peer-review asks about `.peer-review/` cleanup:** Confirm removal — findings are already captured.

## Step 6: Create PR

Push the branch and create the PR. **Verify the repo** before running `gh` (per repo policy):

```bash
git push -u origin <branch>
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

**Build the PR body** using this structure:

```markdown
## Summary
<PRD mode: Condensed Problem & Outcome from PRD>
<Prose mode: What was requested and what was built>

<If Jira ticket: https://practicetek.atlassian.net/browse/<ticket>>

## Changes
<What was implemented, organized by FR if PRD mode>

## Peer Review
- **Rounds:** <N>
- **Final verdict:** APPROVED | Advisory (circuit breaker, round N)
<For each round that had findings, one bullet summarizing what was fixed:>
- **Round <N>:** <concise summary of changes made to address findings>
<Omit rounds with no findings. If only 1 round and clean, omit the per-round list entirely.>

<If circuit breaker: list remaining unresolved findings>

## Verification
<Which commands passed, which had issues>

## Test Plan
<PRD mode: checklist from Acceptance Criteria>
<Prose mode: checklist of what to verify manually>
- [ ] <criterion>
```

Create the PR:

```bash
PR_URL=$(gh pr create -R "$REPO" \
  --title "<type>(<scope>): <concise title>" \
  --body "$(cat <<'EOF'
<assembled PR body>
EOF
)")
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
```

Hold `PR_URL` and `PR_NUMBER` for Step 7 and Step 8.

**Jira integration.** If a ticket number was extracted in Step 0, comment on the Jira ticket with the PR URL after PR creation.

## Step 7: CI Watch

Monitor CI checks on the PR. Fix failures and push until green, or exhaust the attempt budget.

### Poll

Wait 5 minutes, then check:

```bash
gh pr checks $PR_NUMBER -R "$REPO"
```

If any checks are still `pending` or `queued`, wait another 5 minutes and re-check. Repeat until all checks reach a terminal state (pass, fail, neutral, skipped, cancelled). If checks remain non-terminal after **60 minutes** of polling, comment on the PR noting the stall and proceed to cleanup — something is stuck.

### On All Green

Proceed to Step 8 (Cleanup).

### On Failure

1. Identify the failing check(s). Get the run ID from the checks output, then fetch logs:
   ```bash
   gh run view <run-id> -R "$REPO" --log-failed
   ```
2. Read the error output. Triage the failure:
   - **Code issue** (build error, test failure, lint violation) — fix the root cause in the worktree
   - **Infra flake** (timeout, runner unavailable, transient network error) — re-run the workflow via `gh run rerun <run-id> -R "$REPO" --failed` (counts as one attempt)
   - **Environment issue** (missing secret, permissions, external service down) — not fixable from code; skip to circuit breaker
3. Fix the issue in the worktree — this may touch files beyond those changed in Step 2.
4. Commit and push:
   ```bash
   git add <files>
   git commit -m "fix(<scope>): <what was fixed for CI>"
   git push
   ```
5. Return to **Poll** and wait for the new run.

### Circuit Breaker

After **5 fix attempts**, stop. Report remaining CI failures in a PR comment:

```bash
gh pr comment $PR_NUMBER -R "$REPO" --body "CI still failing after 5 fix attempts: <summary of remaining failures>"
```

Proceed to Step 8 (Cleanup).

## Step 8: Cleanup

Return to the original repository and remove the worktree:

```bash
cd $ORIGINAL_DIR
git worktree remove ../<branch>
```

Display:

```
Done.
$PR_URL
Worktree removed: ../<branch>
```

If `git worktree remove` fails (uncommitted changes, lock), display the error and leave the worktree for manual cleanup.

## Constraints

- **Single-repo only.** Reject PRDs with multiple code-change repos. Prose is single-repo by definition.
- **Zero checkpoints.** The pipeline runs unattended. The PR is the human gate. This intentionally overrides the default commit/push approval policy — requesting one-shot implementation (whether via `/one-shot` or natural language) is the user's approval to commit, push, and create a PR.
- **No scope creep.** Implement what was requested — no extras, no drive-by cleanup.
- **Worktree isolation.** All work happens in the worktree. The original repo stays on main.
- **Capture before cleanup.** Read peer-review findings before removing `.peer-review/` or the worktree.
- **Green CI.** The PR should have passing CI before the pipeline is done. CI watch runs after PR creation and fixes failures up to the attempt budget. CI fix commits are not peer-reviewed — they are small targeted fixes (lint, types, missing imports) where the feedback loop is CI itself.

## Failure Modes

| Failure | Action |
|---------|--------|
| No branch name provided | Prompt user — do not guess |
| Multi-repo PRD | Reject — one-shot only supports single-repo work |
| Worktree exists and is clean | Remove and recreate |
| Worktree exists with uncommitted changes | Stop — tell user to clean up manually |
| Verification fails after 2 attempts | Note failure, continue to peer review |
| Peer review circuit breaker | Include advisory findings in PR body |
| `git push` fails | Display error, leave worktree for diagnosis |
| `gh pr create` fails | Display error, branch is pushed for manual PR |
| CI checks fail after 5 fix attempts | Comment remaining failures on PR, proceed to cleanup |
| CI checks stuck pending for 60+ minutes | Skip to circuit breaker |
