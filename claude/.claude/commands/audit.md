---
description: Audit usage patterns across all Claude Code customizations (skills, agents, commands, hooks, settings)
allowed-tools: Bash, Read, Glob, Grep
---

Analyze usage patterns across all Claude Code customizations by parsing recent session transcripts.

## Step 1: Discover Installed Artifacts

Enumerate everything installed. Use the dotfiles source of truth:

```
Skills:   ~/repos/dotfiles/claude/.claude/skills/*/SKILL.md
Agents:   ~/repos/dotfiles/claude/.claude/agents/*.md
Commands: ~/repos/dotfiles/claude/.claude/commands/*.md
Rules:    ~/repos/dotfiles/claude/.claude/rules/*.md
Hooks:    ~/repos/dotfiles/claude/.claude/settings.json → hooks section
Settings: ~/repos/dotfiles/claude/.claude/settings.json → permissions
```

Read each artifact's description/frontmatter so you can cross-reference later.

## Step 2: Find Session Transcripts

Use Glob to find recent transcripts:
```
Glob with pattern="**/*.jsonl" path="~/.claude/projects"
```

Filter to files modified in the last 7 days by checking modification times. Count total sessions and which projects they belong to.

## Step 3: Parse Usage Data

For each transcript file found, use jq via Bash to extract data:

### Skills & Commands (both use Skill tool)
```bash
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Skill") |
       .input.skill' <file>
```
Skills and slash commands both invoke via the Skill tool. Cross-reference against installed skills and commands to categorize each invocation.

### Custom Agents
```bash
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Task") |
       .input.subagent_type' <file>
```
Filter to only custom agent types (from `~/.claude/agents/`), not built-in types like `Explore`, `Plan`, `Bash`, etc.

### Hook Effectiveness
Use Grep to search for the SessionStart hook fingerprint across transcripts:
```
Grep with pattern="specialized skills installed" path="~/.claude/projects" glob="*.jsonl"
```
Count sessions where the hook fired vs total sessions.

### Permission Denials
Use Grep to search for evidence of denied tool calls:
```
Grep with pattern="denied|not allowed|permission" path="~/.claude/projects" glob="*.jsonl" -i=true
```

## Step 4: Output

Present findings in this format:

```
## Audit Summary (Last 7 Days)

Sessions analyzed: X across Y projects
Installed: X skills, Y agents, Z commands, W rules

---

## Skill Usage

| Skill | Invocations | Sessions | Notes |
|-------|-------------|----------|-------|
| ...   | ...         | ...      | ...   |

Never used: [list with descriptions]
Missed opportunities: [sessions where a skill clearly applied but wasn't invoked]

## Agent Usage

| Agent | Invocations | Sessions |
|-------|-------------|----------|
| ...   | ...         | ...      |

Never used: [list]
Note: Only tracks custom agents, not built-in (Explore, Plan, etc.)

## Command Usage

| Command | Invocations |
|---------|-------------|
| ...     | ...         |

Never used: [list]

## Hook Effectiveness

SessionStart hook fired: X/Y sessions (Z%)
[Flag if hook is not firing consistently]

## Permission Denials

[List any denied actions found in transcripts]
[If none: "No permission denials found — settings appear well-calibrated"]

## Installed vs Used (Cross-Reference)

### Active (used in last 7 days)
- [artifact]: X invocations

### Dormant (installed but unused)
- [artifact]: "[description]" — consider if still needed

### Candidates for Retirement
[Artifacts dormant for multiple audit cycles]

## Recommendations

Prioritized list:
1. [Most impactful finding]
2. ...
```

## Notes

- Use `jq` via Bash for JSONL parsing — it handles the format natively
- Use `Glob` to find files (not `find`) and `Grep` to search content (not `grep`) — these are denied in Bash
- Sessions with 0 skill invocations despite task-relevant skills are the most interesting finding
- When identifying "missed opportunities", look at what tools/actions were taken and match against skill trigger descriptions
- Keep the output factual — numbers first, interpretation second

$ARGUMENTS
