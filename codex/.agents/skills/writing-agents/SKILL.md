---
name: writing-agents
description: ALWAYS invoke when creating, updating, or converting agent/subagent definitions for Claude Code or Codex. Covers frontmatter fields, TOML format, cross-platform field mapping, and sync conventions. Do not write agent definitions directly. Not for skills (use writing-skills).
---

# Writing Agents

## Overview

Agents are named subagent definitions that platforms load and dispatch for specialized tasks. Claude Code uses Markdown + YAML frontmatter; Codex uses TOML config-layer files. This skill provides the field references, cross-platform mapping, and authoring conventions needed to create agents on either platform and keep them in sync.

## When to Use

- Creating a new Claude Code agent (`.claude/agents/*.md`)
- Creating a new Codex agent (`.codex/agents/*.toml`)
- Converting a Claude agent to Codex (or vice versa)
- Updating agent frontmatter fields
- Reviewing whether an agent definition is complete

## When NOT to Use

- Writing or updating skills → `writing-skills`
- Editing AGENTS.md or CLAUDE.md → `agents-md`
- Debugging agent dispatch behavior (that's runtime, not authoring)

## Repo Convention

Claude Code `.md` agents are the canonical source. Codex `.toml` agents are generated or hand-created from them. When modifying an agent, update the Claude Code file first, then update the Codex file in the same commit.

```
claude/.claude/agents/          # Claude Code agents (canonical)
  research.md
  upgrade-analyst.md
  neb-explorer.md

codex/.codex/agents/            # Codex agents (derived)
  research.toml
  upgrade-analyst.toml
  neb-explorer.toml
```

Skills live in `codex/.agents/skills/` (shared via symlink). Agents are platform-specific and live in separate directories.

## Invocation

**Claude Code**: The model reads agent descriptions and auto-routes tasks to matching agents via `Agent(subagent_type="name")`. Strong descriptions (starting with "ALWAYS invoke") improve routing reliability. Users can also invoke explicitly with `@"name (agent)"` syntax in the prompt.

**Codex**: Codex only spawns subagents when explicitly asked — there is no auto-routing based on descriptions. The `description` field helps the model choose *which* agent when it decides to spawn one. Users should request agents explicitly:

```
Use the research agent to find the current Node LTS versions
Spawn upgrade-analyst to evaluate upgrading Sequelize v6 to v7
Use neb-explorer to trace appointment creation across repos
```

Codex may auto-downgrade subagent models (e.g., spawning at `gpt-5.4-mini medium` even when the parent runs `gpt-5.4 high`). To force the parent model, set `model` explicitly in the agent TOML — but this increases cost and may not be necessary for most tasks.

## Claude Code Agent Format

Markdown file with YAML frontmatter. The body becomes the agent's system prompt.

```markdown
---
name: my-agent
description: When to use this agent — Claude reads this to decide when to delegate
tools: Read, Grep, Glob, Bash
model: sonnet
maxTurns: 20
skills:
  - some-skill
---

You are a specialist. Do X when invoked.
```

**Required fields:** `name`, `description`

For the complete field reference (14 fields with types, defaults, and interaction rules), see `references/claude-code-fields.md`.

### Description Best Practices

Same rules as skills — start with "ALWAYS invoke" or a clear trigger phrase. Include a negative constraint ("Do not X directly") when the model's default path is to answer without the agent.

```yaml
# Weak — passive, Claude may skip delegation
description: Use for exploring microservices architecture

# Strong — directive with escape-hatch blocker
description: ALWAYS invoke to explore feature implementations, data flows, or patterns across the neb microservices ecosystem. Do not trace cross-service calls directly.
```

### Key Behaviors

- Subagents run in fresh context — no parent history, no inherited skills
- Skills listed in `skills:` are eagerly injected (full content at startup)
- `tools:` is an allowlist; omit to inherit all tools
- `disallowedTools:` is a denylist; applied before `tools:` when both set
- Subagents cannot spawn other subagents (no nesting)

## Codex Agent Format

Standalone TOML file. Acts as a config layer merged onto the parent session.

```toml
name = "my-agent"
description = "When to use this agent"
developer_instructions = """
You are a specialist. Do X when invoked.
"""

model = "gpt-5.4"
sandbox_mode = "workspace-write"
model_reasoning_effort = "high"
```

**Required fields:** `name`, `description`, `developer_instructions`

For the complete field reference, see `references/codex-fields.md`.

### Key Behaviors

- Custom agents override built-ins with matching names
- Agents inherit the parent session's config; the TOML layers on top
- Any `config.toml` key is valid in an agent file (model, sandbox, MCP, skills, etc.)
- Skills are available by default; use `skills.config` to filter if needed

## Cross-Platform Field Mapping

| Claude Code | Codex | Notes |
|---|---|---|
| `name` | `name` | Direct — same purpose |
| `description` | `description` | Direct — same routing purpose |
| *(markdown body)* | `developer_instructions` | Direct — body becomes TOML multiline string |
| `model: sonnet` | `model = "gpt-5.4"` | Different vendor models; not a sync concern |
| `tools: Read, Grep` | `sandbox_mode` | No 1:1 mapping — set by intent (read-only/write/full) |
| `disallowedTools` | *(no equivalent)* | Skip — Codex uses sandbox mode instead |
| `maxTurns: 25` | *(global time limit)* | Skip — Codex uses `agents.job_max_runtime_seconds` |
| `skills: [foo]` | `skills.config` | Inverted — Claude includes, Codex excludes |
| `permissionMode` | `approval_policy` | Closest: `default`≈`on-request`, `dontAsk`≈`never` (both minimize prompts; semantics differ — Claude auto-denies unallowed, Codex skips confirmation) |
| `effort` | `model_reasoning_effort` | Direct: `low`/`medium`/`high` |
| `hooks` | *(no equivalent)* | Skip |
| `memory` | *(no equivalent)* | Skip |
| `isolation: worktree` | *(no equivalent)* | Skip |
| `background` | *(native concurrency)* | Skip — Codex has `agents.max_threads` |
| `mcpServers` | `mcp_servers` | Both support per-agent MCP; syntax differs |
| *(no equivalent)* | `nickname_candidates` | Codex-only UI feature |

## Creating a New Agent

### 1. Write the Claude Code agent first

Create `claude/.claude/agents/<name>.md` with frontmatter and body:

```markdown
---
name: <name>
description: ALWAYS invoke for [triggers]. Do not [action] directly.
tools: <tool list>
model: sonnet
maxTurns: <limit>
---

<system prompt body>
```

### 2. Create the Codex equivalent

Create `codex/.codex/agents/<name>.toml`:

```toml
name = "<name>"
description = "<same description>"
developer_instructions = """
<same body content>
"""

sandbox_mode = "workspace-write"
model_reasoning_effort = "high"
```

Use the field mapping table above for any additional fields.

### 3. Validate

```bash
# Claude Code agents: check required frontmatter
for f in claude/.claude/agents/*.md; do
  rg -q '^name: ' "$f" && rg -q '^description: ' "$f" || echo "Missing keys: $f"
done

# Codex agents: check required fields
for f in codex/.codex/agents/*.toml; do
  rg -q '^name = ' "$f" && rg -q '^description = ' "$f" && rg -q '^developer_instructions' "$f" \
    || echo "Missing keys: $f"
done

# Cross-platform: every Claude agent should have a Codex counterpart
for f in claude/.claude/agents/*.md; do
  name=$(rg '^name: ' "$f" | head -1 | sed 's/^name: //')
  [ -f "codex/.codex/agents/${name}.toml" ] || echo "Missing Codex agent: ${name}.toml"
done
```

### 4. Commit both in the same commit

Convention: update both platform files together. If you change the body or description in the Claude agent, update the Codex agent in the same commit.

## Quick Reference

### Claude Code storage locations (priority order)

| Priority | Location | Scope |
|---|---|---|
| 1 (highest) | `--agents` CLI JSON | Session only |
| 2 | `.claude/agents/` | Project |
| 3 | `~/.claude/agents/` | User (all projects) |
| 4 | Plugin `agents/` | Where plugin enabled |

### Codex storage locations

| Location | Scope |
|---|---|
| `.codex/agents/` | Project |
| `~/.codex/agents/` | User (all projects) |

### What agents inherit vs. receive

| | Claude Code | Codex |
|---|---|---|
| **Receives** | Own system prompt + Agent tool prompt | Parent config + role layer |
| **Does NOT receive** | Parent history, parent skills, parent system prompt | *(inherits parent config unless overridden)* |
| **Skills** | Only if listed in `skills:` | All discovered; filter via `skills.config` |

## Anti-Patterns

- **Putting platform-specific tool names in the body** — the body should be platform-agnostic where possible; tool names belong in frontmatter/TOML fields
- **Duplicating skill content in the agent body** — use `skills:` to inject skills instead of copy-pasting their content
- **Forgetting the Codex counterpart** — every Claude agent should have a `.toml`; run the validation snippet
- **Over-restricting tools** — omitting `tools:` inherits everything, which is usually the right default; restrict only when the agent should be read-only or scoped
