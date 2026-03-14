# Sharing Agent Skills — Introduction

A companion guide for teammates exploring this repo for the first time. See [README.md](README.md) for installation, structure, and platform-specific details.

## Why Personal Config Matters

Every time you switch between Claude Code and Codex, you lose context. Not just the technical context in the conversation window — the muscle memory of *how you work*. Which skill to invoke, what conventions your team follows, what patterns your codebase uses.

A personal agent configuration solves this by encoding your workflow once and applying it everywhere. Instead of re-explaining "we use conventional commits" or "always check for applicable skills first" in every session, the agent already knows. The friction disappears and you spend your time on the actual problem.

## How This Relates to ptek-ai-playbook

These are complementary, not competing:

| | ptek-ai-playbook | This dotfiles repo |
|---|---|---|
| **Direction** | Top-down | Bottom-up |
| **Scope** | Company-wide standardization | Personal workflow |
| **Compiled configs** | Per brand (ChiroTouch, ChiroSpring360) | Single setup, your preferences |
| **Iteration speed** | Coordinated across teams | Change it, test it, done |
| **Best for** | Org-level consistency, onboarding | Individual mastery, rapid experimentation |

Neither is better. Some teammates will prefer the guardrails of the playbook — it tells you exactly what to do and compiles per-brand configs for you. Others will want the control of a personal setup where every skill and convention is one you chose deliberately.

You can use both. The playbook gives you the org baseline; your personal config layers your own preferences and domain-specific skills on top.

## Skill Anatomy

Skills are the core of this setup. They live in `codex/.agents/skills/<name>/SKILL.md` — Codex owns the canonical copy, and other platforms (like Claude Code) access them via symlinks. This means you write each skill once and it works everywhere.

Every skill follows this structure:

```yaml
---
name: skill-name
description: When the agent should activate this skill
---
```

The **frontmatter** is what the agent reads to decide when a skill applies. The description is a trigger — it tells the agent "use this skill when you encounter X." Getting this right matters more than the skill body, because a skill that never activates is a skill that doesn't exist.

Below the frontmatter is the skill body: the actual guidance, patterns, examples, and constraints. Some skills also have a `references/` directory with deeper material the agent loads on demand.

### Sibling Dependencies

Skills can reference each other. The `review` and `self-review` skills both consume `pr-analysis` internally. This keeps skills focused — each one does one thing well and delegates the rest.

## Review Workflow in Practice

