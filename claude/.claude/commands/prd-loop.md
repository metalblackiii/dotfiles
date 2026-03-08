---
command: prd-loop
description: Decompose a PRD into implementation phases, review and approve, then hand off to the execution loop.
argument-hint: <path-to-prd.md>
---

# PRD Loop: Decompose → Approve → Execute

## Step 1 — Load PRD

Read the PRD at `$ARGUMENTS`. If the path doesn't exist, ask the user for the correct path.

If `.prd-loop/state.json` already exists, show current status and ask:
- "Resume execution from existing state?" → display the `prd-loop --resume` command
- "Start fresh?" → confirm, then delete `.prd-loop/` and continue

## Step 2 — Explore Codebase

Before decomposing, explore the areas of the codebase relevant to the PRD:

1. Identify key files, patterns, and conventions
2. Check existing test infrastructure and verification commands
3. Note anything that affects phase sizing or ordering

## Step 3 — Decompose into Phases

Break the PRD into sequential implementation phases. Each phase must be:

- **Small**: ≤12 files changed, ≤400 lines of new/modified code
- **Self-contained**: clear inputs, outputs, and acceptance criteria
- **Ordered**: later phases build on earlier ones — no circular dependencies
- **Testable**: each phase has a verification command

Present the phases as a numbered list with title and description for each.

## Step 4 — Review and Approve

Ask: "Does this phase breakdown look right? You can ask me to split, merge, reorder, or adjust any phase."

Iterate until the user approves. This is the key decision boundary — take time to get it right.

## Step 5 — Write State

Once approved, create the loop state:

```bash
mkdir -p .prd-loop/plans .prd-loop/specs
```

Write `.prd-loop/state.json`:
```json
{
  "version": "1",
  "prd_path": "<absolute path to PRD>",
  "created_at": "<ISO timestamp>",
  "updated_at": "<ISO timestamp>",
  "consecutive_failures": 0,
  "phases": [
    {
      "id": "phase-1",
      "title": "<title>",
      "description": "<description>",
      "status": "pending",
      "failed_count": 0,
      "started_at": null,
      "completed_at": null,
      "error": null
    }
  ]
}
```

Write `.prd-loop/progress.txt`:
```
# PRD Loop Progress
PRD: <path>
Started: <timestamp>

---
```

## Step 6 — Hand Off

Display:

```
Phase plan saved to .prd-loop/state.json

To start the execution loop:
  ~/.claude/scripts/prd-loop.sh --resume

To check status later:
  ~/.claude/scripts/prd-loop.sh --status
```

Do NOT start executing phases. The execution loop runs in a separate terminal with fresh context per phase.
