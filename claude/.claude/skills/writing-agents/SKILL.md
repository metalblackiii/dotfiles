---
name: writing-agents
description: Use when creating or editing custom agent .md files in .claude/agents/, defining new subagents, or modifying agent frontmatter
---

# Writing Agents

## Overview

Agents are autonomous subprocesses spawned via the Task tool for parallel or specialized work. Good agents have a clear role, restricted toolset, and compose with domain skills rather than duplicating content.

## Frontmatter Reference

All supported YAML frontmatter fields for agent `.md` files:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name (lowercase, letters/numbers/hyphens). Defaults to filename without `.md`. |
| `description` | Recommended | When to spawn this agent. Claude uses this to select `subagent_type`. Start with imperative verb or "Use when..." |
| `tools` | No | Comma-separated tools the agent can use (e.g., `Read, Grep, Glob, Bash`). Restricts to only these. |
| `disallowedTools` | No | Comma-separated tools the agent cannot use. Inverse of `tools` — use one or the other. |
| `model` | No | Model to use (`opus`, `sonnet`, `haiku`). Default inherits from parent. |
| `maxTurns` | No | Maximum agentic turns before stopping. Prevents runaway agents. |
| `skills` | No | YAML list of skills to load into the agent's context. |
| `mcpServers` | No | MCP servers available to the agent. |
| `memory` | No | Whether the agent has access to memory files. |
| `permissionMode` | No | Permission mode for the agent's tool calls. |
| `hooks` | No | Agent-scoped hooks. |

**Max frontmatter size:** 1024 characters total

## Description Best Practices

The description determines when Claude selects your agent as a `subagent_type`. It appears in the Task tool's available agents list.

```yaml
# BAD: Summarizes the process
description: Analyze code changes by reading diffs, checking patterns, and reporting findings

# BAD: Too vague
description: For code review

# GOOD: Triggering conditions only
description: Fresh-eyes code review of uncommitted or branch changes. Use as a pre-commit/pre-PR quality gate.

# GOOD: Specific use case
description: Research dependency upgrades, platform migrations, or breaking changes. Use when evaluating a version bump, migration path, or compatibility impact.
```

**Rules:**
- Describe when to spawn the agent, not what it does internally
- Write from the caller's perspective — what problem triggers spawning this agent?
- Keep under 500 characters

## Agent vs Skill

| Aspect | Agent | Skill |
|--------|-------|-------|
| **Runs as** | Subagent via Task tool (isolated context) | Loaded into current context |
| **Best for** | Research, analysis, parallel work | Methodology, discipline, checklists |
| **Context** | Separate — doesn't see or pollute main conversation | Shared — adds to current context |
| **Output** | Returns a result message to caller | Guides behavior inline |
| **Tools** | Can restrict to specific toolset | Uses whatever tools are available |
| **File** | Single `.md` in `agents/` | `SKILL.md` in `skills/<name>/` directory |
| **Example** | `self-code-reviewer` — runs a review in isolation | `analyzing-prs` — review criteria loaded inline |

**Use an agent when:** the work is self-contained, benefits from isolation, or should run in parallel.
**Use a skill when:** the guidance shapes how the main agent behaves throughout a task.

## Design Decisions

### Model Selection

| Model | Use for | Examples |
|-------|---------|----------|
| `sonnet` | Research, analysis, structured output | All 5 current agents |
| `opus` | Complex reasoning, nuanced judgment | Deep architectural analysis |
| `haiku` | Quick lookups, simple transformations | Lightweight data extraction |

Default to `sonnet`. Only escalate to `opus` when the task requires reasoning that `sonnet` can't reliably deliver.

### Tool Restrictions

Restrict tools to the minimum needed. Wider toolsets increase cost and risk of unexpected actions.

| Pattern | Tools | When |
|---------|-------|------|
| Read-only research | `Read, Grep, Glob, Bash` | Exploring code, tracing features |
| Research + web | `Read, Grep, Glob, Bash, WebSearch, WebFetch` | Needs external docs or changelogs |
| Code modification | `Read, Grep, Glob, Bash, Edit, Write` | Agents that make changes (rare) |

Omit `Edit` and `Write` unless the agent's purpose is to modify files. Most agents are read-and-report.

### maxTurns Guidance

| Scope | maxTurns | Rationale |
|-------|----------|-----------|
| Focused review | 10–15 | Known scope, limited files |
| Codebase exploration | 15–20 | Multiple repos or directories |
| Deep research + web | 20–25 | External sources + codebase analysis |

Set maxTurns to prevent runaway agents. Too low truncates useful work; too high wastes tokens on unfocused exploration.

## Skill Composition

Agents compose with skills via `skills:` frontmatter to inherit domain expertise without duplicating content.

| Agent | Loads Skill | Why |
|-------|-------------|-----|
| `self-code-reviewer` | `analyzing-prs` | Review criteria maintained in one place, reused by agent and manual reviews |
| `neb-explorer` | `neb-ms-conventions` | Service conventions shared across neb agents |
| `requirements-analyst` | `neb-ms-conventions` | Same conventions for assessing implementation feasibility |
| `analysis-writer` | `software-design` | Design principles inform comparison criteria |
| `upgrade-analyst` | `software-design` | Design principles inform migration recommendations |

**Pattern:** If a skill captures domain knowledge that an agent needs, compose rather than duplicate. When the skill updates, all agents that load it benefit automatically.

## Body Structure

The agent body (below frontmatter) is a prompt defining behavior. Structure it as:

```markdown
[Role statement — 1-2 sentences establishing identity and purpose]

## [Context / Input]
[What the agent receives and how to interpret it]

## Process
1. [Step-by-step approach]
2. [Each step is concrete and actionable]

## Output Format
[Template or structure for the agent's response]

## Guidelines
- [Behavioral rules]
- [Quality criteria]
- [What to avoid]
```

Keep the body focused. Delegate domain knowledge to composed skills. The body covers the agent's process and output format, not encyclopedic reference material.

## Quick Checklist

- [ ] Name: lowercase, letters/numbers/hyphens, matches filename
- [ ] Description: triggers only, caller's perspective, no process summary
- [ ] Tools: minimum required set, omit Edit/Write for read-only agents
- [ ] Model: `sonnet` unless stronger reasoning is needed
- [ ] maxTurns: set appropriately for scope (10–25 range)
- [ ] Skills: compose with domain skills rather than duplicating content
- [ ] Body: role → context → process → output → guidelines
- [ ] README: update agents table and count in repo root README

## Cross-References

**For description quality**, apply the `prompt-engineer` skill criteria. Agent descriptions are prompts that determine when the Task tool selects the agent. Evaluate for: trigger-only (no process summary), specificity (would the model match this to the right request?), and differentiation (does another agent's description overlap?).

**For current frontmatter fields and conventions**, consult the `claude-code-guide` agent. The frontmatter reference table above may lag behind Claude Code releases. When adding new agents or using unfamiliar frontmatter fields, verify against claude-code-guide.

## Anti-Patterns

- **Kitchen-sink tools** — Granting all tools when the agent only needs Read/Grep/Glob. Wider toolsets increase cost and risk of unexpected actions.
- **Missing composition** — Duplicating skill content in the agent body instead of loading via `skills:`. Causes drift when the skill updates.
- **No maxTurns** — Agent runs indefinitely, burning tokens on unfocused exploration. Always set a ceiling.
- **Vague role** — "You are a helpful assistant that analyzes code." Give the agent a specific identity and clear scope boundaries.
- **Process in description** — Description summarizes the agent's workflow instead of when to spawn it. Claude may follow the description instead of reading the body.
