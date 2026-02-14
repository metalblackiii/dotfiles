---
description: Audit permission deny/allow/ask rules by checking for denials and calibration issues in recent sessions
allowed-tools: Bash, Read, Glob, Grep
---

Audit whether permission rules in settings.json are well-calibrated by checking for denials, workarounds, and gaps.

## Step 1: Read Current Permissions

```
Read ~/repos/dotfiles/claude/.claude/settings.json
```

Catalog all `allow`, `deny`, and `ask` rules.

## Step 2: Find Permission Denials in Transcripts

```
Grep with pattern="denied|not allowed|permission" path="~/.claude/projects" glob="*.jsonl" -i=true
```

For each match, extract the denied tool and command to understand what was blocked.

## Step 3: Check for Workaround Attempts

Look for evidence of denied tools being attempted via alternative commands. For example, if `Bash(grep *)` is denied, check if `Bash(rg *)` was used instead:

```
Grep with pattern="\"rg |\"sed |\"awk " path="~/.claude/projects" glob="*.jsonl"
```

This reveals gaps in deny rules — tools that should be blocked but aren't.

## Step 4: Analyze Ask Rule Friction

Check how often `ask` rules are triggered:

```
Grep with pattern="git commit|git push|gh pr create|gh pr merge" path="~/.claude/projects" glob="*.jsonl"
```

High frequency of ask-gated commands that are always approved may indicate the rule should move to `allow`. Commands that are sometimes denied should stay in `ask`.

## Output

```
## Permission Audit

### Current Rules
- Allow: X rules
- Deny: X rules
- Ask: X rules

### Denials Found
| Tool/Command | Occurrences | Notes |
|-------------|-------------|-------|
| ...         | ...         | ...   |

### Workaround Attempts
[Evidence of deny rules being circumvented via alternative commands]
(or "None found — deny rules appear comprehensive")

### Ask Rule Calibration
| Rule | Triggers | Always Approved? |
|------|----------|-----------------|
| ...  | ...      | ...             |

### Recommendations
1. [Most impactful finding]
```

## Notes

- Use `Glob` to find files and `Grep` to search content — `find`/`grep` are denied in Bash
- The most valuable finding is workaround attempts — these reveal deny rule gaps
- "Always approved" ask rules are candidates for promotion to allow (reduces friction)
- Keep output factual: numbers first, interpretation second

$ARGUMENTS
