# GBB Provisioning-v2 Phase 1 Benchmark Prompt

Implement only **Phase 1** from:

- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/provisioning-v2-phase1-backend.md`
- `/Users/martinburch/repos/dotfiles/docs/gbb-phase1-benchmark-2026-02-24.md`

Work only in this repository root (current working directory), expected to be `neb-ms-registry`.

## Scope

1. Extract add-on side effects into a service module.
2. Implement tier bundle resolution/apply logic for Phase 1.
3. Add DB migration for nullable `productBundle` and `insuranceBundle` on tenant.
4. Add/adjust unit tests for mapping and side effects.

## Hard Boundaries

1. No Phase 2+ endpoint work.
2. No changes outside this repo.
3. Keep changes within <= 12 files and <= 400 LOC unless explicitly justified.
4. If scope exceeds budget, stop and output a split/remediation plan.

## Assumptions To Preserve

1. Keep `good|better|best` as opaque keys.
2. Do not invent final `PROCLEAR/PROCLEAR_WAYSTAR` mapping; document TODO.
3. Keep `CT_INSIGHTS` behavior aligned with existing code patterns unless tests demand change.

## Required Output Before Completion

1. Concise implementation summary with changed files.
2. Test command(s) run and outcomes.
3. Remaining risks/open questions.

When all required Phase 1 work and tests are complete, print `LOOP_COMPLETE`.
