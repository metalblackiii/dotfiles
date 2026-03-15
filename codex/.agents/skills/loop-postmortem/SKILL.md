---
name: loop-postmortem
description: ALWAYS invoke after a prd-loop run completes or crashes to produce a structured post-mortem. Triggers on "postmortem", "post-mortem", "what happened in the run", "analyze the prd run", "loop results", or "how did the loop do". Not for monitoring active runs — use babysit-loop.
allowed-tools: Bash, Read, Glob, Grep
---

# Loop Post-Mortem

Produce a structured analysis of a completed or crashed prd-loop run. Prioritizes failed and recovered phases to keep context manageable on large runs.

## Workflow

### 1. Gather Artifacts

Read state first, then prioritize artifacts for failed/recovered phases:

1. `.prd-loop/state.json` — final phase statuses, failure counts, timing
2. `.prd-loop/logs/*.jsonl` — read the **most recent** log file only; for older runs, skim first/last 20 lines per file
3. `.prd-loop/spec-reviews/*.md` and `.prd-loop/reviews/*.md` — read only for phases with `failed_count > 0` or status `skipped`/`failed`
4. `.prd-loop/specs/*.md` — read only for phases referenced by failed reviews

Skip clean-pass phase artifacts unless the run had fewer than 5 phases total.

### 2. Build Timeline

Parse all JSONL log entries and construct a chronological timeline:

```
HH:MM  event_type  phase_id  [duration]  [outcome]
```

Calculate:
- **Total run duration** (first event to last)
- **Time per phase** (planning + review + execution + review)
- **Time wasted on retries** (sum of failed task durations)

### 3. Classify Outcomes

For each phase, classify into one of:

| Outcome | Meaning |
|---------|---------|
| **Clean pass** | Completed on first attempt (0 failures) |
| **Recovered** | Failed 1-2 times, then completed |
| **Skipped** | Exhausted all retries |
| **Crashed** | Run terminated before phase completed |
| **Not reached** | Still pending when run ended |

### 4. Analyze Failures

For every failed task, read the associated review or error and categorize:

| Category | Examples | Fix Type |
|----------|----------|----------|
| **Spec contradiction** | Lockfile in DNT + deps added, bootstrap with no Files to Create | Prompt guardrail (deterministic) |
| **Dependency gap** | Prior phase marked complete but artifacts missing | Orchestrator validation |
| **Planner non-compliance** | Reviewer gave feedback, planner ignored it | Prompt improvement |
| **Scope mismatch** | Phase contract broader than spec covers | State/decomposition fix |
| **Infrastructure** | Git crash, timeout, network error | Code fix |

For each failure, check whether the orchestrator's built-in pre-LLM validation gates caught it (look for `"Spec validation failed"` or `"Missing artifacts"` in task errors). If a failure *could* have been caught deterministically but wasn't, note it as a gap for the orchestrator to address.

### 5. Write Post-Mortem

Produce a markdown document with this structure:

```markdown
# Post-Mortem: prd-loop {project_name}

> Date: {date}
> Run: {start_time}–{end_time} ({duration})
> Branch: {branch}
> Result: {completed}/{total} phases completed, {skipped} skipped, {pending} not reached

## Summary
{2-3 sentence overview of the run outcome}

## Timeline
{chronological event table}

## What Went Wrong
{each failure category with specific examples from this run}

## What Went Right
{successful patterns, recovery examples, code quality observations}

## Root Cause Analysis
{categorized failure table with fix types}

## Gate Effectiveness
{which failures were caught by deterministic gates vs. required LLM review}

## Recommendations
{concrete next steps: prompt changes, orchestrator fixes, decomposition adjustments}
```

### 6. Save

Write the post-mortem to `docs/prd-post-mortem-{project_name}-{date}.md`.

If a previous post-mortem exists for the same project, read it first and note what's changed (new failure modes, resolved issues, recurring patterns).

## Failure Policy

- If `.prd-loop/state.json` doesn't exist, stop and ask the user for the project path.
- If log files are missing, note the gap and analyze from state + reviews only.
- If the run is still active (phases in `executing` or `reviewing` status), warn the user and suggest using `babysit-loop` instead.
