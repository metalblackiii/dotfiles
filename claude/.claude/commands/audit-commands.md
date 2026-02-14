---
description: Audit slash command usage across recent sessions to find unused commands
allowed-tools: Bash, Read, Glob, Grep
---

Audit which slash commands are being used and which are dormant.

## Step 1: Discover Installed Commands

```
Glob with pattern="*.md" path="~/repos/dotfiles/claude/.claude/commands"
```

Read each command file's frontmatter for description.

## Step 2: Find Transcripts With Skill Tool Calls

Commands and skills both invoke via the Skill tool:

```
Grep with pattern="\"name\":\"Skill\"" path="~/.claude/projects" glob="*.jsonl"
```

Only run jq on files that matched.

## Step 3: Extract Command Usage

For each matching transcript:

```bash
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Skill") |
       .input.skill' <file>
```

Cross-reference results against installed command names (exclude skills — those are auto-invoked, not slash commands).

## Output

```
## Command Audit

Sessions analyzed: X

### Usage

| Command | Invocations |
|---------|-------------|
| ...     | ...         |

### Unused Commands
- command-name: "description"

### Recommendations
1. [Most impactful finding]
```

## Notes

- Use `Glob` to find files and `Grep` to search content — `find`/`grep` are denied in Bash
- Unused commands may indicate poor discoverability or a workflow gap
- Keep output factual: numbers first, interpretation second

$ARGUMENTS
