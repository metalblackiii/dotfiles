---
name: writing-skills
description: Use when creating or editing SKILL.md files, defining new skills, or modifying skill frontmatter
---

# Writing Skills

## Overview

Skills are reusable methodology guides that agents load when relevant. Good skills are discoverable, concise, and actionable. The format follows the open [Agent Skills spec](https://agentskills.io/specification) — skills work across Claude Code, Codex, and other compatible agents.

## Frontmatter Reference

### Standard fields (agentskills.io spec)

These fields are recognized by all spec-compliant agents:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | **Yes** | Must match parent directory name. Lowercase letters, numbers, hyphens only. Max 64 chars. No leading/trailing/consecutive hyphens. |
| `description` | **Yes** | When to use this skill. Agents use this to decide when to load it. Max 1024 chars. |
| `license` | No | License name or reference to bundled license file |
| `compatibility` | No | Environment requirements (e.g., "Requires git, docker"). Max 500 chars. |
| `metadata` | No | Arbitrary key-value pairs (e.g., `author`, `version`) |
| `allowed-tools` | No | Space-delimited tools the skill may use (experimental, support varies) |

### Claude Code extensions

These fields are only recognized by Claude Code and are ignored by other agents:

| Field | Description |
|-------|-------------|
| `argument-hint` | Hint shown during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | Set `true` to prevent auto-loading. For manual-only workflows. |
| `user-invokable` | Set `false` to hide from `/` menu. For background knowledge skills. |
| `model` | Model to use when skill is active (e.g., `opus`, `sonnet`) |
| `context` | Set to `fork` to run in isolated subagent context |
| `agent` | Subagent type when `context: fork` (e.g., `Explore`, `Plan`) |
| `hooks` | Skill-scoped hooks (see Hooks documentation) |

### Codex extensions (optional/future-facing)

When available in a Codex runtime, these fields live in `agents/openai.yaml` inside the skill directory (not in SKILL.md frontmatter). Some environments may not support this file yet.

| Field (in `agents/openai.yaml`) | Description |
|---|---|
| `policy.allow_implicit_invocation` | Set `false` to prevent auto-selection. Codex equivalent of `disable-model-invocation`. Default: `true`. |
| `interface.display_name` | User-facing skill name in the Codex app |
| `interface.short_description` | User-facing description |

When disabling auto-invocation, set `disable-model-invocation: true` in SKILL.md frontmatter (Claude Code) and, when `agents/openai.yaml` is supported, set `allow_implicit_invocation: false` there for cross-platform consistency.

**Max frontmatter size:** 1024 characters total

## Description Best Practices

The description determines when Claude loads your skill. Critical for discovery.

```yaml
# BAD: Summarizes workflow - Claude may follow description instead of reading skill
description: Use for TDD - write test first, watch it fail, write minimal code

# BAD: Too vague
description: For debugging

# GOOD: Triggering conditions only, no workflow summary
description: Use when implementing any feature or bugfix, before writing implementation code

# GOOD: Specific symptoms
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
```

**Rules:**
- Start with "Use when..."
- Describe triggers/symptoms, NOT what the skill does
- Write in third person
- Max 1024 characters (spec limit), aim for under 500

## SKILL.md Structure

```markdown
---
name: skill-name
description: Use when [triggering conditions]
---

# Skill Name

## Overview
Core principle in 1-2 sentences.

## When to Use
- Symptoms and situations
- When NOT to use

## The Iron Law (for discipline skills)
The non-negotiable rule.

## [Core Content]
Techniques, patterns, quick reference tables.

## Common Rationalizations (for discipline skills)
| Excuse | Reality |
|--------|---------|

## Red Flags - STOP
Bullet list of warning signs.
```

## Creating a New Skill

Create a new skill directory directly in the canonical location:

```bash
mkdir codex/.agents/skills/my-skill-name
# Then create SKILL.md with proper frontmatter (see template above)
```

Both Claude and Codex share this directory — Claude accesses it via a symlink at `claude/.claude/skills`.

## Directory Structure

```
codex/.agents/skills/         # Source of truth — all skills live here
  skill-name/
    SKILL.md              # Required - main content
    scripts/              # Optional - executable code
    references/           # Optional - detailed docs, loaded on demand
    assets/               # Optional - templates, schemas, data files
```

**Keep inline:** Principles, code patterns (<50 lines), everything else
**Separate files (`references/`):** Heavy reference (100+ lines), loaded on demand by the agent
**Executable code (`scripts/`):** Reusable scripts/tools the agent can run

## Quick Checklist

- [ ] Name: required, must match directory name, lowercase/numbers/hyphens only, no leading/trailing/consecutive hyphens
- [ ] Description: starts with "Use when...", triggers only, no workflow
- [ ] Overview: core principle in 1-2 sentences
- [ ] Content: actionable, scannable (tables, bullets)
- [ ] For discipline skills: Iron Law, rationalizations table, red flags
- [ ] README: if adding or removing a skill, update the skills table in repo root README
- [ ] Size: <500 words for most skills, <200 for frequently-loaded

## Cross-References

**For description quality**, apply the `prompt-engineer` skill criteria when writing or reviewing descriptions. Skill descriptions are prompts — they determine when the model loads the skill. Evaluate each description for: trigger-only (no workflow summary), specificity (would the model match this to the right request?), overlap (does another skill's description match the same trigger?), and completeness (are common triggering scenarios covered?).

**For the open spec**, see [agentskills.io/specification](https://agentskills.io/specification). Standard fields work across all compatible agents. **For Claude Code extensions**, consult the `claude-code-guide` agent (Claude CLI only; it may not exist in Codex-focused repos) — Claude-specific fields may change between releases. Platform skill docs: [Claude Code](https://code.claude.com/docs/en/skills) | [Codex](https://developers.openai.com/codex/skills).

## Anti-Patterns

- **Workflow in description** - Claude follows description instead of reading skill
- **Narrative examples** - "In session X, we found..." - not reusable
- **Multi-language examples** - One excellent example beats many mediocre ones
- **Generic names** - `helper`, `utils`, `process` - name by what you DO
