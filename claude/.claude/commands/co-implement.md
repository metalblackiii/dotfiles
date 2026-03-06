---
command: co-implement
description: Use when implementation effort is high enough to delegate to Codex. Plans the feature, hands off to Codex, then reviews the result.
argument-hint: <feature description or path(s) to existing spec doc(s)>
---

# Co-Implement: Claude Plans, Codex Builds

## Step 1 — Parse Arguments

If `$ARGUMENTS` contains multiple space-separated `.md` paths and all exist:
- Treat as a multi-spec run
- Display: "Processing N specs sequentially: [list paths]"
- Show the user a brief summary of each spec (goal + acceptance criteria)
- Ask: "Proceed with these specs in order? Reply to proceed or adjust."
- Wait for confirmation before continuing — skip to Step 4 (loop)

If `$ARGUMENTS` is a single path to an existing `.md` file:
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

For multi-spec runs, loop through each spec sequentially. For single-spec runs, execute once.

**For each spec** (display "Spec M/N: [path]" for multi-spec runs):

Display: "🔵 Claude → 🔴 Codex: handing off implementation"

Before running Codex, snapshot the current changed-file list:
```bash
git diff --name-only > .co-implement/pre-snapshot.txt
```

Run (substitute the actual spec path):
```bash
codex exec --full-auto "$(<path/to/spec.md)"
```

Capture output. Note any errors or warnings from Codex.

After Codex finishes, capture this spec's delta:
```bash
git diff --name-only > .co-implement/post-snapshot.txt
comm -13 .co-implement/pre-snapshot.txt .co-implement/post-snapshot.txt > ".co-implement/changed-$(basename path/to/spec.md .md).txt"
```

Then proceed to Step 5 for this spec before moving to the next.

## Step 5 — Review Output

Read `git diff` (unstaged changes).

Evaluate against the acceptance criteria in the current spec:
- **Empty diff**: Codex made no changes. Warn the user — the spec may be unclear or Codex hit an issue. Stop.
- **All criteria appear met**: Record this spec as complete. Continue to the next spec (Step 4) or proceed to Step 6 if all specs are done.
- **Partial progress**: Identify which criteria are still unmet. Write a focused follow-up prompt to `.co-implement/followup.md`:
  ```
  The following work was already completed: [summary of diff]

  The following acceptance criteria still need to be addressed:
  [unmet criteria from original spec]

  Do not re-do completed work. Focus only on the remaining items.
  [Constraints from original spec repeated]
  ```
  Continue to next iteration (back to Step 4 with followup as the prompt).
- **Off the rails**: Codex modified files outside the spec's scope, or made sweeping unexpected changes. Run `git stash push -u -m "co-implement: off-rails changes"` to safely preserve the changes (including new files) for inspection, then report what happened. Only discard with user approval.

Maximum 3 Codex passes per spec. If still incomplete after 3, summarize what's done and what remains. For multi-spec runs, ask the user: "Continue with remaining specs or stop here?" For single-spec runs, stop.

Track cumulative results: files changed, criteria met/unmet, and pass count per spec.

## Step 6 — Stage Gate

Show the user a combined summary:
- For multi-spec runs, list results per spec:
  - Spec path
  - Files changed by this spec (from `.co-implement/changed-*.txt` snapshots)
  - Which acceptance criteria appear met
  - Number of Codex passes used
- For single-spec runs, show a flat summary:
  - Files changed (list from `git diff --name-only`)
  - Brief diff summary
  - Which acceptance criteria appear met

Ask: "Ready to stage these changes? (`git add -p` recommended to review individually)"

Do NOT run `git add` or `git commit`. The user stages and commits.
