---
name: auto-review
description: Automated PR review with domain-expert panel, batch comment approval, and 30-minute re-review loop. Invoke with /auto-review <PR-URLs...>. Accepts a single PR or a related PR set with cross-cutting analysis. Use --once for single-shot.
disable-model-invocation: true
argument-hint: "[Set Title] <PR-URL...> [--once]"
---

# Auto-Review

Automated PR review pipeline. Surface issues without blocking development, provide faster feedback via re-review loops, and raise quality with domain-expert panels.

For related PR sets (2+ PRs), adds cross-cutting analysis — contract consistency, deployment ordering, feature completeness, and shared model drift across repos.

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

The user provides one or more PRs, optionally preceded by a set title:

```
Compliance Scan entitlement
https://github.com/org/repo-a/pull/142
https://github.com/org/repo-b/pull/1646
https://github.com/org/repo-c/pull/324
```

Accepted formats:
- **PR URL** (e.g., `https://github.com/org/repo/pull/123`)
- **PR number** (e.g., `123`) — resolved from current repo via `gh repo view --json nameWithOwner`
- **Set title** — optional first line that doesn't match a URL or PR number. Provides feature intent for cross-PR analysis.
- **`--once`** — single review without re-review loop

Parse `org` and `repo` from each URL. Bare numbers all resolve to the same repo.

**Single PR** is the degenerate case — no cross-PR analysis, identical behavior to a single-PR invocation.

## Phase 1: Initial Review

### Step 1: Load Review Criteria

Read `../pr-analysis/SKILL.md` using relative path from this skill's location. This provides the 12 review categories, healthcare addendum, and severity definitions.

### Step 2: Fetch PR Information

Fetch metadata and diffs for each PR. Use `-R org/repo` on all `gh` commands.

```bash
# Per PR — parallelize across the set
gh pr view <PR> -R org/repo --json title,body,author,files,additions,deletions,labels,reviews,isDraft,headRefName,baseRefName,headRefOid
gh pr diff <PR> -R org/repo
gh pr view <PR> -R org/repo --json files --jq '.files[].path'
gh pr checks <PR> -R org/repo
```

**For multi-PR sets:** Dispatch one subagent per PR to fetch in parallel. Each subagent returns structured metadata + diff. On Claude Code, use `model: "haiku"` for fetch-only subagents. On Codex, model selection is environment-level — do not specify a model.

**Failure policy:** If any required `gh` command fails, report which PR failed and stop. Do not fall back to local `git diff`.

### Step 3: Standard Analysis

For each PR, analyze changed files:
1. Read the full file for final state and surrounding context
2. Read related files — imports, interfaces, tests, configs
3. Apply every applicable category from `pr-analysis`
4. Run the Defensive Code Audit (empty catches, silent fallbacks, unchecked null, ignored promise rejections)
5. Run the Naming & Readability Scan (vague names, "what" comments, redundant comments)

**For multi-PR sets:** Run per-PR analysis in parallel subagents. Each subagent receives one PR's metadata, diff, and file list. Each returns structured findings.

When reading files from repos not checked out locally, use `gh api`:
```bash
gh api repos/org/repo/contents/path/to/file?ref=<branch> --jq .content | base64 -d
```

### Step 4: Expert Panel Dispatch

Read `references/expert-dispatch.md` for the full expert selection heuristic and subagent prompt template.

Expert subagents use `model: "sonnet"` to avoid inheriting an expensive parent model for review work.

**For multi-PR sets:** Union changed file paths across all PRs. Match against the expert heuristic table. Each expert receives the relevant files from all PRs where matches occurred, with repo context preserved — this gives experts cross-repo visibility within their domain.

**Summary of the dispatch flow:**
1. Match changed file paths (across all PRs) and repo metadata against the expert heuristic table
2. Apply conflict resolution (Neb Conventions subsumes API Design in neb-ms-* repos)
3. Enforce the dispatch cap (max 4 experts, prioritized by tier — see `references/expert-dispatch.md`)
4. For each matched expert domain, read the corresponding domain skill's SKILL.md
5. Dispatch all matched experts as parallel subagents (platform-specific — see `references/expert-dispatch.md`)
6. Each subagent receives: relevant diff portions (tagged by PR/repo), domain skill knowledge, `pr-analysis` criteria for their category, and instructions to return structured JSON findings
7. If no patterns match, skip expert dispatch — standard analysis is sufficient

### Step 5: Cross-PR Analysis

**Skip this step for single-PR reviews.**

Read `references/cross-pr-analysis.md` for the full cross-cutting analysis framework.