This is how a typical code review session looks when the skills are wired up. It ties together several skills from the [Review Bundle](#2-review-bundle) into a repeatable flow.

### 1. PR Review (Remote)

Start with `/review <PR-url>`. This invokes the [`review`](codex/.agents/skills/review/SKILL.md) skill, which internally loads [`pr-analysis`](codex/.agents/skills/pr-analysis/) for consistent review criteria. You get a structured baseline covering architecture, tests, quality, and security.

From there, go back and forth with the agent — challenge assumptions, ask whether something is greenfield or incremental, probe how important a finding really is. The baseline is a starting point, not a verdict.

### 2. Domain-Specific Passes

If the PR touches database logic (schema changes, complex queries, index impact), ask the agent to run the [`database-expert`](codex/.agents/skills/database-expert/) skill as a follow-up pass. This surfaces optimization and correctness issues that a general review misses.

The same idea applies to any domain skill — `api-designer` for contract changes, `neb-playwright-expert` for E2E test changes. Stack domain passes on top of the general review when the diff warrants it.

### 3. Local Self-Review (Before Commit)

For your own code, open a shell in the same directory as your git changes and run `/self-review`. This uses the [`self-review`](codex/.agents/skills/self-review/SKILL.md) skill, which reviews your local diffs without needing `gh` or a remote PR. It shares the same `pr-analysis` criteria as the full review, so the bar is consistent.

Self-review works best as a pre-commit gate — catch issues before they leave your machine rather than after a teammate flags them.

### Platform Note

Both Claude Code and Codex can run this workflow. The skills are shared via symlinks, so the same guidance runs on either platform. Invocation syntax differs: Claude Code uses `/review` and `/self-review`, while Codex uses `$review` and `$self-review`. (`/review` also works in Codex since it's registered as a command there.) Claude Code tends to produce slightly more detailed output; Codex is faster for batch work. Use whichever fits the moment.

## Why Skills Improve Agent Performance

### Progressive Disclosure Beats Prompt Bloat

Large always-on instruction files eventually become self-defeating. As global context grows, the agent has to carry more irrelevant material on every request, which can degrade focus and output quality.

The skills system solves this through **progressive disclosure**:
- Keep always-on instructions short and invariant (safety rules, git policy, quality bar)
- Move situational workflows into skills with strong trigger descriptions
- Load deeper references only when the active skill needs them

This keeps the default context lean while still making specialized guidance available exactly when relevant.

If you want more background on why this matters, see: [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md).

### A Practical Split That Works

Use this three-layer model:
1. **Global instructions**: stable rules that should apply in nearly every session
2. **Skills**: reusable workflows that activate for specific task types
3. **Skill references**: deep domain material loaded on demand

### Failure Modes to Avoid

- Putting every preference into always-on instructions
- Creating many near-duplicate skills with overlapping triggers
- Writing vague frontmatter descriptions that never reliably activate

## Key Patterns Worth Adopting

### Skills-First Workflow

In Codex, the `developer_instructions` field in `config.toml` runs on every session. Treat this as your always-on hook: it's where you enforce "check for applicable skills before non-trivial work." This is "The Iron Law" — skills activate before work begins, not as an afterthought. Claude Code achieves similar behavior via a SessionStart hook.

Even if you don't adopt the full skill set, adding a skills-first reminder to your agent's always-on instructions is high-value with low effort.

### ATTRIBUTION.md Culture

When you adapt someone's skill, credit them. When someone adapts yours, they credit you. The `ATTRIBUTION.md` file tracks where skills came from. This creates a healthy sharing ecosystem where people feel safe publishing their work because they know they'll get credit.

## Recommended Skill Bundles

These are **adoption bundles**, not install-time bundles or enforced directory structure.
Descriptions are copied from each skill's frontmatter and lightly shortened for readability.

### 1) Discipline Bundle (start here)

Inspired by [obra/superpowers](https://github.com/obra/superpowers), this bundle gives the highest leverage for daily reliability:

- `test-driven-development` — Non-trivial feature/bugfix work where tests should drive design.
- `systematic-debugging` — Bugs with non-obvious root cause; structured debugging before proposing fixes.
- `verification-before-completion` — Run evidence-based checks before claiming work is complete or passing.
- `using-skills` — Session-start discovery/invocation workflow for applicable skills.

### 2) Review Bundle

This bundle tightens quality gates before code reaches teammates. See [Review Workflow in Practice](#review-workflow-in-practice) for how these skills fit together in a typical session.

- `review` — Full GitHub PR review for architecture, tests, quality, and security.
- `self-review` — Fresh-eyes local diff review before commit/PR, no `gh` required.
- `pr-analysis` — Shared review checklist criteria consumed by `review` and `self-review`.
### 3) Meta Bundle

These skills help you improve the system itself:

- `writing-skills` — Create/edit SKILL.md files and frontmatter conventions.
- `introspect` — Audit agent configuration for conflicts, redundancy, and stale guidance.
- `audit-skills` — Measure skill adoption and find dormant skills.

### 4) Niche Skills (Low-Cost One-Offs)

Useful when the situation appears, with little ongoing overhead:

- `handoff` — Capture session state when pausing or when context pressure is high.
- `the-fool` — Structured critical reasoning: devil's advocate, pre-mortems, red teams, assumption auditing. Invoke it before committing to a design or plan — it's surprisingly effective at surfacing blind spots you're too close to see.

### 5) Domain Skills (If It's Important to You)

Domain-heavy skills are worth adopting when they match your recurring work:

- `database-expert` — SQL, schema design, query optimization, indexes, and Aurora/ORM patterns.
- `api-designer` — REST contracts, versioning strategy, and API evolution planning.
- `neb-playwright-expert` — E2E test design/debugging for neb-www's Playwright setup.

For more domain-specific ideas, see the `jeffallan/claude-skills` source listed in `ATTRIBUTION.md`.

### 6) Optional Security Bundle (Escalation Lane)

Treat security as an opt-in escalation lane, not baseline complexity:

- `security-reviewer` — Use for dedicated security audits or high-risk change sets. Keep this out of everyday review unless explicitly needed.
- `secure-code-guardian` — Use when implementing or remediating security controls in code.

This bundle does **not** require extra tooling to adopt. Teams can run in manual mode first (threat-focused code review + remediation guidance), then add scanner tooling later if they want deeper automation.

### 7) Snyk Security Bundle (Tooling-Backed)

For teams that use Snyk CLI for vulnerability scanning:

- `snyk-scan` — Scan repos for security vulnerabilities in dependencies, source code, and container images, then apply fixes.
- `snyk-expert` — Interpret scan results, prioritize CVEs/CWEs, evaluate upgrade risk, and decide whether to fix, ignore, or accept a vulnerability.

`snyk-scan` runs the scans and applies fixes; `snyk-expert` advises on the results. Use them together or independently. Requires Snyk CLI to be installed and authenticated.

---

These bundles are **curated highlights**, not an exhaustive list. The repo contains 43 skills including generators, validators, and niche domain tools. Browse `codex/.agents/skills/` for the full set.

## What This Repo Does Not Cover

This repo focuses on portable instructions + skills + symlinked platform config. Some adjacent approaches are partially covered or out of scope:

- **MCP servers**: Model Context Protocol integrations for external tools and data sources. Useful, but not configured in this repo yet.
- **Agentic programming / agent teams**: Partially covered. One Claude Code command exists today:
  - `/co-research` — Dispatches parallel research agents and Codex, then synthesizes findings.

  The standalone [`prd-loop` CLI](https://github.com/metalblackiii/prd-loop) handles phased PRD implementation (previously `/prd-loop` and `/co-implement` commands). Codex also runs with `multi_agent = true`. Full multi-agent orchestration patterns are evolving but not yet fully codified as reusable skills.
- **Loop programming**: Autonomous iterative loops for planning/execution/reflection workflows (for example, [awesome-ralph](https://github.com/snwfdhmp/awesome-ralph)). The `prd-loop` CLI is a step in this direction.

These approaches complement the baseline. As patterns stabilize, they may graduate into proper skills.

## How to Start Your Own

### Option A: Fork and Customize

1. Fork this repo
2. Run `./install-ai.sh` to get the symlinks in place
3. Delete skills you don't need
4. Modify remaining skills to match your preferences
5. Add your own domain-specific skills

Update the values in the [Customization](README.md#customization) section of the README — reviewer teams, repo paths, etc.

### Option B: Start from Scratch

1. Create a new repo with the same structure
2. Use the `writing-skills` skill to guide you through creating your first SKILL.md
3. Add a skills-first reminder to your agent config (`developer_instructions` in Codex, SessionStart hook in Claude Code)
4. Build up gradually — add skills as you find yourself repeating the same guidance

Starting from scratch is more work up front but gives you a setup that's entirely yours. No dead skills, no conventions that don't match your workflow.

### Either Way

- Keep it in a Git repo with symlinks to the platform config directories
- Iterate frequently — a skill you wrote last month might need updating
- Don't over-engineer it — a skill with three bullet points that you actually use beats a comprehensive guide that you forget exists

## Share Back

The best part of personal configs is learning from each other. If you build a skill that works well:

- Show it at a recurring session (even 15 minutes is enough)
- Credit your sources in ATTRIBUTION.md
- Don't worry about polish — real, battle-tested skills are more valuable than perfect ones

The `writing-skills` skill in this repo can help you structure new skills with proper frontmatter, descriptions, and reference patterns.
