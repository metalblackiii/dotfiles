---
name: babysit-loop
description: ALWAYS invoke to monitor a running prd-loop session. Triggers on "check the prd", "how is the loop going", "babysit", "prd status", "check on phase", or "monitor the run". Designed for use with /loop (e.g., /loop 3m /babysit-loop). Not for post-run analysis — use loop-postmortem.
allowed-tools: Bash, Read, Glob, Grep
---

# Babysit Loop

Point-in-time health check for a running prd-loop. Read-only — never modify state or interfere with the run.

## Workflow

### 1. Read State

```bash
cat .prd-loop/state.json | jq '{
  project: .project_name,
  branch: .branch,
  consecutive_failures: .consecutive_failures,
  phases: [.phases[] | {id, title, status, failed_count}]
}'
```

### 2. Find Active Phase

The active phase is the first with status not `completed` or `skipped`.

Report:
- **Phase ID and title**
- **Current status** (planning / spec_review / executing / reviewing / failed)
- **Attempt number** (failed_count + 1) / max retries
- **Latest task** — read the last entry in the phase's `tasks` array for type, status, and timing

### 3. Check Recent Logs

Use Glob to find log files, then Read the most recent one. If no log files exist, skip this step and report from state only.

```bash
# Find logs — if none exist, skip to step 4
cat .prd-loop/state.json | jq -r '.phases[] | select(.tasks | length > 0) | .tasks[-1] | {type, status, started_at}'
```

Report timing: how long the current task has been running (compare `started_at` to now).

### 4. Flag Anti-Patterns

Check for these known failure modes and flag any that apply:

| Pattern | Detection | Severity |
|---------|-----------|----------|
| **Retry loop** | Same `error` string in 2+ consecutive failed tasks for the same phase | HIGH — likely a spec contradiction the planner can't resolve |
| **Dependency gap** | Phase description references a command/file that doesn't exist on disk | HIGH — prior phase left work undone |
| **Timeout spiral** | 2+ consecutive tasks with `"Codex timed out"` errors | MEDIUM — phase may be too large |
| **Circuit breaker approaching** | `consecutive_failures` >= 2 | MEDIUM — one more failure triggers halt |
| **Stale execution** | Current task `started_at` is >20 minutes ago | LOW — might be normal for large phases |

### 5. Report

Output a concise status block:

```
## prd-loop status

**Project:** {name} | **Branch:** {branch}
**Progress:** {completed}/{total} phases | **Consecutive failures:** {n}

**Active:** {phase_id} — {title}
  Status: {status} | Attempt: {n}/{max}
  Current task: {type} (running {duration})

{any flagged anti-patterns, or "No issues detected."}
```

If all phases are complete, say so and suggest running `/loop-postmortem`.

## Composing with /loop

This skill is designed for repeated invocation:

```
/loop 3m /babysit-loop
```

Each invocation is independent — no state carried between calls. Keep output concise so repeated reports don't flood the conversation.

## Failure Policy

- If `.prd-loop/state.json` doesn't exist, report "No active prd-loop found" and stop.
- If log files are missing, skip log analysis and report from state only.
- Never modify `.prd-loop/state.json` or any project files.
