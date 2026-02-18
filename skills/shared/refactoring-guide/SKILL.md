---
name: refactoring-guide
description: Use when explicitly refactoring code, when preparatory refactoring is needed before a feature, or when evaluating a specific code smell. Not for routine implementation that follows existing patterns.
disable-model-invocation: true
---

# Refactoring Guide

Refactoring is changing code structure without changing behavior. It's a disciplined practice, not a free-for-all. General design principles live in CLAUDE.md — this skill covers when, why, and how to refactor.

---

## When to Refactor

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

## Code Smells Reference

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

## Refactoring Discipline

### Small Steps, Always
Each refactoring move should take minutes, not hours. Extract, rename, move, inline—one at a time. Run tests after each step. If something breaks, you know exactly what caused it. Big-bang refactoring is rewriting in disguise.

### Tests Are Your Safety Net
Never refactor without tests covering the code you're changing. If tests don't exist, write them first—characterization tests that capture current behavior, even if that behavior is wrong. Refactoring without tests is gambling.

### Keep Behavior Visible
After refactoring, the code should still obviously do what it did before. If a reviewer can't tell behavior is preserved, the refactoring steps were too large or poorly sequenced.

### Separate Refactoring From Features
Keep refactoring commits separate from feature commits. Reviewers can't verify behavior preservation if you're also adding behavior. Two mental modes, two commits.

### One Move, Then Stop
After completing one refactoring move, stop. Run tests. Verify. Do not chain additional refactorings unless the user explicitly asks. The refactoring pendulum — where successive improvements oscillate between extracting and inlining — wastes time and erodes trust.

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

## Constraints

### MUST DO
- Identify the specific smell before refactoring (no smell, no refactor)
- Write characterization tests before touching untested code
- Run tests after each refactoring step
- Keep refactoring commits separate from feature commits
- Stop after one refactoring move unless asked to continue

### MUST NOT DO
- Refactor without tests covering the affected code
- Mix refactoring with behavioral changes in the same commit
- Chain multiple refactorings without user direction
- Add abstractions for hypothetical future use cases
- Re-evaluate design decisions made earlier in the same session unless explicitly asked

---

## Anti-Patterns

**Big-Bang Refactoring** — "Let me just clean this whole thing up." You'll break things and lose track. Small steps.

**Refactoring Without Tests** — You're not refactoring, you're editing and hoping. Write tests first.

**Refactoring For Its Own Sake** — "This could be cleaner" isn't a reason. What change does this enable?

**The Refactoring Pendulum** — Extract a module, then inline it next session, then extract again. If code was recently refactored with stated rationale, respect that decision.

---

## Related Skills

- **self-documenting-code** — for naming and readability improvements (not structural refactoring)
- **test-architect** — for planning characterization tests before refactoring
- **microservices-architect** — for cross-service structural changes (this skill covers single-service refactoring)
