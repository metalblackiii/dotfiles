---
name: auto-review
description: Automated PR review with domain-expert panel, batch comment approval, and 30-minute re-review loop. Invoke with /auto-review <PR-URL>. Use --once for single-shot. Not for multi-PR batches or local code review.
disable-model-invocation: true
argument-hint: <PR-URL> [--once]
---

# Auto-Review

Automated PR review pipeline. Surface issues without blocking development, provide faster feedback via re-review loops, and raise quality with domain-expert panels.

The human is the approver, not the operator — every batch of comments requires explicit approval before posting.

## Synchronization Guardrail

This skill inherits all review standards from `pr-analysis`. It defines no independent review criteria.

When editing, keep aligned with `../review/SKILL.md` and `../self-review/SKILL.md` on:
- `pr-analysis` as the criteria source (`../pr-analysis/SKILL.md`)
- Defensive Code Audit (empty catches, silent fallbacks, unchecked null, ignored rejections)
- Naming & readability scan (vague names, "what" comments, redundant comments)
- Severity taxonomy (`Critical`, `Important`, `Minor`)
- Inline comment submission via `gh api` (iron rule)

## Input

The user provides:
- A **PR URL** (e.g., `https://github.com/org/repo/pull/123`) or **PR number** (e.g., `123`)
- Optional: `--once` flag for single review without re-review loop

Default behavior (no `--once`): initial review with expert panel, then 30-minute re-review loop.

Parse `org` and `repo` from the URL. If a bare number is given, resolve from the current repo via `gh repo view --json nameWithOwner -q .nameWithOwner`.

## Phase 1: Initial Review

### Step 1: Load Review Criteria

Read `../pr-analysis/SKILL.md` using relative path from this skill's location. This provides the 12 review categories, healthcare addendum, and severity taxonomy.

### Step 2: Fetch PR Information

Use `-R org/repo` on all `gh` commands — never rely on cwd.

```bash
# PR metadata
gh pr view <PR> -R org/repo --json title,body,author,files,additions,deletions,labels,reviews,isDraft,headRefName,baseRefName,headRefOid

# Full diff
gh pr diff <PR> -R org/repo

# File list (for expert selection)
gh pr view <PR> -R org/repo --json files --jq '.files[].path'

# CI status
gh pr checks <PR> -R org/repo
```

**Failure policy:** If any required `gh` command fails, stop and report the failure. Do not fall back to local `git diff`.

### Step 3: Standard Analysis

For each changed file:
1. Read the full file for final state and surrounding context
2. Read related files — imports, interfaces, tests, configs
3. Apply every applicable category from `pr-analysis`
4. Run the Defensive Code Audit (empty catches, silent fallbacks, unchecked null, ignored promise rejections)
5. Run the Naming & Readability Scan (vague names, "what" comments, redundant comments)

### Step 4: Expert Panel Dispatch

Read `references/expert-dispatch.md` for the full expert selection heuristic and subagent prompt template.

Expert subagents use `model: "sonnet"` to avoid inheriting an expensive parent model for review work.

**Summary of the dispatch flow:**
1. Match changed file paths against the expert heuristic table
2. For each matched expert domain, read the corresponding domain skill's SKILL.md
3. Dispatch all matched experts as parallel subagents (platform-specific — see `references/expert-dispatch.md`)
4. Each subagent receives: relevant portion of the diff, domain skill knowledge, `pr-analysis` criteria for their category, and instructions to return structured JSON findings
5. If no patterns match, skip expert dispatch — standard analysis is sufficient

### Step 5: Synthesize Findings

When all expert subagents return:

1. **Collect** findings from standard analysis (Step 3) and all expert subagents
2. **Deduplicate**: Same file + overlapping line range (within 3 lines) + same issue category = one finding. Keep the more specific version (longer evidence, more precise recommendation).
3. **Classify** by severity: Critical, Important, Minor
4. **Assign IDs**: `f-1`, `f-2`, ... for metrics tracking

### Step 6: Batch Summary

Present the complete review to the user before posting anything:

