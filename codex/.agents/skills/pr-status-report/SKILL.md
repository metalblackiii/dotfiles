---
name: pr-status-report
description: ALWAYS invoke for a status overview of your open pull requests. Triggers on "my PR status", "open PRs", "what PRs am I waiting on", or "PR dashboard".
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
2. Run the helper script with `--compact` flag — this produces a one-line-per-PR list that renders cleanly in the terminal (no markdown tables that get bloated by the renderer):
   - Codex runtime path: `~/.agents/skills/personal/pr-status-report/scripts/pr-status-report.sh`
   - Claude runtime path: `~/.claude/skills/pr-status-report/scripts/pr-status-report.sh`
3. **Echo the compact output VERBATIM in your text response — do not rewrite, summarize, or reformat it.** The script output contains markdown links (`[repo#N](url)`) that must be preserved exactly so they render as clickable links. If you paraphrase or restructure the output, the links break. Copy-paste the entire script output character-for-character, then add your triage summary after it.
4. After the compact report, add a short triage summary:
   - Count by bucket (active buckets plus draft follow-up)
   - Top 3 highest-priority actions
   - **Link format:** Always reference PRs as `owner/repo#number` (e.g., `Chiropractic-CT-Cloud/neb-ms-registry#140`), never bare `#number` — bare numbers resolve to the wrong repo in markdown contexts.
5. If requested, rerun with tighter filters (owner/repo/search/stale threshold).

## Commands

```bash
# Resolve script path (Codex first, Claude fallback)
SCRIPT_PATH="$HOME/.agents/skills/personal/pr-status-report/scripts/pr-status-report.sh"
[[ -x "$SCRIPT_PATH" ]] || SCRIPT_PATH="$HOME/.claude/skills/pr-status-report/scripts/pr-status-report.sh"

# Default: compact one-line-per-PR (use for text response)
bash "$SCRIPT_PATH" --compact

# Full markdown tables (stays in tool result for reference)
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
