---
description: Restore context after /clear, /compact, or a long break
---

# Context Catchup

Restore context after `/clear`, `/compact`, or a long break. Rebuild understanding of recent work and project state.

## Process

### 1. Git State

Run these as separate parallel Bash calls (no chaining or subshells — keeps permissions clean):

- `git branch --show-current`
- `git status --short`
- `git log --oneline -10`

### 2. Recent Changes

Run these as separate parallel Bash calls:

- `git diff --stat HEAD~5`
- `git diff --name-only`
- `git diff --cached --name-only`
- `git log --name-only --pretty=format: HEAD~5..HEAD` (for TODO scan file list)

### 3. TODO Scan

Use the **Grep** tool (not bash grep) to scan recently modified files for outstanding work markers:

```
Grep pattern="TODO|FIXME|XXX|HACK" across files from git diff --name-only HEAD~5
```

### 4. Project Detection

Read `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, or equivalent to identify the project. Check for CLAUDE.md and .claude/ configuration.

## Output Format

```markdown
## Context Restored

**Project**: [name and type]
**Branch**: [current branch]
**Last commit**: [relative time and message]

### Recent Work (Last 5 Commits)
1. [commit message] — [files affected]
2. ...

### Uncommitted Changes
- [modified files with brief description of changes]
- (or "Working tree clean")

### Outstanding TODOs
- `file:line` — [marker and description]
- (or "None found in recently modified files")

### Suggested Next Steps
Based on recent activity:
1. [Most likely next action]
2. [Alternative focus area]
```

If `$ARGUMENTS` contains a keyword, filter the output to changes related to that area.

$ARGUMENTS