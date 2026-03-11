---
name: review
description: Use when reviewing a GitHub pull request for architecture compliance, testing coverage, code quality, and baseline security checks. For dedicated security audits or deep security assessments, use `security-reviewer`. Requires working `gh` CLI auth/context. Accepts a PR number, URL, or empty for the current branch.
---

# PR Review Skill

Comprehensive pull request review using structured quality criteria.

## Synchronization Guardrail

This skill intentionally mirrors core review policy language from `self-review` without extracting shared scaffolding.

When editing this skill, check `../self-review/SKILL.md` and keep these aligned unless divergence is intentional and documented inline:
- `pr-analysis` as the criteria source (`../pr-analysis/SKILL.md`)
- Defensive Code Audit (empty catches, silent fallbacks, unchecked null, ignored rejections)
- Naming & readability scan (vague names, "what" comments, redundant comments)
- Severity taxonomy (`Critical`, `Important`, `Minor`)
- Shared quality posture (broad category coverage and evidence-based findings)

## Input

The user provides one of:
- A **PR number** (e.g., `123`)
- A **PR URL** (e.g., `https://github.com/org/repo/pull/123`)
- **Nothing** — review the PR for the current branch

## Workflow

### Step 1: Load Review Criteria

Read the `pr-analysis` skill to load baseline review categories, healthcare addendum checks, and severity definitions:

- `../pr-analysis/SKILL.md`

Use relative paths from this skill's location (sibling directory). Read the file directly — do not use platform-specific skill invocation.

### Step 2: Fetch PR Information

Use GitHub CLI to gather PR context:

```bash
# PR metadata
gh pr view <PR> --json title,body,author,files,additions,deletions,labels,reviews,isDraft,headRefName,baseRefName

# Full diff
gh pr diff <PR>

# File list
gh pr view <PR> --json files --jq '.files[].path'

# CI status
gh pr checks <PR>
```

If no PR identifier was given, omit the `<PR>` argument — `gh pr view` defaults to the current branch.

**Failure policy:** If any required `gh` command fails (auth failure, network error, missing PR context, or CLI error), stop immediately and report the failure. Do **not** fall back to local `git diff` review under this skill.

### Step 3: Analyze Changed Files

For each changed file:
1. **Read the full file** to see final state and surrounding context
2. **Read related files** — imports, interfaces, tests, configs
3. **Cross-reference** with project docs (CLAUDE.md, README, architecture docs)

### Step 4: Apply Review Criteria

Apply every applicable category from the `pr-analysis` skill:
- Architecture compliance
- Testing coverage
- Code quality
- Authentication & authorization
- Database & migrations
- API design
- Logging & observability
- Frontend changes
- Documentation
- Security
- Performance
- Dependencies

Skip categories that don't apply to the PR (e.g., skip Database if no schema changes).

### Step 5: Defensive Code Audit

In addition to the standard criteria, specifically scan for:

- **Empty catch blocks** — `catch (e) { }` or `catch { }` that silently swallow errors
- **Silent fallbacks** — `data || DEFAULT` patterns that mask missing data rather than surfacing it
- **Unchecked null/undefined** — property access without validation on values that could be absent
- **Ignored promise rejections** — async calls without `.catch()` or try/catch

These are high-value findings because they create bugs that are hard to diagnose later.

### Security Escalation (When Needed)

`review` includes baseline security checks via `pr-analysis`. Escalate to `security-reviewer` only when:
- the user explicitly requests a security audit/deep-dive, or
- the PR changes high-risk surfaces (auth, permissions, secrets, PHI handling, tenant isolation, exposed infrastructure config).

### Step 6: Naming & Readability Scan

Scan changed code for:

- **Vague names** — `data`, `result`, `temp`, `handle*`, `process*`, `manager`, `helper`, `utils` without specific intent
- **"What" comments** — comments that narrate code (`// Loop through users`) instead of explaining why; these should be naming improvements
- **Redundant comments** — comments that repeat the code (`// Return the result`, `// Set name`)

Flag naming issues as Minor unless they create genuine ambiguity (Important).

### Step 7: Generate Review Report

