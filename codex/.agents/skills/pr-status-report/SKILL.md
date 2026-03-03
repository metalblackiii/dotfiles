---
name: pr-status-report
description: Use when you need a consolidated status dashboard for your open GitHub pull requests across repositories, with active action buckets (needs action, waiting, ready, stale) plus a separate draft follow-up list.
allowed-tools: Bash, Read, Glob, Grep
---

# PR Status Report

Generate a single report for your open PR queue so you can triage quickly.

Draft PRs are intentionally excluded from active status buckets and listed in a separate "Draft Follow-up" section.

## When to Use

- You have many open PRs and need a prioritized queue
- You want one status view across repositories, not repo-by-repo checks
- You need clear next actions (fix checks, address feedback, ping reviewers, merge)

## Inputs

- Optional `author` (default: `@me`)
- Optional `owner` filter (for org-scoped reporting)
- Optional `repo` filter (one or more specific repositories)
- Optional `limit` (default: `100`)
- Optional `stale-days` threshold (default: `7`)
- Optional free-form `search` qualifier additions

## Workflow

1. Validate prerequisites:
   - `gh` is installed and authenticated
   - `jq` is installed
2. Run the helper script:
   - Codex runtime path: `~/.agents/skills/personal/pr-status-report/scripts/pr-status-report.sh`
   - Claude runtime path: `~/.claude/skills/pr-status-report/scripts/pr-status-report.sh`
3. Present the markdown report exactly, then add a short triage summary:
   - Count by bucket (active buckets plus draft follow-up)
   - Top 3 highest-priority actions
4. If requested, rerun with tighter filters (owner/repo/search/stale threshold).

## Commands

```bash
# Resolve script path (Codex first, Claude fallback)
SCRIPT_PATH="$HOME/.agents/skills/personal/pr-status-report/scripts/pr-status-report.sh"
[[ -x "$SCRIPT_PATH" ]] || SCRIPT_PATH="$HOME/.claude/skills/pr-status-report/scripts/pr-status-report.sh"

# Default dashboard for your open PRs
bash "$SCRIPT_PATH"

# Org-scoped
bash "$SCRIPT_PATH" --owner Chiropractic-CT-Cloud

# Include custom search qualifiers and stricter stale threshold
bash "$SCRIPT_PATH" \
  --search "label:needs-review" \
  --stale-days 5

# JSON output (for follow-up automation)
bash "$SCRIPT_PATH" --json
```

## Failure Policy

- If `gh` auth fails, stop and ask the user to run `gh auth login`.
- If API calls fail for specific PRs, keep going and report partial results.
- Never invent CI/review states; if unavailable, show `UNKNOWN`.
