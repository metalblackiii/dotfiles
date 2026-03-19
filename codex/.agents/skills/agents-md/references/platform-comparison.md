# Platform Comparison

## 7-Tool Comparison Matrix

| Feature | Claude Code | Codex | Cursor | Windsurf | Copilot | Cline | Zed |
|---|---|---|---|---|---|---|---|
| **Root file** | CLAUDE.md | AGENTS.md | .cursor/rules/*.mdc | .windsurfrules | .github/copilot-instructions.md | .clinerules | .rules |
| **User-global** | ~/.claude/CLAUDE.md | ~/.codex/AGENTS.md | User Rules | global_rules.md | Personal instructions | ~/Documents/Cline/Rules | Rules Library |
| **Nested/directory** | Walk-up + lazy subdir | Git root to cwd | Glob-scoped rules | Up to git root | applyTo globs | paths frontmatter | No |
| **Org/managed** | System paths (unexcludable) | No | Team Rules dashboard | System paths | Org instructions | No | No |
| **@imports** | Yes | No | No | No | No | No | No |
| **Frontmatter** | paths: in rules/ | No | globs, alwaysApply | trigger: modes | applyTo: | paths: | No |
| **AGENTS.md** | Via @import shim | Native | Native (root-only) | Native | Native | Native | Native |

## Size Guidelines by Platform

| Platform | Limit | Type | Notes |
|---|---|---|---|
| **Claude Code** | <200 lines | Soft (official recommendation) | Per CLAUDE.md file |
| **Codex** | 32 KiB | Hard (configurable) | Total across all AGENTS.md files |
| **Cursor** | <500 lines | Soft | Per .mdc rule file |
| **Windsurf** | 6K chars/file, 12K total | Hard | Strictest limit; requires aggressive pruning |
| **Copilot** | ~2 pages | Soft | Vague; roughly 100-150 lines |
| **Cline** | Not specified | — | No published limit |
| **Zed** | Not specified | — | No published limit |

**Cross-platform safe target:** Under 150 lines, under 6K characters. This satisfies all platforms with headroom.

## AGENTS.md vs CLAUDE.md Relationship Patterns

### Pattern 1: AGENTS.md Canonical + CLAUDE.md Stub

```
# CLAUDE.md (2 lines)
@AGENTS.md
```

**When to use:** Multi-tool teams, open-source repos, any repo where portability matters. AGENTS.md is the cross-platform standard (20+ tools); CLAUDE.md just redirects.

**Pros:** Single source of truth; works everywhere; no duplication
**Cons:** Can't use Claude-specific features (@imports to deep paths, path-scoped rules references) in the shared file

### Pattern 2: Independent Files

```
AGENTS.md    → Cross-platform rules (build commands, conventions, constraints)
CLAUDE.md    → Claude-specific config (@imports, hooks references, skills references)
```

**When to use:** When Claude-specific features add real value beyond what AGENTS.md can express. The CLAUDE.md supplements, never duplicates.

**Pros:** Each file serves its platform's strengths
**Cons:** Two files to maintain; risk of contradiction

### Pattern 3: Symlinked (Dotfiles Pattern)

```
AGENTS.md    → symlink to canonical source
CLAUDE.md    → symlink to same target (or to AGENTS.md)
```

**When to use:** Dotfiles repos or any setup where both files should always be identical. The symlink is the single source of truth — no drift possible.

**Pros:** Zero maintenance; physically impossible to diverge
**Cons:** Only works when content is truly identical across platforms

**During audit:** If both files resolve to the same inode or one is a symlink to the other, classify as "Symlinked" — not duplication. This is intentional.

### Pattern 4: Full Duplication (Anti-Pattern)

```
AGENTS.md    → Full content
CLAUDE.md    → Same content (copy-pasted, NOT symlinked)
```

**Never use.** Guaranteed drift. Double maintenance. If found during audit, consolidate to Pattern 1, 2, or 3.

## Cross-Platform Strategy

### For Shared Repos (Team Projects)

Use AGENTS.md as canonical with an @import shim for Claude Code:

```markdown
# CLAUDE.md
@AGENTS.md
```

Put Claude-specific content (if any) below the import in CLAUDE.md. Keep AGENTS.md portable — no Claude-specific syntax, no @imports within it.

If the team uses Cursor alongside Claude/Codex, create `.cursor/rules/main.mdc` with:
```
---
globs: ["**/*"]
alwaysApply: true
---
<!-- Content mirrored from AGENTS.md or maintained independently -->
```

### For Dotfiles Repos (Personal Config)

Use symlinks to share content across platforms. The key principle: pick one canonical file, symlink everything else to it.

```
# Example layout (paths vary by repo)
<canonical-location>/AGENTS.md          # single source of truth
claude/.claude/CLAUDE.md  →  <canonical> # symlink if content is identical
codex/AGENTS.md           →  <canonical> # symlink for Codex

# OR: independent CLAUDE.md when Claude-specific features are needed
claude/.claude/CLAUDE.md                 # independent file with @imports
```

The dotfiles pattern allows different content per platform while keeping everything in one repo. Use Phase 1 discovery to find the actual layout — don't assume root-level paths.

### Progressive Disclosure Architecture

For repos that outgrow a single file, use a three-layer approach:

**Layer 1: Root file (~500 tokens)**
- 2-3 sentence project overview
- Essential non-obvious commands
- Stack + versions (only if not in config files)
- Pointers to deeper docs
- "Before starting any task, identify which docs below are relevant and read them first."

**Layer 2: Satellite docs (200-500 tokens each)**
- Domain-specific gotchas, loaded on-demand
- `.claude/rules/` with `paths:` frontmatter for path-scoped loading (Claude Code)
- `@import` for explicit loading

**Layer 3: Skills / Subagents**
- Specialized methodology for distinct domains
- Isolated context windows — don't pollute main conversation
- ~100 tokens metadata, full body only on invocation

One practitioner reported a **54% reduction in initial context usage** after migrating to progressive disclosure.

### When to Stay Monolithic

Stay with a single file when:
- Total content fits under 100 lines
- No path-scoped rules needed
- Single-purpose repo (library, CLI tool, small service)
- Solo developer using one AI tool

## Sources

- Claude Code Memory: code.claude.com/docs/en/memory
- Codex AGENTS.md Guide: developers.openai.com/codex/guides/agents-md
- Cursor Rules: cursor.com/docs/context/rules
- Windsurf Memories: docs.windsurf.com/windsurf/cascade/memories
- Copilot Instructions: docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot
- Cline Rules: docs.cline.bot/features/cline-rules
- Zed AI Rules: zed.dev/docs/ai/rules
- agents.md Open Standard: agents.md
- Progressive Disclosure: alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools
