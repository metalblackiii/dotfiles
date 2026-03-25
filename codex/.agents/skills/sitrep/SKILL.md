---
name: sitrep
description: >-
  ALWAYS invoke for multi-session situation awareness on large Jira work items —
  epics, complex stories, or label-based groupings spanning multiple repos and tickets.
  Triggers on "sitrep", "situation report", "status of GBB", "what's the state of",
  "orient me on", "catch me up on", or any request for persistent cross-session context
  on a body of Jira work. Do not scan Jira for situational context without this skill.
argument-hint: "<keyword or ticket key(s)>"
---

# Sitrep — Situation Representative

Maintain a persistent situation report for a body of Jira work. Orient in seconds, start making decisions immediately — no re-discovery between sessions.

## Overview

A sitrep is a living document at `~/.sitreps/{slug}/sitrep.md` that captures ticket inventory, status breakdown, acceptance criteria, repo scan results, gaps, and a decision log. The skill detects freshness, offers to refresh when stale, and enters an interactive conversational mode grounded in the sitrep data.

## Workflow

```
INPUT → DISCOVER → CONFIRM → [CREATE | REFRESH | LOAD] → INTERACTIVE
```

### Step 0: Parse Input

The argument is either:
- **Ticket key(s)** — matches `[A-Z]+-\d+` (e.g., `NEB-95149`, `NEB-1,NEB-2`). Use directly as root issues.
- **Keyword** — anything else (e.g., `GBB`). Triggers fuzzy Jira search.

Derive the slug: lowercase, hyphenated. `GBB` → `gbb`, `NEB-95149` → `neb-95149`, `multi word` → `multi-word`.

Check for existing sitrep at `~/.sitreps/{slug}/sitrep.md`.

### Step 1: Discovery

**If keyword input**, search Jira across all issue types:

```bash
ptjira search 'summary ~ "<keyword>" ORDER BY issuetype, status' \
  --fields key,summary,status,issuetype --json --all
```

Present all matches with key, summary, status, and issue type. Ask the user to confirm which issues to include as root issues. User may select all, a subset, or refine the search.

**If ticket key input**, validate the keys exist:

```bash
ptjira get <KEY1>,<KEY2> --fields key,summary,status,issuetype --json
```

### Step 2: Route by Freshness

| Condition | Action |
|-----------|--------|
| No sitrep file exists | → Step 3 (Create) |
| Sitrep exists, older than 24 hours | Offer to refresh → Step 4 (Refresh) or Step 5 (Interactive) |
| Sitrep exists, younger than 24 hours | → Step 5 (Interactive) |

The user can always force a refresh (`rescan`, `refresh`) or skip to interactive.

### Step 3: Create Sitrep (First Run)

#### 3a: Repo Discovery

Ask the user which repos to scan. Suggest candidates by scanning ticket content for repo hints:
- Ticket summaries mentioning service names → suggest that repo
- Common mappings: "billing" → `neb-ms-billing`, "image" → `neb-ms-image`, "frontend"/"UI" → `neb-www`

Save selected repos in the sitrep metadata for reuse on subsequent runs.

#### 3b: Parallel Scan

Launch parallel operations using the Agent tool:

**Jira agent** — Discover child tickets and subtasks:
1. For Epic roots: `ptjira search '"Epic Link" in (<keys>) ORDER BY status' --fields key,summary,status,issuetype --json --all`
2. For Story/Task roots: `ptjira search 'parent in (<keys>) ORDER BY status' --fields key,summary,status,parent --json --all`
3. **Second pass** — for any Stories/Tasks discovered in step 1 (children of epics), also fetch their subtasks: `ptjira search 'parent in (<child-story-keys>) ORDER BY status' --fields key,summary,status,parent --json --all`
4. Batch-fetch descriptions with AC for all discovered keys: `ptjira get <all-keys> --fields description --text --json`

**Repo agents** (one per repo) — Search for related code:
- Search terms: root issue keys, child ticket keys, feature-specific slugs (extracted from ticket content, e.g., bracket-notation like `[entl:multi-location]`), and the keyword
- Search location: `~/repos/{repo-name}`
- Use Grep for each search term, collect file paths and match context

#### 3c: Synthesize

Assemble the sitrep file at `~/.sitreps/{slug}/sitrep.md` using the format in the File Format section below.

Populate the Gaps section by identifying:
- Tickets with no code matches in any scanned repo
- Code matches with no corresponding ticket
- Tickets missing acceptance criteria
- Open tickets with no subtasks (for stories/tasks that seem decomposable)

### Step 4: Refresh Existing Sitrep

1. Read the existing sitrep file
2. **Preserve the Decision Log and Progress sections verbatim** — extract both before overwriting. These are the accumulated cross-session history.
3. Re-run the parallel scan from Step 3b using the saved root issues and repos
4. Rebuild the sitrep with fresh data
5. Re-insert the preserved Decision Log and Progress sections
6. **Diff and present changes**: tickets that moved status, new tickets discovered, new subtasks, new code matches, resolved gaps

### Step 5: Interactive Mode

Load the sitrep file as context. Enter freeform conversational mode.

The user can:
- Ask analytical questions grounded in the sitrep ("what are the biggest gaps?", "which tickets are blocked?")
- Request Jira actions ("create a subtask under NEB-1234", "transition NEB-5678 to In DEV")
- Request a rescan ("rescan for new tickets", "check for new epics") — triggers Step 4 inline
- Discuss decisions and planning
- Ask for a PRD to be drafted for a gap

**Decision Log**: When a decision is made or confirmed during the conversation, ask the user for permission to append it to the Decision Log. Format: `- {YYYY-MM-DD}: {decision} — Reason: {why}`

**Sitrep Updates**: When the session produces significant progress or decisions, proactively offer to update the sitrep file:
- Append new Decision Log entries
- Add a session summary to the Progress section: `### Session — {YYYY-MM-DD}` with bullet points of what was discussed/decided

## Sitrep File Format

```markdown
# Sitrep: {keyword}

Last refreshed: {ISO timestamp}
Root issues: {NEB-1 (Epic), NEB-2 (Epic), ...}
Repos: {repo-1, repo-2, ...}

## Status Summary

| Status | Count | Tickets |
|--------|-------|---------|
| Open | 4 | NEB-1, NEB-2, ... |
| In DEV | 1 | NEB-3 |
| Implemented | 3 | NEB-4, NEB-5, NEB-6 |

## Ticket Inventory

### NEB-XXXXX: {summary}
- **Parent**: NEB-YYYYY ({parent summary})
- **Status**: {status}
- **Acceptance Criteria**: {plaintext from --text, or "No AC defined"}
- **Subtasks**: {list with status, or "None"}
- **Code found**: {repo: files matched, or "No matches"}

## Gaps

{Tickets with no code matches, code with no tickets, missing AC, open items with no subtasks}

## Decision Log

- {date}: {decision} — Reason: {why}

## Progress

### Session — {date}
- {what was discussed/decided}
```

## Jira Commands Reference

```bash
# Fuzzy search across all issue types
ptjira search 'summary ~ "<keyword>" ORDER BY issuetype, status' \
  --fields key,summary,status,issuetype --json --all

# Child tickets under epics
ptjira search '"Epic Link" in (<keys>) ORDER BY status' \
  --fields key,summary,status,issuetype --json --all

# Subtasks under stories/tasks (also use for children of epic-discovered stories)
ptjira search 'parent in (<keys>) ORDER BY status' \
  --fields key,summary,status,parent --json --all

# Batch description extraction (AC)
ptjira get <KEY1>,<KEY2>,<KEY3> --fields description --text --json

# Validate keys
ptjira get <KEY1>,<KEY2> --fields key,summary,status,issuetype --json
```

## Resilience

- If `ptjira` commands fail (auth, network), report the failure and continue with available data — do not abort the entire scan
- If a repo path doesn't exist at `~/repos/{name}`, skip it and note the miss
- If no tickets match a keyword search, tell the user and suggest refining the search term

## Guardrails

- **Read-only scanning.** Do not modify Jira tickets during scan phases. Write operations only during interactive mode, and only when the user explicitly requests them.
- **Confirm before writing.** Show the user what you'll do before any Jira write operation.
- **Preserve Decision Log and Progress.** On every refresh, both sections must survive verbatim. These are the accumulated cross-session history — the core value of the tool.
- **No PII.** Use placeholder data in any examples.