```markdown
# Pull Request Review: [PR Title]

**PR Number**: #[number]
**Author**: @[username]
**Branch**: `[head]` -> `[base]`
**Files Changed**: [X] files (+[additions], -[deletions] lines)
**Status**: [Draft | Ready for Review | Changes Requested | Approved]

---

## Summary

### What This PR Does
[2-3 sentence summary of the changes and their purpose]

### Changed Components
- **[Layer]**: [List files changed]

---

## Strengths

1. **[Category]**: [Specific positive observation]
   - File: `file.ext:line`

---

## Issues Found

### Critical (Must Fix Before Merge)

#### 1. [Issue Title]
- **Category**: [Architecture | Security | Testing | etc.]
- **Location**: `path/to/file.ext:line`
- **Issue**: [Detailed description]
- **Impact**: [Why this is critical]
- **Recommendation**: [Specific fix with code example]

### Important (Should Fix)

#### 1. [Issue Title]
- **Category**: [Category]
- **Location**: `path/to/file.ext:line`
- **Issue**: [Description]
- **Recommendation**: [Fix]

### Minor (Nice to Have)

#### 1. [Issue Title]
- **Category**: [Category]
- **Location**: `path/to/file.ext:line`
- **Issue**: [Description]
- **Recommendation**: [Fix]

---

## Test Coverage Analysis

### Tests Added/Modified
- [List test files with status]

### Coverage Gaps
- [Missing test scenarios]

---

## Recommendations Summary

### Before Merge (Required)
1. [Critical issue fix]

### After Merge (Nice to Have)
1. [Minor improvement]

---

## Verdict

**[Changes Requested | Approved with Suggestions | Approved]**

**Reasoning**: [1-2 sentence summary]
```

Omit any severity section that has no findings.

### Step 8: Submit Review (Only When Asked)

Only if the user explicitly asks to submit the review to GitHub.

#### 8.1 Comment Placement Policy (Iron Rule)

**Inline comments are the default for all code feedback. `gh pr review --comment` is almost never the right tool.**

When the user asks to "leave comments" or "submit review":

- **Every finding that has a file:line anchor MUST be an inline review comment** — use `gh api` with the `comments` array. This includes criticals, importants, minors, and suggestions. If you can point to a line, it goes inline.
- **Top-level review body only** for feedback that genuinely has no code anchor — e.g., "I can't review this without more context on the approach" or a one-sentence overall verdict. This is rare.
- If you have both, submit a single `COMMENTED` review with inline comments and a minimal top-level body. Do not duplicate inline content in the top-level body.
- **Never use `gh pr review --comment`** for findings. It posts to the Conversation tab only and loses the file/line context entirely. Only use it if explicitly asked for a conversation-only comment.

Submitted reviews cannot be deleted. Get it right the first time.

#### 8.2 Command Decision Table

| Intent | Command pattern |
|---|---|
| Inline comments (default for all findings) | `gh api -X POST repos/<org>/<repo>/pulls/<PR>/reviews --input <json>` |
| Approve | `gh pr review <PR> --approve --body-file <file>` |
| Request changes | `gh pr review <PR> --request-changes --body-file <file>` |
| Conversation-only comment (rare, explicit request only) | `gh pr review <PR> --comment --body-file <file>` |

#### 8.3 Inline Review Payload Template

Use for code-anchored comments in `Files changed`:

```json
{
  "commit_id": "<head-sha>",
  "event": "COMMENT",
  "body": "Optional top-level summary",
  "comments": [
    {
      "path": "src/file.js",
      "line": 123,
      "side": "RIGHT",
      "body": "Inline feedback"
    }
  ]
}
```

Get `head-sha` from:

```bash
gh pr view <PR> --json headRefOid --jq .headRefOid
```

Then submit:

```bash
gh api -X POST repos/<org>/<repo>/pulls/<PR>/reviews --input review.json
```

Never submit without explicit user request.

## Anti-Hallucination Rules

**Verify before asserting.** Never claim "project uses pattern X" without checking. Before recommending a pattern or convention:

1. **Use `gh` + file inspection first** — confirm the pattern in changed files and relevant repository context, not only PR text.
2. **Occurrence threshold** — >10 occurrences = established pattern (suggest aligning). <3 occurrences = not established (don't cite as convention).
3. **Read full file context** — don't judge from diff lines alone; surrounding code may explain the choice.

If unsure about a convention, flag it as a question rather than a finding.

## Guidelines

- Provide constructive, specific feedback with `file:line` references
- Categorize issues by severity (Critical, Important, Minor)
- Include code examples for recommended fixes
- Acknowledge good patterns as well as issues
- Focus on "why" not just "what"
- Be respectful and encouraging in tone
- Don't repeat what linters catch — focus on logic, architecture, security, and correctness