Using the set title (if provided) and all PR metadata/diffs gathered in Step 2, analyze:

1. **Contract consistency** — Do provider and consumer PRs agree on API shapes, field names, types, and behavior?
2. **Deployment ordering** — Which PRs must merge/deploy first? Flag circular or missing dependencies.
3. **Shared model drift** — Same entity changed differently across repos without coordination.
4. **Feature completeness** — Given the stated intent, are any layers missing? (e.g., backend without frontend, permissions without enforcement)
5. **Cross-service error handling** — If service A calls service B's new/changed endpoint, does A handle failure?
6. **Configuration consistency** — Env vars, feature flags, and config values that must match across services.

Cross-PR findings use the `xpr:` namespace (e.g., `xpr:f-1`) and reference multiple PRs.

### Step 6: Synthesize Findings

When all per-PR analysis and expert subagents return:

1. **Collect** findings from standard analysis (Step 3), expert subagents (Step 4), and cross-PR analysis (Step 5)
2. **Namespace IDs**: Per-PR findings use `<repo>#<pr>:f-N` (e.g., `neb-ms-core#324:f-1`). Cross-PR findings use `xpr:f-N`. Single-PR reviews use plain `f-N`.
3. **Deduplicate**: Same `repo + file` + overlapping line range (within 3 lines) + same issue category = one finding. Keep the more specific version (longer evidence, expert over standard). For single-PR, dedup key is file path alone.
4. **Classify** by severity: Critical, Important, Minor
5. **Sort**: Cross-PR findings first, then per-PR grouped by repo

### Step 7: Batch Summary

Present the complete review to the user before posting anything.

**Single-PR format:**
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

FINDINGS: X critical, Y important, Z minor

Post this review? (approve / reject / edit)
```

**Multi-PR format:**
```
=== Auto-Review Set: [Set Title] ([N] PRs) ===

PRs:
  repo-a#142  — [title] (@author, +X -Y)
  repo-b#1646 — [title] (@author, +X -Y)
  repo-c#324  — [title] (@author, +X -Y)

Experts dispatched: [list or "none"]

--- Cross-Cutting ([N]) ---
[xpr:f-1] [Severity] [Title] — spans repo-a#142 + repo-c#324
           [One-line description]

