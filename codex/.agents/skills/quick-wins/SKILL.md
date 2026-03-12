---
name: quick-wins
description: ALWAYS invoke for scanning a repo for low-risk improvement opportunities without making changes. Triggers include "quick wins", "low-hanging fruit", "what can we improve", or "repo health check".
---

# Quick Wins

Research-only codebase scan for low-risk, high-value improvements. Study deeply, report clearly, change nothing.

## The Iron Law

**Report only. Never modify files.** Surface opportunities — don't act on them.

## Workflow

### 1. Orient

Read the repo's entry points to understand what you're working with:

- README, package.json / pyproject.toml / Cargo.toml (or equivalent)
- Language, framework, test runner, linter, build tool
- Directory structure and architecture style

### 2. Study

Go deep. Read key files — don't just grep for patterns.

| Category | What to Look For |
|----------|-----------------|
| Dead code | Unused exports, unreachable branches, commented-out code |
| Code smells | Empty catches, console.logs, silent failures, magic numbers, god functions |
| Type safety | `any` casts, missing types, loose generics, implicit `any` |
| TODO/FIXME | Stale items that look resolvable now |
| Dependency hygiene | Outdated deps, unused deps, duplicate deps |
| Config gaps | Loose compiler/linter settings, missing rules, inconsistent config |
| Test gaps | Untested public APIs, skipped tests, missing edge cases |
| Error handling | Swallowed errors, missing error boundaries, bare throws |

Adapt categories to the repo's language and ecosystem. Skip categories that don't apply.

### 3. Filter

Only report items that meet **all** of these:

- **Low risk** — fixing it won't break anything
- **Self-contained** — no architectural changes required
- **Verifiable** — tests exist, or the change is obviously safe

Include **medium risk** items only if effort is trivial (minutes).

### 4. Report

Present findings as a structured table, grouped by category:

```
| Category | Finding | File(s) | Risk | Effort |
|----------|---------|---------|------|--------|
| Dead code | `unusedHelper` exported but never imported | src/utils.ts:42 | Low | Minutes |
```

**Risk**: Low / Medium
**Effort**: Minutes / Hours / Days

After the table, add a **Top 7** ranked by value (highest impact, lowest effort first).

## Suggesting Follow-Up Skills

After presenting findings, suggest which skills would help execute the wins:

- Dead code / code smells → `code-renovator`
- Test gaps → `test-driven-development`
- Type safety / error handling → `systematic-debugging` (to understand current behavior first)
- Config gaps → direct fix (usually trivial)

## What Is NOT a Quick Win

- Architectural refactors
- New feature work
- Changes requiring migration plans
- Anything touching auth, payments, or data models without test coverage

## Constraints

### MUST DO
- Read actual source files — don't report based on grep hits alone
- Include file paths and line numbers for every finding
- Verify dead code is actually dead (check all import sites)
- Check if TODO/FIXME items reference resolved tickets before reporting

### MUST NOT DO
- Modify any files
- Create branches or commits
- Run destructive commands
- Report speculative issues without code evidence
