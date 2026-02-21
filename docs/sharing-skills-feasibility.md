# Feasibility Analysis: Sharing Agent Skills

How to share a personal agent skills setup with teammates. This document preserves the research, options evaluated, and decision rationale from the analysis session (February 2026).

## The Problem

The team's pain is context-switching fatigue from the Cursor / Claude Code / Codex shuffle. Each tool has different configuration, different conventions, and different expectations. Personal agent configuration solves this — but only if people actually adopt it.

The question: what's the right mechanism for sharing?

## Options Evaluated

### Option 1: Symlink Bundles

Reorganize skills into bundle directories (`discipline/`, `review/`, `architecture/`), update `install.sh` to accept `--bundle` flags, symlink selected bundles flat into `~/.claude/skills/`.

**Pros:** Live edits work, minimal rebuild, selective installation.
**Cons:** Bundle boundaries are inherently subjective. Skills reference each other (e.g., `verification-before-completion` references `refactoring-guide`), creating cross-bundle dependencies that fight the grouping.

### Option 2: Manifest / Registry

Define a manifest file listing skill bundles with dependencies. An install script reads the manifest, resolves dependencies, and symlinks the result.

**Pros:** Cleaner dependency management than raw bundles.
**Cons:** You're building a package manager. The manifest needs maintenance every time skills change. Solving a distribution problem nobody has yet.

### Option 3: Plugin System

Claude Code has a plugin system with marketplace infrastructure. Package skill bundles as plugins, distribute via `claude plugin install`.

**Pros:** Native distribution, users install only what they need, handles namespacing.
**Cons:** Plugins are Claude Code-only (Codex has no equivalent). Bigger refactor. Skills become namespaced (`/bundle:skill-name`). Converts a personal tool into a public API with implicit stability expectations.

### Option 4: Fork and Customize

Publish the repo. People fork, delete what they don't need, add their own skills.

**Pros:** Zero infrastructure to build. People get the full picture and can learn from the structure.
**Cons:** Forks diverge immediately and never pull updates. High activation energy to curate someone else's opinionated config. People who invest the effort to customize tend to build from scratch anyway.

### Option 5: Workshop + Reference (chosen)

Keep the repo as-is. Share it as a reference artifact. Teach the patterns through recurring sessions. Let people build their own setup inspired by what they see.

**Pros:** Zero maintenance burden. Preserves iteration velocity. Shares the fishing rod (patterns, structure, conventions) rather than the fish (specific skills). No infrastructure to maintain.
**Cons:** Slower adoption. Requires ongoing teaching effort. Some teammates may want a more turnkey solution.

## Pre-Mortem: What Would Go Wrong?

Used structured pre-mortem analysis (via `the-fool` skill) to stress-test the approaches. Key failure narratives:

### Fork Graveyard (Option 4)

It's 6 months out. 6 people forked the repo. 2 actually used it for a week after deleting neb-specific skills. Then 3 significant skill improvements shipped — none of the forks pulled updates. The 4 people who forked but didn't customize hit confusing sibling references or got irrelevant suggestions from org-specific skills. They quietly stopped using it.

**Root cause:** The assumption that people will invest effort curating someone else's opinionated configuration. Fork-and-customize has high activation energy.

### Bundle Entropy (Options 1 & 2)

It's 6 months out. The bundle system works. Then a new skill fits both the `architecture` and `discipline` bundles. Bundle boundaries turn out to be inherently subjective. Meanwhile, `verification-before-completion` was refactored to reference `refactoring-guide` — now multiple bundles need shared dependencies. The "simple selective install" has become a dependency graph.

**Root cause:** Skills were designed as a flat, interconnected set. Imposing bundle boundaries on an interconnected graph creates artificial seams.

### Audience of One (All Options)

The skills are deeply opinionated — encoding specific methodology (Pragmatic Programmer principles, healthcare/HIPAA awareness, specific review checklists). Someone with a different debugging philosophy or working in a non-regulated industry finds them prescriptive. The universally useful skills (TDD, verification-before-completion) are simple enough to replicate in 10 minutes.

**Root cause:** The real value is the patterns and structure (how to write skills, how to organize them), not the specific skills themselves.

### Maintenance Tax (Options 1, 2 & 3)

It's 6 months out. Every skill iteration now requires asking "will this break someone else's setup?" Hesitating to rename, merge, or restructure skills because external users depend on the current structure. Iteration velocity — the quality that made these skills good — slows down.

**Root cause:** Sharing a personal tool with others converts it from a private experiment into a public commitment.

## Decision

**Workshop + Reference** (Option 5), for these reasons:

1. **The pain is context-switching, not tooling.** Teaching people to build their own setup addresses the root cause. Shipping them a bundle addresses a symptom.

2. **The highest-value shareable artifact is the system for building skills**, not the skills themselves. The `writing-skills` skill, the frontmatter conventions, the SessionStart hook, the dotfiles repo structure — that's what's novel and transferable.

3. **No maintenance tax.** The repo stays a personal tool with full iteration freedom. No implicit stability contract with external consumers.

4. **Plugin system remains available.** If distribution demand materializes after the workshop — people actively asking for a turnkey install — the plugin approach is a viable future option. But building it speculatively violates YAGNI.

## Positioning vs ptek-ai-playbook

These are complementary:

| | ptek-ai-playbook | dotfiles repo |
|---|---|---|
| **Direction** | Top-down | Bottom-up |
| **Scope** | Company-wide standardization | Personal workflow |
| **Compiled configs** | Per brand | Single setup |
| **Iteration speed** | Coordinated across teams | Immediate |
| **Best for** | Org-level consistency | Individual mastery |

Present both honestly. Some teammates will prefer the guardrails and structure of the playbook. Others will want the control of a personal setup. Both are valid. They can coexist — the playbook gives the org baseline, personal config layers preferences on top.

## Future Options

If workshop sessions generate demand for easier adoption:

1. **GitHub template repo** — One-click "generate from template" that strips org-specific skills
2. **Starter kit** — Minimal repo with SessionStart hook, `writing-skills`, and 2-3 example skills
3. **Plugin system** — Full distribution via `claude plugin install` if the audience grows beyond the team

None of these require structural changes now. The current repo is the right starting point for all three paths.