```
=== Auto-Review: [PR Title] (#[number]) ===
Author: @[username]
Branch: [head] -> [base]
Files:  [X] files (+[additions], -[deletions])
Experts dispatched: [list or "none"]

Verdict: [REQUEST_CHANGES | COMMENT | APPROVE]

--- Critical ([N]) ---
[f-1] [Title] — [file:line]
      [One-line description]

--- Important ([N]) ---
[f-2] [Title] — [file:line]
      [One-line description]

--- Minor ([N]) ---
[f-3] [Title] — [file:line]
      [One-line description]

--- Looks Good ---
[Positive observations]

Post this review? (approve / reject / edit)
```

Wait for explicit user approval. If rejected, ask what to change. If edited, adjust findings and re-present.

### Step 7: Submit Review

On approval, post via `gh api`. See the Comment Submission section below for the exact payload.

### Step 8: Emit Metrics

Append a JSON record to `~/.auto-review-metrics.jsonl`. See Metrics Schema below.

## Phase 2: Re-Review Loop

Skip this phase entirely if `--once` was specified.

### Entry

After Phase 1 completes (review posted), inform the user:

```
Re-review loop active. Checking for new commits every 30 minutes.
PR will be monitored until approved or merged. Ctrl+C to stop.
```

### Cycle

Each cycle:

1. **Wait**: Sleep 30 minutes. Platform-specific:
   - **Claude Code**: `sleep 1800` via Bash with `run_in_background: true`
   - **Codex**: `sleep 1800` via shell (blocks the session — this is expected for a monitoring loop)
2. **Check PR status**:
   ```bash
   gh pr view <PR> -R org/repo --json state,reviews,commits
   ```
   From the JSON response, extract: `state`, each review's `author.login`, `state` (APPROVED/CHANGES_REQUESTED/etc), and `submittedAt`, and the latest commit OID.
3. **Evaluate**:
   - PR merged or closed → exit loop with message
   - PR has an APPROVED review from someone other than this session's GitHub user, AND no new commits after that approval's `submittedAt` → exit loop with message
   - No new commits since last review → skip cycle, log "no changes"
   - New commits detected → proceed to delta review (even if PR was previously approved — new pushes after approval need review)
4. **Load prior findings**: Read the last record from `~/.auto-review-metrics.jsonl` for this PR URL. This provides the finding IDs (`f-1`, `f-2`, ...) and their locations from the previous cycle.
5. **Delta review**: Run standard analysis only (Steps 3 + 5 from Phase 1, no expert panel). Focus on changed files in new commits.
6. **Fetch existing comments**: Retrieve previously posted review comments via `gh api`:
   ```bash
   gh api repos/org/repo/pulls/<PR>/comments
   ```
   Note: `gh api` does not support `-R`. The org/repo are embedded in the URL path. Parse `<!-- auto-review:f-N -->` markers from comment bodies to map back to finding IDs from the metrics log.
7. **Deduplicate against existing**: Compare new findings against already-posted comments. If a finding matches an existing unresolved comment (same file + overlapping lines + same category), suppress it.
8. **Track resolutions**: For each finding ID from the prior metrics record, check if the corresponding posted comment's code location is addressed by the new commits. Mark as `resolved` or `still-open` in metrics.
9. **Present batch**: Same format as Phase 1 Step 6, but prefixed with:
   ```
   === Re-Review (cycle [N]) ===
   New commits: [count] since last review
   Previously resolved: [list of f-IDs]
   ```
10. **Submit and emit metrics** on approval.

### Termination

The loop exits when:
- PR state is `MERGED` or `CLOSED`
- PR has an approval from a different reviewer (not this auto-review session) AND no new commits since that approval
- User interrupts (Ctrl+C)

The auto-review's own APPROVE verdict does not terminate the loop — the dev may push more commits after approval, and those need re-review.

## Verdict Logic

| Findings | Verdict | GitHub Event | Comment Tone |
|---|---|---|---|
| 1+ Critical | Request Changes | `REQUEST_CHANGES` | Direct, actionable |
| 1+ Important (no Critical) | Inline Comment | `COMMENT` | Clear but not blocking |
| No Critical/Important | Approve | `APPROVE` | Soft suggestions ("consider", "up to you", "for a follow-up") |

