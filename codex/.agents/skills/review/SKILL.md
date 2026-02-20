---
name: review
description: Use when reviewing a GitHub pull request for architecture compliance, testing coverage, code quality, security vulnerabilities, and other quality criteria. Requires working `gh` CLI auth/context. Accepts a PR number, URL, or empty for the current branch.
---

# PR Review Skill

Comprehensive pull request review using structured quality criteria.

## Input

The user provides one of:
- A **PR number** (e.g., `123`)
- A **PR URL** (e.g., `https://github.com/org/repo/pull/123`)
- **Nothing** — review the PR for the current branch

## Workflow

### Step 1: Load Review Criteria

Read the `analyzing-prs` skill and its references to load review categories and severity definitions. These files are co-located in the skills directory:

- `analyzing-prs/SKILL.md` — review categories, severity definitions, anti-patterns
- `analyzing-prs/references/security-deep-dive.md` — load when PR touches auth, patient data, audit logging, encryption, or entitlements

Use relative paths from this skill's location (sibling directory). Read these files directly — do not use platform-specific skill invocation.

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

Apply every applicable category from the `analyzing-prs` skill:
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

### Step 5: Generate Review Report

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

### Step 6: Submit Review (Only When Asked)

Only if the user explicitly asks to submit the review to GitHub:

```bash
# Comment
gh pr review <PR> --comment -b "Review body here"

# Request changes
gh pr review <PR> --request-changes -b "Please address the issues found"

# Approve
gh pr review <PR> --approve -b "LGTM!"
```

Never submit without explicit user request.

## Guidelines

- Provide constructive, specific feedback with `file:line` references
- Categorize issues by severity (Critical, Important, Minor)
- Include code examples for recommended fixes
- Acknowledge good patterns as well as issues
- Focus on "why" not just "what"
- Be respectful and encouraging in tone
- Don't repeat what linters catch — focus on logic, architecture, security, and correctness
