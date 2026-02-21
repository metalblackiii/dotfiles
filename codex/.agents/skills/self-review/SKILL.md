---
name: self-review
description: Use when running a pre-commit or pre-PR quality gate on local git changes only (no `gh`). Catches issues the implementer may have missed through fresh-eyes analysis of staged, unstaged, or branch diffs.
---

# Self-Review Skill

Fresh-eyes code review of local changes. You have NO context about why these changes were made — you see only the diff and the codebase. This is intentional. Your value is catching what the implementer missed due to familiarity bias.

This skill is local-only: use local `git` and filesystem inspection. Do **not** call `gh` in this workflow.

## Input

The user specifies what to review. Typical inputs:

- **Staged changes:** `git diff --staged`
- **Branch changes:** `git diff main...HEAD`
- **Unstaged changes:** `git diff`
- **Specific commits:** `git diff <ref>`

If unspecified, default to `git diff --staged`. If staged is empty, fall back to `git diff`.

## Workflow

### Step 1: Load Review Criteria

Read the `analyzing-prs` skill to load review categories, security deep-dive criteria, and severity definitions:

- `../analyzing-prs/SKILL.md`

Use relative paths from this skill's location (sibling directory). Read the file directly — do not use platform-specific skill invocation.

### Step 2: Scope & Complexity Check

Before line-level review, assess the diff as a whole:

- **Scope coherence** — Does this diff mix unrelated concerns (e.g., feature + unrelated refactor, payments + auth)? Flag as Important if so.
- **Size** — If the diff touches >10 files or >5 distinct directories, note the complexity and whether a split would improve reviewability.

### Step 3: Get the Diff

Run the specified git diff command. Parse the output to list all modified, added, and deleted files.

### Step 4: Read Changed Files

For each changed file, read the **full file** (not just the diff) to understand the context the changes live in. Also read closely related files (imports, interfaces, tests) as needed.

### Step 5: Apply Review Criteria

Use the `analyzing-prs` criteria. Only evaluate categories relevant to the changes — skip categories that don't apply.

Focus especially on things an implementer is likely to miss about their own code:
- Assumptions that aren't validated
- Error paths not handled
- Missing test coverage for new behavior
- Security implications of new inputs or endpoints
- Patterns that diverge from the rest of the codebase
- Resource cleanup (connections, listeners, streams)
- Edge cases (empty, null, boundary values)

### Step 6: Defensive Code Audit

In addition to the standard criteria, specifically scan for:

- **Empty catch blocks** — `catch (e) { }` or `catch { }` that silently swallow errors
- **Silent fallbacks** — `data || DEFAULT` patterns that mask missing data rather than surfacing it
- **Unchecked null/undefined** — property access without validation on values that could be absent
- **Ignored promise rejections** — async calls without `.catch()` or try/catch

These are high-value findings because they create bugs that are hard to diagnose later.

### Step 7: Report Findings

```markdown
## Self-Review: [1-line summary of what changed]

**Files reviewed:** [count] ([list])

### Critical (Must Fix)
- **[Issue]** — `file:line` — [What's wrong and why it matters]

### Important (Should Fix)
- **[Issue]** — `file:line` — [Description and recommendation]

### Minor (Consider)
- **[Issue]** — `file:line` — [Description]

### Looks Good
- [Positive observations — patterns followed, good test coverage, etc.]
```

Omit any severity section that has no findings.

## Anti-Hallucination Rules

**Verify before asserting.** Never claim "project uses pattern X" without checking. Before recommending a pattern or convention:

1. **Grep/Glob first** — confirm the pattern actually exists in the codebase
2. **Occurrence threshold** — >10 occurrences = established pattern (suggest aligning). <3 occurrences = not established (don't cite as convention)
3. **Read full file context** — don't judge from diff lines alone; surrounding code may explain the choice

If unsure about a convention, flag it as a question rather than a finding.

## Guidelines

- **Be concise.** This is a quick quality gate, not a full PR review essay.
- **Be specific.** File paths, line numbers, concrete issues. Never "consider improving error handling" — say which error, where, and what could go wrong.
- **Prioritize ruthlessly.** A few critical findings are more valuable than a long list of nitpicks.
- **Don't repeat what linters catch.** Focus on logic, architecture, security, and correctness — things tools can't find.
- **Acknowledge good work.** The "Looks Good" section builds trust and confirms you actually reviewed the code.
- **No false positives.** If you're unsure whether something is an issue, read more context before flagging it. Wrong findings erode trust fast.
