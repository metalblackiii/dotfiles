---
name: reflection
description: Use after completing a meaningful chunk of implementation, before claiming progress or moving to verification. Not for trivial single-line changes.
disable-model-invocation: true
---

# Reflection

## Overview

Implementation momentum creates blind spots. You know what you *intended* to write, not what you *actually* wrote.

**Core principle:** Re-read your own work against original intent before presenting it. Fix what you find silently. The user sees correct code, not a correction narrative.

## The Iron Law

```
NO PRESENTING WORK WITHOUT RE-READING IT FIRST
```

If you haven't re-read the actual files you changed, you cannot report progress.

## When to Use

**After completing any meaningful implementation chunk:**
- New function, class, or module
- Multi-file change
- Bugfix with structural changes
- Refactoring pass
- Any change touching 3+ locations

**Don't use for:**
- Single-line fixes, typos, config tweaks
- Pure research or exploration
- Reading/explaining code without modifying it

## Where Reflection Fits

```
implement → REFLECT → verify → self-review → commit
```

| Layer | What it does | What it catches |
|-------|-------------|-----------------|
| **Reflection** (reasoning) | Re-read files, check against intent | Hallucinated imports, partial implementations, pattern drift, stale references, logic gaps |
| **Verification** (evidence) | Run commands, prove claims with output | Test failures, build errors, lint violations, runtime bugs |
| **Self-review** (fresh eyes) | Isolated diff review, no implementation context | Architecture violations, security gaps, missing edge cases, code quality |

Reflection catches what verification cannot — reasoning errors that produce code that *runs* but doesn't match *intent*. Verification catches what reflection cannot — runtime failures invisible to static reading.

## The Reflection Pass

One continuous re-read, not a checklist to rush through. Each lens builds on the previous.

### 1. PAUSE

Break implementation momentum. You've been writing code — now switch to *reading* mode.

The cognitive shift matters. Writing and reviewing are different mental states. If you skip the pause, you'll read what you *think* you wrote, not what's actually there.

### 2. RE-READ THE ASK

Go back to the original request. What did the user actually ask for?

- What were the explicit requirements?
- What were the implicit constraints?
- What did you commit to delivering?
- Has scope crept during implementation?

Don't trust your memory of the ask. Re-read it.

### 3. RE-READ WHAT YOU BUILT

Open the actual files. Read them top to bottom. Watch for:

- **Hallucinated imports** — modules or functions you assumed exist
- **Partial implementations** — TODO comments, placeholder returns, stub functions that never got filled in
- **Copy-paste artifacts** — variable names from the source, not adapted to the target
- **Off-by-one in logic** — boundary conditions, loop ranges, array indices
- **Stale references** — old variable names, removed functions still called, outdated comments
- **Type mismatches** — passing wrong types, missing conversions, nullable values used as non-null
- **Silent failures** — empty catch blocks, swallowed errors, missing error paths

Read the code as if someone else wrote it. What would you flag in review?

### 4. CHECK CROSS-FILE COHERENCE

When changes span multiple files:

- **Imports resolve** — every import points to something that exists and is exported
- **Signatures match** — callers pass what callees expect, in the right order
- **Patterns align** — if you followed a convention in file A, you followed it in file B
- **State flows correctly** — data transformations chain without gaps
- **No orphaned code** — nothing left dangling from a mid-implementation pivot

### 5. FIX SILENTLY

Found issues? Fix them. Don't report them to the user.

The user doesn't need a narrative of your self-corrections. They need correct code. Presenting a list of "things I caught and fixed" wastes their time and erodes confidence.

**Exception:** If reflection reveals the original approach is fundamentally wrong and requires a different strategy, tell the user. They should know about directional changes, not typo fixes.

### 6. CONTINUE

Hand off to the next phase:
- If more implementation remains → continue building, reflect again at next chunk
- If implementation is complete → invoke `verification-before-completion`

## Red Flags — STOP and Reflect

If you catch yourself thinking:

- **"This should work"** → You don't know until you re-read it
- **"I just wrote it, I know what's there"** → You know what you intended, not what you wrote
- **"Let me just present this and move on"** → Momentum talking, not quality
- **"It's basically done"** → Basically ≠ actually
- **"I'll catch issues in verification"** → Verification catches runtime failures, not reasoning errors
- **"The user can review it"** → Your job is to present clean work, not delegate review

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I just wrote it, I know what's there" | You know what you *intended*, not what you *wrote* |
| "It's a small change" | Small changes with wrong imports crash just as hard |
| "Verification will catch it" | Verification catches runtime errors; reflection catches reasoning errors |
| "Re-reading is redundant" | Writing and reading use different cognitive modes — that's the point |
| "The user will review anyway" | Present clean work, not rough drafts |
| "I'm confident in this code" | Confidence without re-reading is wishful thinking |
| "This is slowing me down" | Rework from unread code is slower |
| "I'll reflect at the end" | Errors compound. Reflect at each meaningful chunk. |

## What Reflection Is NOT

- **Not verification** — reflection doesn't run commands or prove claims with evidence
- **Not self-review** — reflection happens *with* implementation context, not isolated from it
- **Not a checklist** — it's a genuine re-read, not mechanical box-checking
- **Not a report** — fixes are silent; the user sees results, not process
- **Not optional for "simple" multi-file changes** — simple changes have imports and signatures too

## The Bottom Line

**Read what you wrote, not what you think you wrote.**

Implementation momentum is the enemy of correctness. The pause between writing and presenting is where quality happens.