--- repo-a#142: [PR Title] ---
Verdict: [REQUEST_CHANGES | COMMENT | APPROVE]
[repo-a#142:f-1] [Severity] [Title] — [file:line]
                  [One-line description]
FINDINGS: X critical, Y important, Z minor

--- repo-b#1646: [PR Title] ---
Verdict: [COMMENT]
[repo-b#1646:f-1] [Severity] [Title] — [file:line]
                   [One-line description]
FINDINGS: X critical, Y important, Z minor

--- Looks Good (across set) ---
[Positive observations]

Post reviews? (approve all / approve selective / reject / edit)
```

Wait for explicit user approval. Options for multi-PR:
- **approve all** — post reviews to all PRs
- **approve selective** — choose which PRs to post to
- **reject** — ask what to change
- **edit** — adjust findings and re-present

Omit any severity section that has no findings. Each PR section (and the single-PR format) ends with a `FINDINGS:` summary line — it enables machine parsing by automation skills. Count 0 for empty sections.

### Step 8: Submit Reviews

On approval, post via `gh api`. See the Comment Submission section below for the exact payload.

**For multi-PR sets:** Submit one review per PR, containing only that PR's findings as inline comments. Cross-PR findings are posted as inline comments on the most relevant PR (closest to root cause), with a note linking to the related PR(s).

### Step 9: Emit Metrics

Append JSON records to `~/.auto-review-metrics.jsonl`. See Metrics Schema below.

**For multi-PR sets:** Emit one record per PR plus one set-level record linking them via `set_id`.

## Phase 2: Re-Review Loop

Skip this phase entirely if `--once` was specified.

### Entry

After Phase 1 completes (reviews posted), inform the user:

**Single-PR:**
```
Re-review loop active. Checking for new commits every 30 minutes.
PR will be monitored until approved or merged. Ctrl+C to stop.
```

**Multi-PR:**
```
Re-review loop active. Checking for new commits every 30 minutes.
Monitoring [N] PRs until all are approved or merged. Ctrl+C to stop.
```

### Cycle

Each cycle:

1. **Wait**: Sleep 30 minutes. Platform-specific:
   - **Claude Code**: `sleep 1800` via Bash with `run_in_background: true`
   - **Codex**: `sleep 1800` via shell (blocks the session — expected for a monitoring loop)
2. **Check PR statuses**:
   ```bash
   gh pr view <PR> -R org/repo --json state,reviews,commits
   ```
   From the JSON response, extract: `state`, each review's `author.login`, `state` (APPROVED/CHANGES_REQUESTED/etc), and `submittedAt`, and the latest commit OID.
3. **Evaluate each PR**:
   - PR merged or closed → remove from active set, log
   - PR has an APPROVED review from someone other than this session's GitHub user, AND no new commits after that approval → remove from active set, log
   - No new commits since last review → skip, log "no changes"
   - New commits detected → mark for delta review
4. **Exit conditions**:
   - All PRs removed from active set → exit loop with summary
   - No PRs marked for delta review → skip to next cycle
5. **Load prior findings**: Read the last records from `~/.auto-review-metrics.jsonl` for each active PR URL. This provides the finding IDs and locations from the previous cycle.
6. **Delta review**: Run standard analysis only (Steps 3 + 6 from Phase 1, no expert panel). Focus on changed files in new commits for each marked PR.
7. **Cross-PR delta** (multi-PR only): If delta review findings touch cross-service boundaries (API contracts, shared models), re-run cross-PR analysis scoped to the affected PRs. Otherwise skip — cross-PR analysis is expensive and unnecessary for isolated changes.
8. **Fetch existing comments**: Retrieve previously posted review comments via `gh api`:
   ```bash
   gh api repos/org/repo/pulls/<PR>/comments
   ```
   Note: `gh api` does not support `-R`. The org/repo are embedded in the URL path. Parse `<!-- auto-review:... -->` markers from comment bodies to map back to finding IDs from the metrics log.
9. **Deduplicate against existing**: Compare new findings against already-posted comments. If a finding matches an existing unresolved comment (same file + overlapping lines + same category), suppress it.
10. **Track resolutions**: For each finding ID from the prior metrics record, check if the corresponding posted comment's code location is addressed by the new commits. Mark as `resolved` or `still-open` in metrics.
11. **Present batch**: Same format as Phase 1 Step 7, prefixed with:
    ```
    === Re-Review (cycle [N]) ===
    New commits: [count] since last review
    Previously resolved: [list of f-IDs]
    ```
12. **Submit and emit metrics** on approval.

### Termination

The loop exits when:
- All PRs in the active set are merged, closed, or approved by another reviewer
- User interrupts (Ctrl+C)

The auto-review's own APPROVE verdict does not terminate the loop — the dev may push more commits after approval, and those need re-review.

## Verdict Logic

| Findings | Verdict | GitHub Event | Comment Tone |
|---|---|---|---|
| 1+ Critical | Request Changes | `REQUEST_CHANGES` | Direct, actionable |
| 1+ Important (no Critical) | Inline Comment | `COMMENT` | Clear but not blocking |
| No Critical/Important | Approve | `APPROVE` | Soft suggestions ("consider", "up to you", "for a follow-up") |

**For multi-PR sets:** Each PR gets its own verdict based on its per-PR findings plus any cross-PR findings posted to that PR. The batch summary shows per-PR verdicts.

The verdict is computed automatically from findings but displayed in the batch summary for user review before posting.

## Comment Submission (Iron Rule)

All code-anchored findings are posted as inline review comments via `gh api`. Never use `gh pr review --comment`.

### Payload Template

```json
{
  "commit_id": "<head-sha>",
  "event": "<APPROVE|COMMENT|REQUEST_CHANGES>",
  "body": "Review summary (N findings: X critical, Y important, Z minor)",
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

- **Critical**: `<!-- auto-review:<ID> -->\n**[Critical]** Title\n\nIssue description.\n\n**Impact:** Why this matters.\n\n**Fix:** Specific recommendation with code example.`
- **Important**: `<!-- auto-review:<ID> -->\n**[Important]** Title\n\nIssue description.\n\n**Recommendation:** Specific fix.`
- **Minor** (on APPROVE): `<!-- auto-review:<ID> -->\n**[Suggestion]** Title\n\nConsider [recommendation]. Up to you — not blocking.`
- **Cross-PR**: `<!-- auto-review:<ID> -->\n**[Important]** Title\n\n[Description]\n\n**Related:** [linked PR URLs]`

`<ID>` is the finding's namespaced ID — `f-1` for single-PR, `repo#pr:f-1` for multi-PR per-PR findings, `xpr:f-1` for cross-PR findings. The marker must match the ID in the metrics record exactly for re-review dedup to work.

The `<!-- auto-review:... -->` HTML comment is invisible on GitHub but lets re-review cycles map posted comments back to finding IDs in the metrics log.

### Findings Without Line Anchors

If a finding has no specific file:line (rare — e.g., "missing test file entirely"), include it in the top-level `body` of the review, not as an inline comment. Cross-PR findings without a clear code anchor (e.g., "missing permission enforcement PR") go in the top-level body of the most relevant PR's review.

## Anti-Hallucination Rules

Adapted from `review`:
1. Verify patterns in the codebase before recommending — don't assume conventions.
2. >10 occurrences = established pattern. <3 occurrences = not established.
3. Read full file context — don't judge from diff lines alone.
4. If unsure about a convention, flag it as a question, not a finding.

## Metrics Schema

Each review cycle appends one JSON line per PR to `~/.auto-review-metrics.jsonl`:

```json
{
  "pr_url": "https://github.com/org/repo/pull/123",
  "set_id": "auto-review-2026-03-24T10:30:00Z",
  "set_title": "Compliance Scan entitlement",
  "timestamp": "2026-03-24T10:30:00Z",
  "mode": "initial",
  "verdict": "COMMENT",
  "experts_dispatched": ["database", "security"],
  "findings": [
    {
      "id": "neb-ms-core#324:f-1",
      "severity": "Important",
      "title": "Missing index on frequently queried column",
      "location": "migrations/20260314-add-table.sql:15",
      "category": "Database",
      "status": "new"
    }
  ],
  "cross_pr_findings_on_this_pr": [
    {
      "id": "xpr:f-1",
      "severity": "Important",
      "title": "Contract mismatch on fieldName",
      "prs": ["org/repo-a#142", "org/repo-c#324"],
      "category": "Contract Consistency",
      "status": "new"
    }
  ],
  "counts": { "critical": 0, "important": 1, "minor": 3, "cross_pr_on_this_pr": 1 },
  "resolved_from_previous": [],
  "cycle_duration_seconds": 180
}
```

For single-PR reviews, `set_id`, `set_title`, and `cross_pr_findings_on_this_pr` are omitted. Finding IDs use plain `f-N`.

**Cross-PR finding ownership:** Per-PR records contain only the `xpr:` findings that were *posted to that specific PR* — whether as inline comments (code-anchored) or in the top-level review body (no anchor). See Step 8 for placement rules. The set-level record carries the complete list. Re-review dedup and resolution tracking for `xpr:` findings use the per-PR record to know which findings live on which PR, and the set-level record for the full picture.

**Set-level record** (multi-PR only): In addition to per-PR records, emit one set-level record that links the individual PR reviews:

```json
{
  "set_id": "auto-review-2026-03-24T10:30:00Z",
  "set_title": "Compliance Scan entitlement",
  "timestamp": "2026-03-24T10:30:00Z",
  "mode": "initial",
  "pr_urls": [
    "https://github.com/org/repo-a/pull/142",
    "https://github.com/org/repo-c/pull/324"
  ],
  "cross_pr_findings": [
    {
      "id": "xpr:f-1",
      "severity": "Important",
      "title": "Contract mismatch on fieldName",
      "prs": ["org/repo-a#142", "org/repo-c#324"],
      "category": "Contract Consistency",
      "status": "new"
    }
  ],
  "counts": { "cross_pr": 1 },
  "cycle_duration_seconds": 240
}
```

The set-level record has no `pr_url` (singular) or `verdict` — those live on the per-PR records. It carries `pr_urls` (plural), `cross_pr_findings`, and set-level timing.

For re-review cycles, `mode` is `"re-review"` and `resolved_from_previous` contains IDs of findings from earlier cycles that are now fixed.

**Metrics hygiene:** No diff content, code snippets, or PHI/PII. Structured references only (file:line, finding title, severity).

## Constraints

- **Criteria alignment**: Consume `pr-analysis/SKILL.md` as the single source of review criteria. Never define independent review standards.
- **Iron rule**: All code-anchored findings posted as inline comments via `gh api`. Never `gh pr review --comment` for findings.
- **No git operations**: This is a `gh`-only command. Never fall back to local `git diff`.
- **Human gate**: Every batch requires explicit user approval before posting. Never auto-post.
- **-R everywhere**: Always use `-R org/repo` on `gh` commands. Never rely on cwd.
- **Re-review is lightweight**: No panel re-dispatch. No full cross-PR re-analysis unless boundary changes are detected.
- **No duplicate comments**: On re-review, always check existing comments before posting.
- **Soft tone on approve**: When verdict is APPROVE, phrase minors as suggestions — surface issues without blocking.
- **Single-PR backward compatibility**: Single PR input produces identical behavior — no cross-PR steps, plain `f-N` IDs, same summary format.
