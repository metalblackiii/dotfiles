# GBB Phase 1 Benchmark Spec (Canonical)

Date: 2026-02-24

## Objective

Run a controlled, apples-to-apples benchmark of `ralph-orchestrator` and `ptek-ai-playbook` on `provisioning-v2` **Phase 1 only**.

## Source Inputs

- `/Users/martinburch/repos/neb-www/docs/features/gbb-pricing-model/provisioning-v2-phase1-backend.md`
- `/Users/martinburch/repos/dotfiles/docs/gbb-harness-tooling-analysis-2026-02-23.md` (Section 11)

## Scope Lock

In scope:

1. Extract add-on side effects from:
   - `src/controllers/v1/tenants/:tenantId/addons/post.js`
2. Implement a tier resolver/apply service (`applyBundles`) that maps:
   - `productTier` + `insuranceTier` -> billing flags + entitlements
3. Add DB migration for nullable tenant columns:
   - `productBundle`
   - `insuranceBundle`
4. Add/adjust unit tests for mapping and side-effect firing behavior

Out of scope:

1. New v2 endpoint implementation (`POST /v2/tenants`, `PATCH /v2/tenants/:tenantId/tier`)
2. Salesforce integration work
3. Legacy migration waves/tooling
4. UI/support-app work
5. Changes in repos outside `neb-ms-registry`

## Assumption Block (Frozen For Benchmark)

1. Tier identifiers remain `good|better|best` for this run and are treated as opaque keys in a single constants source.
2. `PROCLEAR`/`PROCLEAR_WAYSTAR` final placement is unresolved; preserve current behavior and document TODOs rather than inventing new matrix rules.
3. `CT_INSIGHTS` gate semantics are unresolved; keep behavior aligned with existing code patterns and document any assumption explicitly.
4. Phase 1 remains internal refactor/schema prep only; no public contract changes.
5. Side effects (Doctible notifications, RCM flags, etc.) must preserve existing behavior unless explicitly covered by tests showing intended change.

## Hard Stops

1. Do not implement Phase 2+ behavior.
2. Do not exceed decomposition guardrails without explicit exception:
   - <= 12 files changed
   - <= 400 LOC changed
3. If guardrails are exceeded, stop and produce a split/remediation plan.
4. Do not touch secrets or non-scope infrastructure config.

## Required Deliverables

1. Phase 1 plan listing files, test strategy, and stop conditions
2. Implementation changes in `neb-ms-registry`
3. Test evidence for new/updated unit tests
4. Review report with severity-tagged findings and remediation tasks if needed
