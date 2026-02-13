---
Description: Review a pull request comprehensively using the analyzing-prs skill
Argument-hint: [PR number, URL, or empty for current branch]
Allowed-tools: Bash(gh *), Read, Glob, Grep
---

# Review PR

Review a pull request comprehensively using the analyzing-prs skill criteria.

## Arguments

- `$ARGUMENTS` - PR number, URL, or empty for current branch PR

## Workflow

### Setup Phase: Load Review Criteria

Use the Skill tool to load the `analyzing-prs` skill -- this contains the review categories and severity definitions you MUST apply.

### Step 1: Fetch PR Information

Use GitHub CLI to fetch PR details:

```bash
# Get PR details
gh pr view $ARGUMENTS --json title,body,author,files,additions,deletions,labels,reviews,isDraft,headRefName,baseRefName

# Get PR diff
gh pr diff $ARGUMENTS

# Get PR file list
gh pr view $ARGUMENTS --json files --jq '.files[].path'

# Get PR status checks
gh pr checks $ARGUMENTS
```

If `$ARGUMENTS` is empty, use `gh pr view` without arguments to get the current branch PR.

### Step 2: Analyze Changed Files

For each file in the PR:
1. **Read the file** using the Read tool to see final state
2. **Understand context** by reading related files (imports, dependencies, tests)
3. **Check git diff** to see what changed
4. **Cross-reference** with project docs (CLAUDE.md, README, architecture docs)

### Step 3: Apply Review Criteria

Apply the **analyzing-prs** skill criteria to evaluate all applicable categories:
- Architecture compliance
- Testing coverage
- Code quality
- Authentication & authorization
- Database & migrations
- API design
- Logging & observability
- Frontend changes (if applicable)
- Documentation
- Security
- Performance
- Dependencies

Skip categories that don't apply to the PR (e.g., skip Database if no schema changes).

### Step 4: Generate Review Report

Format the review using this template:

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

### Step 5: Submit Review (Optional)

Only if the user explicitly asks to submit:

```bash
# Add review comment
gh pr review $ARGUMENTS --comment -b "Review comment here"

# Request changes
gh pr review $ARGUMENTS --request-changes -b "Please address the issues found"

# Approve PR
gh pr review $ARGUMENTS --approve -b "LGTM!"
```

## Notes

- Provide constructive, specific feedback with file:line references
- Categorize issues by severity (Critical, Important, Minor)
- Include code examples for recommended fixes
- Acknowledge good patterns as well as issues
- Focus on "why" not just "what"
- Be respectful and encouraging in tone

$ARGUMENTS
