---
description: Audit skill usage across recent sessions to find dormant skills and adoption gaps
allowed-tools: Bash, Read, Glob, Grep
---

Audit which skills are being invoked, which are dormant, and whether the SessionStart hook is driving adoption.

## Step 1: Discover Installed Skills

```
Glob with pattern="*/SKILL.md" path="~/repos/dotfiles/claude/.claude/skills"
```

Read each SKILL.md frontmatter for name and description.

## Step 2: Find Transcripts With Skill Invocations

Pre-filter to avoid parsing large files unnecessarily:

```
Grep with pattern="\"name\":\"Skill\"" path="~/.claude/projects" glob="*.jsonl"
```

Only run jq on files that matched.

## Step 3: Extract Skill Usage

For each matching transcript:

```bash
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Skill") |
       .input.skill' <file>
```

Cross-reference results against installed skills (exclude commands — those are slash commands, not skills).

## Step 4: Check Hook Effectiveness

```
Grep with pattern="specialized skills installed" path="~/.claude/projects" glob="*.jsonl"
```

Count sessions where the hook fired. Compare against total session count.

## Output

```
## Skill Audit

Sessions analyzed: X
SessionStart hook fired: X/Y sessions (Z%)

### Usage

| Skill | Invocations | Sessions |
|-------|-------------|----------|
| ...   | ...         | ...      |

### Dormant Skills (installed but unused)
- skill-name: "description" — consider if trigger description needs work or skill should be retired

### Recommendations
1. [Most impactful finding]
```

## Notes

- Use `Glob` to find files and `Grep` to search content — `find`/`grep` are denied in Bash
- Dormant skills are the most actionable finding — either the description needs improvement or the skill isn't needed
- Keep output factual: numbers first, interpretation second

$ARGUMENTS
