---
command: co-implement
description: Plan a feature, delegate implementation to Codex CLI, then supervise
argument-hint: <feature description or path to existing spec doc>
---

# Co-Implement: Claude Plans, Codex Builds

## Step 1 — Parse Arguments

If `$ARGUMENTS` is a path to an existing `.md` file:
- Read it as the spec — skip to Step 3
- Display: "Using spec from [path]"

Otherwise treat `$ARGUMENTS` as a feature description — continue to Step 2.

## Step 2 — Write the Spec

Explore the relevant codebase areas. Then write a self-contained spec to
`.co-implement/spec.md` using this template:

---
### Spec Template

```
## Goal
[One paragraph: what to build and why. Codex will read this without conversation context.]

## Context
[Key files, existing patterns, relevant constants, current behavior]

## Files to Modify
- `path/to/file.js` — [what to change and why]

## Files to Create
- `path/to/new-file.js` — [what it should contain]

## Do Not Touch
[Files and areas explicitly out of scope — prevents Codex drift]

## Acceptance Criteria
- [ ] [Concrete, testable criterion]
- [ ] [Another criterion]

## Constraints
[API contracts to maintain, patterns to follow, things not to break]

## Verify
[Command to run to confirm correctness — e.g., `npm test`, `node -e "..."`, etc.]
```
---

## Step 3 — Present Spec for Review

Show the user the spec at `.co-implement/spec.md`.
Ask: "Does this spec look right? Reply to proceed or edit the spec first."
Wait for confirmation before continuing.

## Step 4 — Delegate to Codex

Display: "🔵 Claude → 🔴 Codex: handing off implementation"

Run:
```bash
codex exec --full-auto "$(cat .co-implement/spec.md)"
```

Capture output. Note any errors or warnings from Codex.

## Step 5 — Review Output

Read `git diff` (unstaged changes).

Evaluate against the acceptance criteria in the spec:
- **Empty diff**: Codex made no changes. Warn the user — the spec may be unclear or Codex hit an issue. Stop.
- **All criteria appear met**: Proceed to Step 6.
- **Partial progress**: Identify which criteria are still unmet. Write a focused follow-up prompt to `.co-implement/followup.md`:
  ```
  The following work was already completed: [summary of diff]

  The following acceptance criteria still need to be addressed:
  [unmet criteria from original spec]

  Do not re-do completed work. Focus only on the remaining items.
  [Constraints from original spec repeated]
  ```
  Continue to next iteration (back to Step 4 with followup as the prompt).
- **Off the rails**: Codex modified files outside the spec's scope, or made sweeping unexpected changes. Run `git checkout -- .` only after confirming with user. Report what happened.

Maximum 3 Codex passes. If still incomplete after 3, summarize what's done and what remains, then stop.

## Step 6 — Stage Gate

Show the user a summary:
- Files changed (list from `git diff --name-only`)
- Brief diff summary
- Which acceptance criteria appear met

Ask: "Ready to stage these changes? (`git add -p` recommended to review individually)"

Do NOT run `git add` or `git commit`. The user stages and commits.
