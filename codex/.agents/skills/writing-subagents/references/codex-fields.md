# Codex Custom Agent TOML — Complete Field Reference

> Source: [developers.openai.com/codex/subagents](https://developers.openai.com/codex/subagents)
> Config schema: [github.com/openai/codex/.../config.schema.json](https://github.com/openai/codex/blob/main/codex-rs/core/config.schema.json)
> Current as of 2026-03-21

## Overview

Codex custom agents are standalone TOML files that act as config layers for spawned agent sessions. They live in `.codex/agents/` (project) or `~/.codex/agents/` (user). Each file is deserialized as agent-specific fields (`name`, `description`, `developer_instructions`, `nickname_candidates`) plus a flattened `ConfigToml` — meaning any valid `config.toml` key is also valid in an agent file.

Custom agent roles are resolved before built-ins. A custom agent named `explorer` overrides the built-in explorer.

## Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | string | Spawn key. Used by Codex to identify and route to this agent. Overrides built-in if names match. Filename should match `name` but `name` field is source of truth. |
| `description` | string | Routing hint. Codex uses this to decide which agent to deploy for a given task. |
| `developer_instructions` | string | System prompt equivalent. Use TOML multiline strings (`"""..."""`) for long content. This is the agent's core instructional text. |

## Agent-Specific Optional Fields

| Field | Type | Description |
|---|---|---|
| `nickname_candidates` | array of strings | Display name aliases for UI. Internal identity always uses `name`. |

## Config-Layer Fields (any config.toml key)

These are the most commonly used config keys in agent files. The full set is the entire `config.toml` schema.

### Model & Reasoning

| Field | Type | Default | Description |
|---|---|---|---|
| `model` | string | *(inherit)* | Any supported model ID. If omitted, inherits from parent session. |
| `model_reasoning_effort` | string | *(inherit)* | `minimal`, `low`, `medium`, `high`, `xhigh` |
| `model_reasoning_summary` | string | *(inherit)* | `auto`, `concise`, `detailed`, `none` |
| `model_verbosity` | string | *(inherit)* | `low`, `medium`, `high` (GPT-5 Responses API) |

### Sandbox & Security

| Field | Type | Default | Description |
|---|---|---|---|
| `sandbox_mode` | string | *(inherit)* | `read-only` — no writes or command execution. `workspace-write` — writes limited to workspace, network disabled by default. `danger-full-access` — no restrictions. |
| `approval_policy` | string or object | *(inherit)* | `untrusted` — most restrictive, prompts before untrusted operations. `on-request` — prompts for sensitive ops. `never` — no prompts, best-effort within sandbox. Or granular: `{ granular = { sandbox_approval = bool, rules = bool, mcp_elicitations = bool, request_permissions = bool, skill_approval = bool } }` |

Protected paths (always read-only regardless of mode): `.git/`, `.agents/`, `.codex/`

### Skills & MCP

| Field | Type | Description |
|---|---|---|
| `skills.config` | array | Per-skill enable/disable overrides. Each entry has `path` and `enabled` fields. |
| `mcp_servers` | table | MCP server configuration. Each entry can include `enabled_tools`/`disabled_tools` for per-server tool filtering. |

### Tools

| Field | Type | Description |
|---|---|---|
| `tools.view_image` | boolean | Enable/disable image viewing |
| `tools.web_search` | boolean | Enable/disable web search |

## Global Subagent Settings

These live in `config.toml` under `[agents]`, not in per-agent files:

| Key | Type | Default | Description |
|---|---|---|---|
| `agents.max_threads` | integer | 6 | Maximum concurrent agent threads |
| `agents.max_depth` | integer | 1 | Maximum nesting depth for spawned agents |
| `agents.job_max_runtime_seconds` | integer | — | Time-based limit for agent execution |

## Storage Locations

| Location | Scope | Notes |
|---|---|---|
| `.codex/agents/` | Project-scoped | Discovered from project root |
| `~/.codex/agents/` | User-scoped | Available in all projects |

Discovery: Codex scans `agents/` directories attached to loaded config layers, recursively finding `.toml` files. Custom agents override built-ins with matching names.

## Dispatch & Lifecycle

- Codex only spawns subagents when explicitly asked — no auto-fan-out
- At spawn time: starts from parent's effective config → copies runtime state → applies live overrides → layers custom role on top
- Custom roles resolved before built-ins
- `name` is source of truth (filename is convention only)

### Lifecycle Tools (from Codex source)

| Tool | Purpose |
|---|---|
| `spawn_agent` | Create and start a new agent thread |
| `send_input` | Send a message to a running agent |
| `wait_agent` | Block until an agent completes or a condition is met |
| `resume_agent` | Resume a paused agent |
| `close_agent` | Terminate an agent thread |

## Inheritance Behavior

Spawned agents inherit the parent session's effective config, including:
- Model, model provider, reasoning settings
- Developer instructions (from AGENTS.md hierarchy)
- CWD, shell environment policy
- Filesystem sandbox policy, network sandbox policy
- Approval/sandbox overrides made interactively during the session

The custom agent's TOML layers on top, overriding any fields it explicitly sets.

## Example

```toml
name = "research"
description = "General-purpose research and multi-step tasks. Use for web research, codebase investigation, and multi-angle analysis."
developer_instructions = """
You are a research agent. Investigate questions thoroughly, search code, fetch web sources, and execute multi-step tasks.

## Guidelines

- Lead with action — start researching immediately, don't ask for confirmation
- Include source URLs for every web claim
- Reference specific file:line for codebase findings
- Write findings as structured markdown when outputting to files
- Be thorough but concise — cover the topic, skip the filler
"""

sandbox_mode = "workspace-write"
model_reasoning_effort = "high"
```

## Recent Timeline

| Date | Change |
|---|---|
| 2025-12-19 | Agent skills announced in Codex |
| 2026-01-22 | Custom prompts deprecated in favor of skills |
| 2026-02-02 | Codex app announced (desktop multi-agent UI) |
| 2026-03-21 | Subagent workflows enabled by default in current releases |
