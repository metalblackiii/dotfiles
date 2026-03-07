---
name: using-skills
description: Establishes how to discover and use skills. Loaded at session start — not invoked directly.
disable-model-invocation: true
---

# Using Skills

You have specialized skills installed. These represent personal development methodology and best practices.

## Discovery

**Use the platform's skill invocation to invoke skills (`Skill` tool in Claude Code, `$skill` in Codex).** The platform lists available skills in system-reminder messages — check there first. When you invoke a skill, its full content is loaded and presented to you. Follow it directly.

Prefer platform skill invocation over reading SKILL.md directly. Direct reading is allowed for meta-maintenance and audit tasks. Exception: if a parent skill explicitly instructs you to read a support skill by relative path (for example, `review`/`self-review` loading `pr-analysis`), follow the parent skill's workflow.

## When to Check for Skills

**Before every task**, scan the available skills list. If any skill's description matches the request, invoke it — even if you believe you can answer without it. The skill exists because the unassisted answer isn't good enough.

1. Scan descriptions for a match
2. Invoke the matching skill(s) via platform skill invocation (`Skill` tool in Claude Code, `$skill` in Codex)
3. Follow the skill's guidance
4. THEN respond to the user

**Skip skills only for pure mechanical edits** — single-line typo fixes, variable renames, file reads with no judgment involved. If you're producing an answer that requires domain knowledge, check for skills first.

## Sequencing

Skills compose naturally. Common sequences:

- **Bugfix:** `systematic-debugging` → `test-driven-development` → `verification-before-completion`
- **New feature:** `feature-forge` (or `requirements-analyst`) → `test-driven-development` → `verification-before-completion`
- **Refactor:** `code-renovator` → `verification-before-completion`
- **PR review:** `review` or `self-review` (these consume `pr-analysis` internally)
- **Security-sensitive implementation:** `feature-forge` (or `requirements-analyst`) → `secure-code-guardian` → `test-driven-development` → `verification-before-completion`
- **Security deep-dive:** `review` or `self-review` → `security-reviewer` (only when explicitly requested or when high-risk surfaces changed)
- **Quick wins:** `quick-wins` → `code-renovator` / `test-driven-development` (to act on findings)
- **Multi-repo batch:** `batch-repo-ops` → `verification-before-completion`
- **End of session:** `handoff` (if WIP remains)

When multiple skills apply, invoke process skills first (debugging, planning), then implementation skills (domain-specific, testing).

## Overlap Precedence

To avoid trigger collisions:

1. If the user asks for "review", default to `review` or `self-review`.
2. Use `security-reviewer` only for explicit security audits or deep security assessments.
3. Use `secure-code-guardian` for implementing or remediating security controls in code.
4. Use `self-documenting-code` for naming/readability in code, not documentation artifact generation.
5. Use `handoff` to preserve WIP for the next session.
6. Use `playwright-cli` for interactive browser automation (navigation, forms, scraping). Use `neb-playwright-expert` only for writing Playwright test files in neb-www.
7. Use `snyk-scan` for running scans and applying fixes. Use `snyk-expert` for interpreting results, advisory, and configuration questions.
8. Use `batch-repo-ops` for applying the same operation across multiple repos. Use `co-implement` for single-repo delegation to Codex. Use `co-research` for multi-repo research/survey (not changes).

## Red Flags

If you're thinking any of these, stop and check for skills:

- "Let me just..." → Is this actually trivial, or are you rationalizing?
- "This won't take long..." → Check for skills first.
- "I need to explore first..." → Skills guide exploration.
- "After I gather context..." → Skills guide context gathering.

## The Iron Law

Skills are not optional when a description matches. Invoke first, work second. "I already know how to do this" is not a reason to skip a skill — the skill contains project-specific standards, not just general knowledge.