The verdict is computed automatically from findings but displayed in the batch summary for user review before posting.

## Comment Submission (Iron Rule)

All code-anchored findings are posted as inline review comments via `gh api`. Never use `gh pr review --comment`.

### Payload Template

```json
{
  "commit_id": "<head-sha>",
  "event": "<APPROVE|COMMENT|REQUEST_CHANGES>",
  "body": "Auto-review summary (N findings: X critical, Y important, Z minor)",
  "comments": [
    {
      "path": "src/file.js",
      "line": 123,
      "side": "RIGHT",
      "body": "**[Important]** Finding title\n\nDescription and recommendation."
    }
  ]
}
```

Get `head-sha` from the PR metadata fetched in Step 2 (`headRefOid` field).

```bash
gh api -X POST repos/org/repo/pulls/<PR>/reviews --input review.json
```

### Comment Formatting

Each inline comment body embeds a hidden finding ID for cross-cycle traceability, followed by the visible content:

- **Critical**: `<!-- auto-review:f-1 -->\n**[Critical]** Title\n\nIssue description.\n\n**Impact:** Why this matters.\n\n**Fix:** Specific recommendation with code example.`
- **Important**: `<!-- auto-review:f-2 -->\n**[Important]** Title\n\nIssue description.\n\n**Recommendation:** Specific fix.`
- **Minor** (on APPROVE): `<!-- auto-review:f-3 -->\n**[Suggestion]** Title\n\nConsider [recommendation]. Up to you — not blocking.`

The `<!-- auto-review:f-N -->` HTML comment is invisible on GitHub but lets re-review cycles map posted comments back to finding IDs in the metrics log.

### Findings Without Line Anchors

If a finding has no specific file:line (rare — e.g., "missing test file entirely"), include it in the top-level `body` of the review, not as an inline comment.

## Anti-Hallucination Rules

Adapted from `review`:
1. Verify patterns in the codebase before recommending — don't assume conventions.
2. >10 occurrences = established pattern. <3 occurrences = not established.
3. Read full file context — don't judge from diff lines alone.
4. If unsure about a convention, flag it as a question, not a finding.

## Metrics Schema

Each review cycle appends one JSON line to `~/.auto-review-metrics.jsonl`:

```json
{
  "pr_url": "https://github.com/org/repo/pull/123",
  "timestamp": "2026-03-14T10:30:00Z",
  "mode": "initial",
  "verdict": "COMMENT",
  "experts_dispatched": ["database", "security"],
  "findings": [
    {
      "id": "f-1",
      "severity": "Important",
      "title": "Missing index on frequently queried column",
      "location": "migrations/20260314-add-table.sql:15",
      "category": "Database",
      "status": "new"
    }
  ],
  "counts": { "critical": 0, "important": 1, "minor": 3 },
  "resolved_from_previous": [],
  "cycle_duration_seconds": 180
}
```

For re-review cycles, `mode` is `"re-review"` and `resolved_from_previous` contains IDs of findings from earlier cycles that are now fixed.

**Metrics hygiene:** No diff content, code snippets, or PHI/PII. Structured references only (file:line, finding title, severity).

## Constraints

- **Criteria alignment**: Consume `pr-analysis/SKILL.md` as the single source of review criteria. Never define independent review standards.
- **Iron rule**: All code-anchored findings posted as inline comments via `gh api`. Never `gh pr review --comment` for findings.
- **No git operations**: This is a `gh`-only command. Never fall back to local `git diff`.
- **Human gate**: Every batch requires explicit user approval before posting. Never auto-post.
- **-R everywhere**: Always use `-R org/repo` on `gh` commands. Never rely on cwd.
- **Re-review is lightweight**: No panel re-dispatch. Speed matters for continuous feedback.
- **No duplicate comments**: On re-review, always check existing comments before posting.
- **Soft tone on approve**: When verdict is APPROVE, phrase minors as suggestions — surface issues without blocking.
