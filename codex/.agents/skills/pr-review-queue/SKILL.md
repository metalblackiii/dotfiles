---
name: pr-review-queue
description: ALWAYS invoke to see what PRs need your review. Triggers on "review queue", "what needs my review", "pending reviews", or "PRs I'm a reviewer on".
allowed-tools: Bash, Read, Glob, Grep
---

# PR Review Queue

Generate a single report for PRs you need to review or are actively reviewing, so you can triage your review workload.

Draft PRs are excluded from active buckets and listed separately.

## When to Use

- You have pending review requests across multiple repositories
- You want one view of your reviewer obligations, not repo-by-repo checks
- You need clear next actions (review, re-review, follow up, unsubscribe)

## Inputs

- Optional `reviewer` (default: `@me`)
- Optional `owner` filter (for org-scoped reporting)
- Optional `repo` filter (one or more specific repositories)
- Optional `limit` (default: `100`)
- Optional `stale-days` threshold (default: `7`)
- Optional free-form `search` qualifier (passed as positional arg to `gh search prs`)

## Workflow

1. Validate prerequisites:
   - `gh` is installed and authenticated
   - `jq` is installed
2. Run the helper script:
   - Codex runtime path: `~/.agents/skills/personal/pr-review-queue/scripts/pr-review-queue.sh`
   - Claude runtime path: `~/.claude/skills/pr-review-queue/scripts/pr-review-queue.sh`
3. Present the markdown report exactly, then add a short triage summary:
   - Count by bucket (active buckets plus draft/watching)
   - Top 3 highest-priority actions
4. If requested, rerun with tighter filters (owner/repo/search/stale threshold).

## Commands

```bash
# Resolve script path (Codex first, Claude fallback)
SCRIPT_PATH="$HOME/.agents/skills/personal/pr-review-queue/scripts/pr-review-queue.sh"
[[ -x "$SCRIPT_PATH" ]] || SCRIPT_PATH="$HOME/.claude/skills/pr-review-queue/scripts/pr-review-queue.sh"

# Default dashboard for PRs you're reviewing
bash "$SCRIPT_PATH"

# Org-scoped
bash "$SCRIPT_PATH" --owner Chiropractic-CT-Cloud

# Stricter stale threshold
bash "$SCRIPT_PATH" --stale-days 5

# JSON output (for follow-up automation)
bash "$SCRIPT_PATH" --json
```

## Failure Policy

- If `gh` auth fails, stop and ask the user to run `gh auth login`.
- If API calls fail for specific PRs, keep going and report partial results.
- Never invent CI/review states; if unavailable, show `UNKNOWN`.
