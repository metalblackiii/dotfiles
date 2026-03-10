---
command: co-implement
description: Use when implementation effort is high enough to delegate to Codex. Plans the feature, hands off to Codex, then reviews the result.
argument-hint: <feature description>
---

# Co-Implement: Single-Phase PRD Loop

Delegates a single feature to the prd-loop orchestrator in single-phase mode. It plans a spec, hands off to Codex for implementation, reviews the result, and creates a PR.

## Usage

```bash
node ~/repos/prd-loop/dist/cli.js --single-phase $ARGUMENTS
```

If `$ARGUMENTS` is empty, ask the user to describe the feature they want implemented.

## Flags

Pass these flags through if the user requests them:

- `--auto` — skip interactive confirmations
- `--lazy-planning` — defer spec generation to right before execution
- `--dry-run` — use stub dispatchers, no external calls

## Notes

- This replaces the previous multi-step co-implement flow with prd-loop's single-phase mode.
- The CLI handles: preflight checks, spec generation, Codex execution, review, git commit, and PR creation.
- State lives in `.prd-loop/state.json`. Resume with `node ~/repos/prd-loop/dist/cli.js --resume`.
