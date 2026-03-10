---
command: prd-loop
description: Use when you have a PRD ready for implementation and want to decompose it into reviewable phases before execution.
argument-hint: <path-to-prd.md>
---

# PRD Loop: Decompose, Approve, Execute

Run the prd-loop orchestrator. It decomposes a PRD into phases, asks for approval, then executes each phase through plan → implement → review cycles.

## Usage

```bash
node ~/repos/prd-loop/dist/cli.js $ARGUMENTS
```

If no arguments are provided, ask the user for the path to their PRD.

## Flags

Pass these flags through if the user requests them:

- `--auto` — skip the human approval gate (preflight checks still run)
- `--lazy-planning` — defer spec generation to right before each phase executes
- `--dry-run` — use stub dispatchers, no external calls

## Resume / Status

If the user wants to resume or check status:

```bash
node ~/repos/prd-loop/dist/cli.js --resume
node ~/repos/prd-loop/dist/cli.js --status
```

## Notes

- The CLI handles everything: preflight checks, decomposition, approval gate, execution loop, git lifecycle, and PR creation.
- State lives in `.prd-loop/state.json` — editable between runs.
- Config: project `.prd-loop/config.json` or global `~/.prd-loop/config.json`.
