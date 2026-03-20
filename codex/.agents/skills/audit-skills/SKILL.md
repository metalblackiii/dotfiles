---
name: audit-skills
description: ALWAYS invoke when reviewing skill adoption, finding dormant skills, or evaluating skill-discovery effectiveness across recent sessions on Claude Code or Codex.
allowed-tools: Bash, Read, Glob, Grep
---

# Skill Usage Audit

Audit which skills are being invoked, which are dormant, and whether the skills system is driving adoption.

## Step 1: Discover Installed Skills

```
Glob with pattern="*/SKILL.md" path="~/.claude/skills"        # Claude Code
Glob with pattern="personal/*/SKILL.md" path="~/.agents/skills"  # Codex
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

Transcripts live in `~/.codex/sessions/`. Event schema can vary by Codex version, so use a layered approach:

1. Prefer runtime-resolved skill payloads or equivalent explicit platform events.
2. If those are unavailable, use direct launcher evidence (`$skill ...` or equivalent user/invocation markers).
3. If explicit invocation evidence is unavailable, use SKILL.md access patterns as a fallback signal.
4. If none of the above are available, report the limitation instead of inferring usage from weak signals.

Pre-filter:

```
Grep with pattern="<skill>|\\$skill |SKILL.md" path="~/.codex/sessions" glob="*.jsonl"
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

For each matching transcript, extract usage with the strongest evidence available in that file set.

Preferred evidence order:

1. **Runtime-injected skill payloads** (highest confidence)
2. **Raw launcher evidence** (`$skill ...` or user-entered `$skill-name`)
3. **SKILL.md reads** (fallback only)

Count unique skill names per session, not raw hits. If both a launcher record and a runtime-injected skill payload exist for the same skill in the same session, count that session once and prefer the injected payload as the evidence source.

High-confidence Codex examples:

```bash
# Runtime-injected skill payloads
jq -r '
  select(.type=="response_item" and .payload.type=="message") |
  .payload.content[]? |
  select(.type=="input_text" and (.text | startswith("<skill>\n<name>"))) |
  .text | capture("<name>(?<skill>[^<]+)</name>").skill
' <file>

# User-entered "$skill-name" messages
jq -r '
  select(.type=="event_msg" and .payload.type=="user_message") |
  .payload.message |
  select(test("^\\$[A-Za-z0-9-]+(?:\\s|$)")) |
  capture("^\\$(?<skill>[A-Za-z0-9-]+)").skill
' <file>
```

Supporting launcher evidence example:

```bash
# Assistant launcher command (may be followed by injected payload, or may fail)
jq -r '
  select(.type=="response_item" and .payload.type=="function_call" and .payload.name=="exec_command") |
  .payload.arguments | fromjson? | .cmd? // empty |
  select(test("^\\$skill\\s+[A-Za-z0-9-]+(?:\\s|$)")) |
  capture("^\\$skill\\s+(?<skill>[A-Za-z0-9-]+)").skill
' <file>
```

Fallback example (SKILL.md read signal only):

```bash
jq -r 'select(.type=="response_item" and .payload.type=="function_call" and .payload.name=="exec_command") |
       .payload.arguments' <file> |
  jq -r 'select(.cmd | test("SKILL\\.md")) |
         .cmd | capture(".*/skills/(?<skill>[^/]+)/SKILL\\.md").skill' 2>/dev/null
```

Cross-reference results against installed skills, and label confidence:
- **High confidence**: runtime-injected skill payloads or equivalent explicit platform events
- **Medium confidence**: raw launcher evidence (`$skill`, user-entered skill invocation markers)
- **Low confidence**: partial/fallback signals only

## Step 4: Check Skill Discovery Signal Effectiveness

### Claude Code

```
Grep with pattern="specialized skills installed" path="~/.claude/projects" glob="*.jsonl"
```

Count sessions where the hook fired. Compare against total session count.

### Codex

Codex has no direct SessionStart hook equivalent. Instead:
- Measure whether sessions show early skill discovery/use signals (explicit skill invocation preferred).
- If transcript schema does not expose reliable signals, report `N/A` with a short reason.

## Output

```
## Skill Audit

Platform: [Claude Code / Codex]
Sessions analyzed: X
Discovery signal effectiveness: [Claude hook X/Y (Z%) | Codex signal X/Y (Z%) | N/A with reason]
Confidence: [High / Medium / Low]

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
- On Codex, runtime-injected `<skill>` payloads are stronger evidence than raw `$skill` launcher strings; prefer them when both appear in the same session
- On Codex, user-entered `$skill-name` messages are real manual invocations, but assistant-side `$skill ...` launcher attempts may fail; do not treat launcher attempts as stronger evidence than injected payloads
- On Codex, SKILL.md reads may include browsing/discovery (listing many skills up front) — deduplicate by counting unique skill names per session, not raw file accesses
- Prefer explicit invocation evidence over SKILL.md-read heuristics whenever available
