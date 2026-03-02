---
name: renovate-code
description: Use when improving existing code structure through refactoring, replacing legacy patterns incrementally, or planning structural changes before a feature. Not for greenfield implementation.
---

# Renovate Code

Improve existing code without rewriting from scratch. Covers two scales of the same discipline: **refactoring** (restructuring code within a module or file) and **legacy modernization** (incrementally replacing old systems with new ones). Both preserve behavior while changing structure.

## When to Use

- Preparatory refactoring before a feature — reshape structure first, then make the change
- Evaluating or addressing a specific code smell (long method, feature envy, shotgun surgery)
- Replacing a legacy API with a new facade incrementally
- Planning a strangler fig migration across a codebase
- Managing dual-mode coexistence between old and new systems

**Not for:** Greenfield implementation, routine code following existing patterns, or adding new behavior.

## Scale Assessment

Determine which scale applies before starting:

| Signal | Scale | Approach |
|--------|-------|----------|
| Smell in a single file or method | **Micro** | Extract, rename, move — small steps with tests |
| Same group of parameters/fields repeated | **Micro** | Extract class or struct for data clump |
| Code structure fights the next feature | **Micro** | Preparatory refactoring, then the feature |
| Replacing an API used across many files | **Macro** | Strangler fig: facade, gate, migrate, retire |
| Two systems must coexist per-tenant or per-flag | **Macro** | Dual-mode with feature flag routing |

---

## Refactoring (Micro Scale)

### Core Rules

- **Smell first, refactor second** — identify the specific smell before applying a solution. No smell, no refactor.
- **Rule of Three** — first time, do it. Second time, wince. Third time, extract.
- **Small steps** — each move takes minutes, not hours. Run tests after each step.
- **Separate from features** — refactoring commits and feature commits stay apart.
- **Know when to stop** — stop when structure supports the current need. Perfect structure is gold plating.

### Code Smells Quick Reference

| Smell | Signal | Move |
|-------|--------|------|
| Long Method | Can't see it all on screen | Extract with intention-revealing names |
| Feature Envy | Uses another object's data more than its own | Move to where the data lives |
| Data Clumps | Same fields/params appear together | Extract class or struct |
| Primitive Obsession | Strings/ints where a domain type would clarify | Introduce domain type |
| Shotgun Surgery | One change touches many files | Consolidate related behavior |
| Divergent Change | One class changes for unrelated reasons | Split responsibilities |
| Long Parameter List | Too many arguments | Parameter object or redesign |
| Speculative Generality | Abstraction for a nonexistent use case | Delete it |

### Quick Decisions

| Situation | Approach |
|-----------|----------|
| Adding feature to messy code | Preparatory refactoring first |
| Duplication seen twice | Note it, don't extract yet |
| Duplication seen three times | Now extract |
| Code works but you don't know why | Stop. Understand before continuing. |
| Under deadline pressure | Ship, then schedule cleanup |
| Tests don't exist | Write characterization tests first |
| Change requires edits in 5+ places | Smell: shotgun surgery. Consolidate. |

---

## Legacy Modernization (Macro Scale)

Apply the strangler fig pattern: wrap the old, build the new, migrate callers, retire the legacy.

### Core Workflow

1. **Assess** — Audit all call sites. Categorize by migration type (mechanical, logic change, architecture change). Map dependencies.
2. **Facade** — Build the new API as a wrapper that delegates to legacy. Callers adopt immediately with zero behavior change.
3. **Gate** — Feature flags for per-tenant or per-environment rollout. Flag off = passthrough to legacy.
4. **Migrate** — Convert call sites incrementally, one PR per logical group. Each independently reversible.
5. **Validate** — Verify each migration preserves behavior for all flag states. Test both paths.
6. **Retire** — All callers on new API + zero legacy traffic = remove legacy code. Point of no return.

### Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Strangler Fig Pattern | `references/strangler-fig.md` | Designing facade wrappers, incremental replacement strategy |
| Migration Playbook | `references/migration-playbook.md` | Planning call site migration, categorizing migration types |
| Legacy Coexistence | `references/legacy-coexistence.md` | Dual-mode systems, feature flag gating, rollback strategies |

---

## Constraints

### MUST DO
- Identify the specific smell (micro) or audit all call sites (macro) before changing code
- Write characterization tests before touching untested code
- Run tests after each step
- Keep refactoring and migration commits separate from feature commits
- Make each migration independently reversible via feature flags
- Test both legacy and new code paths in every migration PR
- Stop after one refactoring move unless asked to continue

### MUST NOT DO
- Mix structural changes with behavioral changes in the same commit
- Big-bang rewrite or big-bang switchover — never replace everything at once
- Refactor or migrate without test coverage
- Chain multiple refactorings without user direction
- Delete legacy code before all callers are migrated and validated
- Add abstractions for hypothetical future use cases
- Skip the feature flag gate on behavioral changes

## Anti-Patterns

| Anti-Pattern | Why It Fails |
|-------------|-------------|
| Big-Bang Refactoring | You'll break things and lose track. Small steps. |
| Refactoring Without Tests | You're editing and hoping, not refactoring. |
| Refactoring For Its Own Sake | "Could be cleaner" isn't a reason. What change does this enable? |
| The Refactoring Pendulum | Extract, inline, extract again. Respect recent decisions with stated rationale. |
| Facade That Modifies Behavior | Callers can't trust the migration is safe. |
| Migrating Before Facade Is Stable | Moving target breaks already-migrated callers. |

## Related Skills

- **self-documenting-code** — for naming and readability, not structural changes
- **test-driven-development** — for characterization tests before refactoring or migration test strategy
- **api-designer** — for request/response contract evolution during migration
- **neb-ms-conventions** — for implementation patterns in neb services
