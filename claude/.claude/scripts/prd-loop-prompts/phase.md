You are executing one phase of a PRD implementation loop. You have fresh context — no prior conversation history. Everything you need is on disk.

## Your task

Execute phase **{{PHASE_ID}}** — and ONLY this phase.

## Inputs

- State file: `{{STATE_FILE}}`
- Progress log: `{{PROGRESS_FILE}}`
- PRD: `{{PRD_PATH}}`
- Plans directory: `{{LOOP_DIR}}/plans/`
- Specs directory: `{{LOOP_DIR}}/specs/`

## Workflow

### 1. Orient

Read these files in order:
1. `{{STATE_FILE}}` — find phase {{PHASE_ID}} and its description
2. `{{PROGRESS_FILE}}` — understand what prior phases accomplished, what patterns worked, what to avoid
3. `{{PRD_PATH}}` — full requirements context

### 2. Plan

Write a phase plan to `{{LOOP_DIR}}/plans/{{PHASE_ID}}.md` covering:
- What this phase implements (traced back to PRD requirements)
- Which files to modify and create
- How it builds on prior phases
- Acceptance criteria (derived from PRD + phase description)
- Verification command

### 3. Write Codex Spec

Write a self-contained spec to `{{LOOP_DIR}}/specs/{{PHASE_ID}}.md`. Codex reads this with zero prior context — it must be fully self-contained:

```
## Goal
[What to build and why]

## Context
[Key files, existing patterns, what prior phases already built — be specific with paths and code references]

## Files to Modify
- `path/to/file` — [what to change and why]

## Files to Create
- `path/to/file` — [what it should contain]

## Do Not Touch
[Files explicitly out of scope — prevents Codex drift]

## Acceptance Criteria
- [ ] [Concrete, testable criterion]

## Constraints
[Patterns to follow, API contracts to maintain, things not to break]

## Verify
[Command to confirm correctness — e.g., npm test, npm run build, etc.]
```

### 4. Delegate to Codex

Run:
```bash
codex exec --full-auto "$(< {{LOOP_DIR}}/specs/{{PHASE_ID}}.md)"
```

If the command fails or produces no output, record the error and skip to step 7 (mark as failed).

### 5. Review

Check `git diff` (unstaged changes) against the acceptance criteria from step 3.

- **All criteria met** → proceed to step 6
- **Partial progress** → write a focused followup to `{{LOOP_DIR}}/specs/{{PHASE_ID}}-followup.md` addressing only unmet criteria, then re-run Codex (max 3 total attempts across original + followups)
- **Empty diff or off-rails** → record the error, proceed to step 7 as failed

### 6. Peer Review

Invoke the `peer-review` skill on the current unstaged changes. (Requires the peer-review skill from the dotfiles repo to be installed — it provides context-isolated review via the self-review and pr-analysis criteria.)

- **Critical findings** → mark phase as failed, include findings summary in the error field
- **Important/Minor or clean** → proceed to step 7 as completed
- **If peer-review skill is unavailable** → skip this step, note it in the progress log, proceed to step 7

### 7. Commit

Stage and commit all implementation changes for this phase:

```bash
git add -A
git commit -m "{{PHASE_ID}}: <short description of what this phase implemented>"
```

Do NOT commit if the phase failed — leave changes unstaged. The bash driver discards uncommitted changes before retrying.

### 8. Update State

Read `{{STATE_FILE}}` fresh, then update it:

**If completed:**
- Set this phase's `status` to `"completed"`
- Set `started_at` and `completed_at` to ISO timestamps
- Reset top-level `consecutive_failures` to `0`

**If failed:**
- Set this phase's `status` to `"failed"` (keeps it eligible for retry by the outer loop)
- Increment this phase's `failed_count`
- Set `error` to a brief description of what went wrong
- Increment top-level `consecutive_failures`

In both cases, update top-level `updated_at`.

**CRITICAL**: Read the existing JSON, modify only the fields listed above, and write the full structure back. Do not drop or reorder other phases.

### 9. Log Progress

Append to `{{PROGRESS_FILE}}`:

```
## {{PHASE_ID}}: [completed|failed]
- **What**: [brief summary of what was done]
- **Files changed**: [list of files]
- **What worked**: [approaches that succeeded]
- **What failed**: [issues encountered, if any]
- **Context for next phase**: [anything the next phase should know]
```

### 10. Stop

Do NOT proceed to the next phase. Do NOT start planning the next phase. Your job is done. Exit.
