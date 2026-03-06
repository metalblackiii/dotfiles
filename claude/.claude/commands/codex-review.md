---
command: codex-review
description: Use to have Codex peer-review your current local changes. Runs verdict-driven iterations (VERDICT: APPROVED / VERDICT: REVISE) until approved or max rounds reached.
argument-hint: [focus area — e.g. "security", "error handling", "src/auth/**"]
---

# Codex Review: Claude Writes, Codex Reviews

Claude implements. Codex reviews. On REVISE, Claude addresses the feedback and re-submits. Repeat until APPROVED or 3 rounds.

## Step 1 — Capture Diff

Run `git diff HEAD` to get all local changes. If empty, try `git diff --staged`. If both are empty, tell the user there's nothing to review and stop.

Display: "Reviewing [N lines across M files]" (from `git diff HEAD --stat`).

If `$ARGUMENTS` is provided, treat it as a focus area to pass to Codex (e.g., "focus on error handling", "review only src/auth/**").

Create `.codex-review/` working directory if it doesn't exist.

## Step 2 — Build Review Prompt

Construct a self-contained prompt for Codex. It must include the full diff inline — Codex runs without conversation context.

```
Review the following code changes for quality, correctness, and potential issues.

First, read these files to load the review criteria and severity definitions:
- ~/.agents/skills/personal/pr-analysis/SKILL.md
  (12 review categories, severity definitions, healthcare HIPAA addendum)
- ~/.agents/skills/personal/self-documenting-code/SKILL.md
  (naming quality criteria — flag vague names and what-comments added in the diff)

Apply ALL applicable review categories from pr-analysis to the diff below.
For the naming scan, flag any vague names or what-comments introduced in the diff.
[If focus area provided]: Additionally focus on: $ARGUMENTS

<diff>
[full output of git diff HEAD]
</diff>

For each issue found, report:
- Severity: Critical / Important / Minor  (per pr-analysis definitions)
- Category: [which pr-analysis category, e.g. "Security", "Testing Coverage"]
- Location: file:line
- Issue: what's wrong
- Suggestion: how to fix it

Be specific and evidence-based. Do not flag issues not present in the diff.
Skip categories with no findings — do not pad with N/A rows.

End your review with exactly one of these lines (no trailing text):
VERDICT: APPROVED
VERDICT: REVISE
```

## Step 3 — Dispatch to Codex

Display: "Round N/3: handing off to Codex..."

Run (use the actual round number for the filename):
```bash
codex exec --full-auto "<review prompt>" | tee .codex-review/round-N.md
```

Wait for output. If Codex exits with an error or produces no output, report what happened and stop.

## Step 4 — Parse Verdict

Read `.codex-review/round-N.md`. Find the last line matching `VERDICT: APPROVED` or `VERDICT: REVISE`.

**If VERDICT: APPROVED:**
- Display: "Codex approved the changes."
- Show a one-line summary of any Minor findings noted (non-blocking).
- Stop.

**If VERDICT: REVISE:**
- Display the full Codex review output so the user can read it.
- List each Critical and Important finding clearly.
- Proceed to Step 5.

**If no VERDICT line found:**
- Warn the user that Codex didn't return a verdict.
- Show the raw output.
- Ask: "Treat as REVISE and continue, or stop?"

## Step 5 — Address Feedback

Claude (not Codex) addresses each Critical and Important finding from the review:
- Read the relevant files
- Make the targeted fixes
- Do not make changes outside the scope of the Codex findings

After fixing, display a brief summary: which findings were addressed and how.

If a finding is unclear or requires a design decision, ask the user before proceeding.

**Maximum 3 rounds.** If still REVISE after round 3:
- Summarize what was addressed across all rounds
- List any remaining findings that weren't resolved
- Ask the user how to proceed

## Step 6 — Re-Submit

Go back to Step 2 with the updated diff. Increment round counter.

## Working Files

`.codex-review/round-N.md` — Codex output per round (keep for reference)

Tell the user these files exist and can be deleted manually when done:
```
rm -rf .codex-review/
```
Do NOT delete them yourself.
