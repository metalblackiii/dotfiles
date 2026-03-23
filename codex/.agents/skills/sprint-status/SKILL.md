---
name: sprint-status
description: ALWAYS invoke for a status overview of your current Jira sprint. Triggers on "sprint status", "my sprint", "what's in the sprint", "jira dashboard", "sprint board", or "how's my sprint looking".
allowed-tools: Bash, Read
---

# Sprint Status

Generate a triage-ready report for your current sprint: grouped status list first, then analysis.

## When to Use

- You want a quick view of your sprint workload
- You need to prioritize what to work on next
- You want to see what's close to Done vs stuck in backlog

## Inputs

- Optional `--include-done` flag to show completed items (hidden by default)

## Workflow

1. Validate `ptjira` and `jq` are on PATH
2. Run the helper script:
   - Codex: `~/.agents/skills/personal/sprint-status/scripts/sprint-status.sh`
   - Claude Code: `~/.claude/skills/sprint-status/scripts/sprint-status.sh`
3. **Echo the script output VERBATIM** — do not reformat or summarize the status list. Copy it character-for-character so ticket keys and alignment are preserved.
4. After the status list, add a **Triage** section with your own analysis:
   - Count by status category
   - Items closest to Done (PR, In Testing) — nudge to finish
   - Largest clusters in backlog — bulk opportunities or deferral candidates
   - Any items that look stale or blocked based on status
   - Top 3 recommended next actions
   - **Link format:** `[NEB-1234](https://practicetek.atlassian.net/browse/NEB-1234)`

## Commands

```bash
# Resolve script path
SCRIPT_PATH="$HOME/.agents/skills/personal/sprint-status/scripts/sprint-status.sh"
[[ -x "$SCRIPT_PATH" ]] || SCRIPT_PATH="$HOME/.claude/skills/sprint-status/scripts/sprint-status.sh"

# Default: hide Done items
bash "$SCRIPT_PATH"

# Include completed items
bash "$SCRIPT_PATH" --include-done
```

## Failure Policy

- If `ptjira` auth fails, stop and tell the user to check `~/.config/ptjira/config.toml`
- If the search returns zero results, say so — don't fabricate data
