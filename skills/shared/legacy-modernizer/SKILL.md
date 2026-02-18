---
name: legacy-modernizer
description: Use when migrating legacy systems incrementally, replacing old APIs with new facades, planning strangler fig migrations, or managing dual-mode coexistence between old and new systems
---

# Legacy Modernizer

Incremental migration specialist for replacing legacy systems without big-bang rewrites. Applies the strangler fig pattern — wrap the old, build the new, migrate callers, retire the legacy.

## When to Use

- Replacing a legacy API with a new facade (e.g., `hasAddOn()` → `hasEntitlement()`)
- Planning incremental migration of call sites across a large codebase
- Designing dual-mode systems (legacy and new coexist per-tenant or per-flag)
- Managing feature-flag-gated rollout of new system behavior
- Assessing migration scope and risk before starting

## Core Workflow

1. **Assess** — Audit all call sites of the legacy API. Categorize by migration type (mechanical, logic change, architecture change). Map dependencies.
2. **Facade** — Build the new API as a wrapper that delegates to the legacy system. Callers can adopt the new API immediately with zero behavior change.
3. **Gate** — Use feature flags for per-tenant or per-environment rollout. When the flag is off, the facade passes through to legacy behavior.
4. **Migrate** — Convert call sites incrementally, one PR per logical group. Each migration is independently reversible.
5. **Validate** — Verify each migration preserves existing behavior for all flag states. Test both legacy and new paths.
6. **Retire** — Once all callers use the new API and the legacy path has zero traffic, remove the legacy code. This is the point of no return — confirm before proceeding.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Strangler Fig Pattern | `references/strangler-fig.md` | Designing facade wrappers, incremental replacement strategy |
| Migration Playbook | `references/migration-playbook.md` | Planning call site migration, categorizing migration types |
| Legacy Coexistence | `references/legacy-coexistence.md` | Dual-mode systems, feature flag gating, rollback strategies |

## Constraints

### MUST DO
- Audit all call sites before writing any migration code
- Build the facade first — callers adopt the new API before behavior changes
- Make each migration independently reversible via feature flags
- Test both legacy and new code paths in every migration PR
- Migrate in priority order: highest-risk or most-mechanical first
- Document the migration inventory and track progress per call site
- Preserve legacy fields/tables until the new system is fully validated

### MUST NOT DO
- Big-bang rewrite — never replace the entire system at once
- Delete legacy code before all callers are migrated and validated
- Change behavior and migrate callers in the same PR
- Skip the feature flag gate — every behavioral change needs a rollback path
- Assume legacy and new paths produce identical results without testing both
- Force-migrate tenants without a per-tenant rollback mechanism

## Related Skills

- **test-driven-development** — characterize existing behavior before migrating; plan migration test strategy
- **refactoring-guide** — for internal code structure decisions within a migration
- **microservices-architect** — for cross-service migration coordination
- **neb-ms-conventions** — for implementation patterns in neb services
