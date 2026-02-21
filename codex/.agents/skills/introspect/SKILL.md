---
name: introspect
description: Use when reviewing agent configuration for conflicts, redundancy, staleness, or prompt quality issues. Covers skills, commands, settings, and instructions across Claude Code and Codex.
allowed-tools: Read, Glob, Grep
---

# Configuration Introspection

Audit agent configuration for conflicts, redundancy, staleness, and prompt quality.

## What to Analyze

Scan configuration from the dotfiles repo. Resolve the repo root dynamically: follow a symlink (e.g., `readlink ~/.claude/skills` or `readlink ~/.agents/skills/personal`) back to the source, or run `git rev-parse --show-toplevel` from inside it. All config lives under these paths (relative to the repo root):

### Shared (both platforms)
- `shared/INSTRUCTIONS.md` — global instructions (single source of truth)
- `codex/.agents/skills/*/SKILL.md` — canonical skill files (source of truth)
- `claude/.claude/CLAUDE.md` — symlink → `shared/INSTRUCTIONS.md`
- `codex/AGENTS.md` — symlink → `shared/INSTRUCTIONS.md`

### Claude Code
- `claude/.claude/settings.json` — global settings
- `claude/.claude/commands/*.md` — slash commands
- `claude/.claude/agents/*.md` — agent definitions
- `claude/.claude/skills` — symlink → `codex/.agents/skills`

### Codex
- `codex/.codex/config.toml` — Codex settings
- `codex/.agents/skills/` — actual skill directories (source of truth)

Also check for project-level overrides:
- `.claude/settings.json`, `.claude/CLAUDE.md` (project-scoped Claude)
- `AGENTS.md` (project-scoped Codex)

## Checks

### 1. Conflicts

Instructions that contradict each other, across or within files:
- Settings that deny a tool one file allows
- Instructions that diverge between shared and platform-specific files
- Skills with overlapping triggers that give conflicting guidance

### 2. Redundancy

Multiple skills, commands, or agents doing the same thing:
- Skills with near-identical descriptions
- Commands that duplicate skill functionality
- Agent definitions that replicate what a skill already covers

### 3. Staleness

Instructions that may be obsolete:
- References to removed files, tools, or patterns
- Skills that haven't been invoked in recent sessions (cross-reference with `audit-skills` if available)
- Workarounds for issues that have been fixed upstream

### 4. Prompt Quality Audit

For each skill, evaluate the **description** field. Read the `prompt-engineer` skill (sibling directory at `../prompt-engineer/SKILL.md`) for criteria, then assess:

- **Trigger-only?** Does it say WHEN to use, not HOW it works? Descriptions containing process steps cause agents to follow the brief summary instead of reading the full skill.
- **Specific enough?** Would a model reliably match this description to the right user request?
- **Overlap detection:** Do any two descriptions match the same user request? If so, which one wins and is the precedence clear?
- **Completeness:** Are there common triggering scenarios the description misses?

Rate each: **STRONG** / **NEEDS WORK** / **WEAK**, with a one-line explanation.

### 5. Cross-Platform Parity

Both platforms share the same skill directory (`codex/.agents/skills/`). Verify all three levels resolve correctly:

**Canonical (source of truth):** `Glob("codex/.agents/skills/*/SKILL.md")` from the dotfiles repo root

**Claude runtime:** `Glob("*/SKILL.md")` from `~/.claude/skills/`
- Symlink chain: `~/.claude/skills` → `dotfiles/claude/.claude/skills` → `../../codex/.agents/skills`
- Should match canonical skill names exactly

**Codex runtime:** `Glob("personal/*/SKILL.md")` from `~/.agents/skills/`
- Structure: `~/.agents/skills/personal/` → `dotfiles/codex/.agents/skills` (symlink under real parent dirs)
- Should match canonical skill names exactly

Do NOT glob within the repo at `claude/.claude/skills/` — it's a relative symlink that only resolves at the installed location.

Note: some assets are inherently platform-specific and should NOT be flagged:
- Slash commands (`claude/.claude/commands/`) — Claude Code only, Codex has no equivalent
- Custom agents (`claude/.claude/agents/`) — Claude Code only, Codex has no equivalent
- `settings.json`, hooks, scripts — Claude Code only, Codex uses `config.toml`

## Known-Intentional Patterns (Do NOT Flag)

- Empty `attribution` fields in settings.json — intentionally suppress default attribution behavior
- Claude-only commands (`.claude/commands/`) that have shared skill equivalents — the command is kept for `/slash` invocation

## Output Format

```markdown
### Conflicts Found
[Contradictory instructions that need resolution]

### Redundancies
[Duplicated or overlapping functionality]

### Potentially Stale
[May no longer be needed]

### Prompt Quality Audit
[Per-skill description rating with improvement suggestions]

### Cross-Platform Parity
[Missing symlinks, platform-only skills that could be shared]

### Configuration Health
[What's working well]

### Suggestions
[Improvements or gaps to consider]
```

Omit any section with no findings.
