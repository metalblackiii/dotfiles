---
name: software-design
description: Use when making single-service design decisions, restructuring code, planning implementations, or evaluating code smells and refactoring opportunities.
---

# Software Design

## Core Belief

Software development is a craft that balances idealism with reality. Ship working software, learn continuously, and leave the codebase better than you found it.

---

## Part 1: Design Principles

### DRY Is About Knowledge, Not Code
"Don't Repeat Yourself" means every piece of *knowledge* has a single, authoritative source. Duplicated code is a symptom; duplicated intent is the disease. Database schema, API contract, validation rules—each truth lives in one place.

### Orthogonality
Keep components independent. A change here shouldn't break something over there. When you modify one module, you shouldn't need to understand (or touch) another. If two things change together, they belong together.

### Tracer Bullets
Get something working end-to-end first—a thin slice through all the layers. It proves the architecture, reveals unknowns, and gives you something real to iterate on. Tracer bullets aren't prototypes; they're production code, just incomplete.

### Good Enough Software
Perfect software doesn't exist, and chasing it delays value. Know when to stop. Involve users in the "good enough" tradeoff—they often prefer something working now over something perfect later. Make quality a requirements issue, not an afterthought.

### Broken Windows
Don't leave "broken windows"—bad designs, wrong decisions, poor code—unrepaired. One broken window invites more. Fix it, board it up, or at minimum mark it clearly. Neglect accelerates decay.

### Reversibility
Don't carve decisions in stone. Requirements change, technologies change, minds change. Hide third-party dependencies behind abstractions. Prefer configuration over hardcoding. Make it easy to change your mind.

### Don't Program By Coincidence
Understand *why* your code works, not just *that* it works. Coincidental correctness hides bugs and crumbles under change. If you can't explain it, you don't control it.

### Crash Early
A dead program does less damage than a crippled one. When something impossible happens, stop immediately with a clear message. Don't mask errors with defensive returns or empty catches—surface them.

### Prove It, Don't Assume It
"select isn't broken"—when something fails, the bug is almost certainly in your code. Don't blame the library, the OS, or the compiler until you've proven it. Test your assumptions explicitly.

### Names Over Comments
Good names eliminate comments. A comment that explains *what* the code does is a naming failure—rename until the comment is redundant, then delete it. Time spent on comments is better spent on names; the latter pays compound interest. See the **self-documenting-code** skill for naming methodology and comment survival criteria.

---

## Part 2: When to Refactor

Refactoring is changing code structure without changing behavior. It's a disciplined practice, not a free-for-all.

### The Rule of Three
First time, just do it. Second time, wince at the duplication but do it anyway. Third time, refactor. Premature extraction creates wrong abstractions. Wait for the pattern to prove itself.

### Preparatory Refactoring
The best time to refactor is right before adding a feature. Make the change easy, then make the easy change. If the code structure fights the new feature, reshape the structure first.

### Refactoring Is Not Rewriting
Refactoring preserves behavior; rewriting changes it. Don't mix them. If you need to change what code does, finish the refactoring first, then make the behavioral change. Two separate commits, two separate mental modes.

### Smell First, Refactor Second
Don't refactor "just because." Identify the specific smell: long method, feature envy, data clumps, primitive obsession, shotgun surgery. Name the problem before applying the solution. No smell, no refactor.

### Know When To Stop
Refactoring has diminishing returns. Stop when the code is "good enough" for the current need. Perfect structure for its own sake is gold plating. The goal is enabling the next change, not winning an award.

---

## Part 3: Code Smells Reference

Recognition guide for when refactoring is needed:

**Long Method** — Can't see the whole thing on screen. Extract smaller methods with intention-revealing names.

**Feature Envy** — Method uses another object's data more than its own. Move it to where the data lives.

**Data Clumps** — Same group of fields/parameters appear together repeatedly. Extract a class or struct.

**Primitive Obsession** — Using strings, ints, or booleans where a domain type would clarify intent.

**Shotgun Surgery** — One conceptual change requires edits in many places. Consolidate related behavior.

**Divergent Change** — One class changes for multiple unrelated reasons. Split responsibilities.

**Long Parameter List** — Method takes too many arguments. Introduce a parameter object or reconsider the design.

**Speculative Generality** — Abstraction for a use case that doesn't exist. Delete it.

---

## Part 4: Refactoring Discipline

### Small Steps, Always
Each refactoring move should take minutes, not hours. Extract, rename, move, inline—one at a time. Run tests after each step. If something breaks, you know exactly what caused it. Big-bang refactoring is rewriting in disguise.

### Tests Are Your Safety Net
Never refactor without tests covering the code you're changing. If tests don't exist, write them first—characterization tests that capture current behavior, even if that behavior is wrong. Refactoring without tests is gambling.

### Keep Behavior Visible
After refactoring, the code should still obviously do what it did before. If a reviewer can't tell behavior is preserved, the refactoring steps were too large or poorly sequenced.

### Separate Refactoring From Features
Keep refactoring commits separate from feature commits. Reviewers can't verify behavior preservation if you're also adding behavior. Two mental modes, two commits.

---

## Part 5: Verification Asymmetry

The best work exploits asymmetry: problems that are hard to solve but easy to verify.

### Speed Of Verification Trumps All
A solution you can verify in 10 seconds beats one that takes 10 minutes to validate, even if the latter is "better." Fast verification means fast iteration.

### Make Correctness Obvious
Structure output so verification requires minimal cognitive load. Clear naming, logical organization, before/after comparisons, small diffs. The reviewer shouldn't have to simulate execution in their head.

### Small Batches, Fast Feedback
Large changes are hard to verify. Small, focused changes are easy. Prefer many small PRs over one large one. Each atomic change should be independently verifiable. If you can't explain what changed in one sentence, it's too big.

### Objective Over Subjective
Prioritize work with clear success criteria. "The API returns the correct data" is verifiable. "The code is clean" is subjective. When requirements are fuzzy, clarify them before starting.

---

## Anti-Patterns

**Cargo Cult Programming** — Copying patterns without understanding why. If you can't explain the purpose, don't use it.

**Programming By Coincidence** — Code that works "somehow." If tests pass but you don't know why, you're not done.

**The Myth of "Later"** — Technical debt accrues interest. "We'll fix it later" usually means "we'll live with it forever."

**Gold Plating** — Adding features nobody asked for. Ship what's needed, then iterate based on feedback.

**Big-Bang Refactoring** — "Let me just clean this whole thing up." You'll break things and lose track. Small steps.

**Refactoring Without Tests** — You're not refactoring, you're editing and hoping. Write tests first.

**Refactoring For Its Own Sake** — "This could be cleaner" isn't a reason. What change does this enable?

---

## Quick Decision Framework

| Situation | Approach |
|-----------|----------|
| Adding feature to messy code | Preparatory refactoring first |
| See duplication for second time | Note it, don't extract yet |
| See duplication for third time | Now extract |
| Code works but you don't know why | Stop. Understand before continuing. |
| Under deadline pressure | Don't refactor. Ship, then schedule cleanup. |
| Tests don't exist | Write characterization tests before touching code |
| Change requires edits in 5+ places | Smell: shotgun surgery. Consider consolidating. |
| Method takes 8 parameters | Smell: long parameter list. Consider parameter object. |

---

## Related Skills

**For distributed systems** — service decomposition, cross-service communication, saga patterns, service mesh — use the **microservices-architect** skill instead. This skill covers single-service design; that skill covers multi-service architecture.
