---
name: audit-skills
description: Use when reviewing skill adoption, finding dormant skills, or measuring SessionStart hook effectiveness across recent sessions.
allowed-tools: Bash, Read, Glob, Grep
---

# Skill Usage Audit

Audit which skills are being invoked, which are dormant, and whether the skills system is driving adoption.

## Step 1: Discover Installed Skills

```
Glob with pattern="*/SKILL.md" path="~/repos/dotfiles/codex/.agents/skills"
```

Read each SKILL.md frontmatter for name and description.

## Step 2: Detect Platform and Find Transcripts

### Claude Code

Transcripts live in `~/.claude/projects/`. Skill invocations appear as `Skill` tool calls.

Pre-filter to avoid parsing large files unnecessarily:

```
Grep with pattern="\"name\":\"Skill\"" path="~/.claude/projects" glob="*.jsonl"
```

Only run jq on files that matched.

### Codex

Transcripts live in `~/.codex/sessions/`. Skill reads appear as `exec_command` calls that access SKILL.md files.

Pre-filter:

```
Grep with pattern="SKILL.md" path="~/.codex/sessions" glob="*.jsonl"
```

Only run jq on files that matched.

## Step 3: Extract Skill Usage

### Claude Code

For each matching transcript:

```bash
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Skill") |
       .input.skill' <file>
```

### Codex

For each matching transcript:

```bash
jq -r 'select(.type=="response_item" and .payload.type=="function_call" and .payload.name=="exec_command") |
       .payload.arguments' <file> |
  jq -r 'select(.cmd | test("SKILL\\.md")) |
         .cmd | capture(".*/skills/(?<skill>[^/]+)/SKILL\\.md").skill' 2>/dev/null
```

Cross-reference results against installed skills.

## Step 4: Check Hook Effectiveness

### Claude Code

```
Grep with pattern="specialized skills installed" path="~/.claude/projects" glob="*.jsonl"
```

Count sessions where the hook fired. Compare against total session count.

### Codex

Codex has no SessionStart hook equivalent. Skip this check and note it in the output.

## Output

```
## Skill Audit

Platform: [Claude Code / Codex]
Sessions analyzed: X
SessionStart hook fired: X/Y sessions (Z%) [Claude only, or "N/A — Codex" ]

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

- Use `Glob` to find files and `Grep` to search content — `find`/`grep` are denied in some environments
- Dormant skills are the most actionable finding — either the description needs improvement or the skill isn't needed
- Keep output factual: numbers first, interpretation second
- On Codex, skill reads may include browsing/discovery (listing all SKILL.md files) — deduplicate by counting unique skill names per session, not raw file accesses
