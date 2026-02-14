---
description: Audit custom agent usage across recent sessions to find unused agents
allowed-tools: Bash, Read, Glob, Grep
---

Audit which custom agents are being spawned and which are dormant.

## Step 1: Discover Installed Agents

```
Glob with pattern="*.md" path="~/repos/dotfiles/claude/.claude/agents"
```

Read each agent file's frontmatter for name and description.

## Step 2: Find Transcripts With Task Tool Calls

```
Grep with pattern="\"name\":\"Task\"" path="~/.claude/projects" glob="*.jsonl"
```

Only run jq on files that matched.

## Step 3: Extract Agent Usage

For each matching transcript:

```bash
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Task") |
       .input.subagent_type' <file>
```

Filter to custom agent names only. Ignore built-in types: `Explore`, `Plan`, `Bash`, `general-purpose`, `statusline-setup`, `claude-code-guide`, `neb-explorer` (wait — that IS custom), etc. Cross-reference against installed agent file names to distinguish custom from built-in.

## Output

```
## Agent Audit

Sessions analyzed: X

### Usage

| Agent | Invocations | Sessions |
|-------|-------------|----------|
| ...   | ...         | ...      |

### Unused Agents
- agent-name: "description"

### Recommendations
1. [Most impactful finding]
```

## Notes

- Use `Glob` to find files and `Grep` to search content — `find`/`grep` are denied in Bash
- Custom agents are defined in `~/.claude/agents/`. Everything else is a built-in agent type.
- Unused agents may indicate the agent's description doesn't match how you phrase requests, or the workflow it supports hasn't come up
- Keep output factual: numbers first, interpretation second

$ARGUMENTS
