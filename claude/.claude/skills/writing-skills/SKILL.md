---
name: writing-skills
description: Use when creating or editing SKILL.md files, defining new skills, or modifying skill frontmatter
---

# Writing Skills

## Overview

Skills are reusable methodology guides that Claude loads when relevant. Good skills are discoverable, concise, and actionable.

## Frontmatter Reference

All supported YAML frontmatter fields:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name (lowercase, letters/numbers/hyphens only, max 64 chars). Defaults to directory name. |
| `description` | Recommended | When to use this skill. Claude uses this to decide when to load it. Start with "Use when..." |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | No | Set `true` to prevent auto-loading. For manual-only workflows. |
| `user-invocable` | No | Set `false` to hide from `/` menu. For background knowledge skills. |
| `allowed-tools` | No | Comma-separated tools allowed without permission when skill is active |
| `model` | No | Model to use when skill is active (e.g., `opus`, `sonnet`) |
| `context` | No | Set to `fork` to run in isolated subagent context |
| `agent` | No | Subagent type when `context: fork` (e.g., `Explore`, `Plan`) |
| `hooks` | No | Skill-scoped hooks (see Hooks documentation) |

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
- Keep under 500 characters

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

## Directory Structure

```
~/.claude/skills/
  skill-name/
    SKILL.md              # Required - main content
    supporting-file.*     # Optional - heavy reference or tools only
```

**Keep inline:** Principles, code patterns (<50 lines), everything else
**Separate files:** Heavy reference (100+ lines), reusable scripts/tools

## Quick Checklist

- [ ] Name: lowercase, letters/numbers/hyphens only
- [ ] Description: starts with "Use when...", triggers only, no workflow
- [ ] Overview: core principle in 1-2 sentences
- [ ] Content: actionable, scannable (tables, bullets)
- [ ] For discipline skills: Iron Law, rationalizations table, red flags
- [ ] Size: <500 words for most skills, <200 for frequently-loaded

## Anti-Patterns

- **Workflow in description** - Claude follows description instead of reading skill
- **Narrative examples** - "In session X, we found..." - not reusable
- **Multi-language examples** - One excellent example beats many mediocre ones
- **Generic names** - `helper`, `utils`, `process` - name by what you DO
