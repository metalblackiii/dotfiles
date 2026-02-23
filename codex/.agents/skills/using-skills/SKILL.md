---
name: using-skills
description: Establishes how to discover and use skills. Loaded at session start — not invoked directly.
---

# Using Skills

You have specialized skills installed. These represent personal development methodology and best practices.

## Discovery

**Use the platform's skill invocation to invoke skills (`Skill` tool in Claude Code, `$skill` in Codex).** The platform lists available skills in system-reminder messages — check there first. When you invoke a skill, its full content is loaded and presented to you. Follow it directly.

Prefer platform skill invocation over reading SKILL.md directly. Direct reading is allowed for meta-maintenance and audit tasks. Exception: if a parent skill explicitly instructs you to read a support skill by relative path (for example, `review`/`self-review` loading `analyzing-prs`), follow the parent skill's workflow.

## When to Check for Skills

**Non-trivial tasks** — features, debugging, architecture, reviews, deployments:
1. Check which skills apply (scan the available skills list)
2. Invoke the relevant skill(s) via platform skill invocation (`Skill` tool in Claude Code, `$skill` in Codex)
3. Follow the skill's guidance
4. THEN respond to the user

**Trivial tasks** — single-line fixes, typos, simple questions, file reads:
- Proceed directly. Skills add overhead here with no benefit.

## Sequencing

Skills compose naturally. Common sequences:

- **Bugfix:** `systematic-debugging` → `test-driven-development` → `verification-before-completion`
- **New feature:** `feature-forge` (or `analyzing-requirements`) → `test-driven-development` → `verification-before-completion`
- **Refactor:** `refactoring-guide` → `verification-before-completion`
- **PR review:** `review` or `self-review` (these consume `analyzing-prs` internally)

When multiple skills apply, invoke process skills first (debugging, planning), then implementation skills (domain-specific, testing).

## Red Flags

If you're thinking any of these, stop and check for skills:

- "Let me just..." → Is this actually trivial, or are you rationalizing?
- "This won't take long..." → Check for skills first.
- "I need to explore first..." → Skills guide exploration.
- "After I gather context..." → Skills guide context gathering.

## The Iron Law

Skills are not optional when applicable. Invoke first, work second. But don't invoke skills for work that genuinely doesn't benefit from them.
