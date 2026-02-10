---
description: Audit skill usage across recent Claude Code sessions
allowed-tools: Bash, Read
---

Analyze skill usage patterns across recent sessions to understand which skills are being invoked and which are being overlooked.

## What to Analyze

1. **Find recent session transcripts:**
   - Look in `~/.claude/projects/` for all project directories
   - Find `.jsonl` session files from the last 7 days
   - Focus on the current project first, then expand to all projects

2. **Extract skill usage data:**
   - Parse session transcripts for tool_use records where `name == "Skill"`
   - Count which skills were invoked and how often
   - Identify sessions where NO skills were used despite relevant tasks
   - Look for patterns in when skills are/aren't used

3. **Analyze hook effectiveness:**
   - Check if SessionStart hook messages appear in transcripts
   - Compare skill usage before/after hook installation (if timestamps available)
   - Identify if the hook reminder is present in session context

4. **Compare against available skills:**
   - List all installed skills from `~/.claude/skills/`
   - Identify skills that exist but are never used
   - Match task types in sessions to skill descriptions

## Output Format

### 📊 Skill Usage Summary (Last 7 Days)

```
Total sessions analyzed: X
Sessions with skill usage: X (X%)
Sessions without skill usage: X (X%)

Top skills used:
  1. skill-name (X times across Y sessions)
  2. skill-name (X times across Y sessions)
  ...
```

### 🔍 Current Project Analysis

```
Project: <project-name>
Recent sessions: X
Skill invocations: X

Details:
- Session <id> (<date>): skill1, skill2
- Session <id> (<date>): no skills used
```

### 📚 Installed vs Used Skills

```
Total installed skills: X
Skills used at least once: X (X%)
Never-used skills: X (X%)

Never used:
  - skill-name: "<description from SKILL.md>"
  - skill-name: "<description from SKILL.md>"
```

### 🎯 Pattern Analysis

Identify:
- Task types where skills should have been used but weren't
- Common rationalizations (if visible in transcripts)
- Evidence of hook firing in recent sessions
- Recommendations for improving skill adoption

### 💡 Recommendations

Based on usage patterns:
- Skills that might need better trigger descriptions
- Tasks where skill usage would have helped
- Whether the SessionStart hook is working effectively
- Suggestions for improving skill discoverability

## Implementation Notes

Use bash commands to parse JSONL files with `jq`:

```bash
# Find recent sessions
find ~/.claude/projects -name "*.jsonl" -mtime -7

# Extract skill usage from a session
jq -r 'select(.type == "assistant") |
       .message.content[]? |
       select(.type == "tool_use" and .name == "Skill") |
       "\(.input.skill)"' <session-file>

# Count skill frequency across all sessions
find ~/.claude/projects -name "*.jsonl" -mtime -7 -exec \
  jq -r 'select(.type == "assistant") |
         .message.content[]? |
         select(.type == "tool_use" and .name == "Skill") |
         .input.skill' {} \; | sort | uniq -c | sort -rn

# Check for hook messages in sessions
jq -r 'select(.type == "system") | .message.text' <session-file> | grep -i "specialized skills"
```

$ARGUMENTS
