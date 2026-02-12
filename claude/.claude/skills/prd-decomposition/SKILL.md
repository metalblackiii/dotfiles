---
Name: prd-decomposition
Description: Decompose Product Requirements Documents (PRDs) into atomic, reviewable implementation phases. Use when breaking down feature specs, technical designs, or product requirements into sequential branches and pull requests. Provides heuristics for phase ordering, dependency analysis, atomicity criteria, and PR sizing. Enforces working-state invariant where each phase leaves the codebase compilable and testable.
---

# PRD Decomposition Skill

Domain knowledge for breaking down Product Requirements Documents into atomic, reviewable implementation phases. Each phase becomes a separate branch and pull request that can be independently reviewed and merged.

## Phase Ordering Heuristics

Order phases by dependency depth -- foundational layers first, consumer layers last:

| Order | Layer | Examples |
|-------|-------|----------|
| 1 | Types & Interfaces | Shared types, DTOs, enums, contracts |
| 2 | Data Layer | Database schema, migrations, models, repositories |
| 3 | Business Logic | Services, domain logic, validation rules |
| 4 | API / Integration | Controllers, endpoints, middleware, external service clients |
| 5 | UI / Presentation | Components, pages, forms, styling |
| 6 | Tests & Validation | Integration tests, e2e tests, test fixtures |
| 7 | Documentation & Cleanup | README updates, API docs, migration guides |

**When in doubt:** If Phase B imports or references anything from Phase A, then A comes first.

## Atomicity Criteria

Every phase **must** satisfy all three conditions:

1. **Builds** -- The codebase compiles/transpiles without errors after the phase is applied
2. **Passes tests** -- All existing tests continue to pass (new tests may be added)
3. **Is independently understandable** -- A reviewer can read the PR in isolation and understand what it does and why

A phase that breaks any of these conditions must be split further or merged with an adjacent phase.

## Sizing Guidelines

Target **100-400 lines changed** per phase (additions + deletions).

| Size | Lines Changed | Action |
|------|--------------|--------|
| Too small | < 50 | Merge with adjacent phase |
| Ideal | 100-400 | Ship it |
| Acceptable | 400-600 | OK if logically cohesive |
| Too large | > 600 | Split into sub-phases |

**Exceptions:**
- Auto-generated code (migrations, scaffolding) can exceed limits
- Schema or type definition files may be large but remain cohesive
- Test files accompanying a feature phase can push over the limit

## Common Phase Patterns

| Pattern | Description | When to Use |
|---------|-------------|-------------|
| **Foundation** | Types, interfaces, shared utilities | Starting a new feature domain |
| **Schema** | Database migrations, model definitions | Feature requires new or modified data |
| **Service** | Business logic layer with unit tests | Core logic that other layers consume |
| **API** | Controllers/endpoints with route tests | Exposing functionality via HTTP |
| **UI** | Components, pages, styling | User-facing features |
| **Integration** | Wire components together, integration tests | Connecting layers end-to-end |
| **Polish** | Error handling, edge cases, UX improvements | Hardening after core functionality |
| **Documentation** | README, API docs, architecture docs | Final phase of a feature |

## Dependency Analysis

Before ordering phases, build a dependency graph:

1. **Identify entities** -- List all new types, services, components, endpoints, and schemas the PRD requires
2. **Map dependencies** -- For each entity, list what it imports or references
3. **Topological sort** -- Order entities so every dependency is implemented before its consumer
4. **Group into phases** -- Cluster entities at the same dependency depth into a single phase (if sizing allows)

**Circular dependencies** indicate a design problem. Resolve by:
- Extracting a shared interface into a Foundation phase
- Using dependency inversion (depend on abstractions, not implementations)
- Introducing an event-based or callback pattern

## Working-State Invariant

After applying **any** phase to the codebase, the following must hold:

- `build` / `compile` succeeds with zero errors
- All **pre-existing** tests pass (new code may have tests added in the same or later phase)
- No dead imports or references to not-yet-created entities
- No feature flags required to hide incomplete work (each phase is complete in its own scope)
- The application can start and serve traffic (existing functionality unaffected)

**How to maintain this invariant:**
- Never reference code that doesn't exist yet -- stub it in the current phase if needed
- Add new code as additive (new files, new functions) rather than modifying existing signatures until consumers are ready
- If a signature must change, update all callers in the same phase
- Use interface-first design so implementations can be swapped in later phases

## PR Description Quality Guidelines

Each phase PR description should include:

1. **Summary** -- One paragraph explaining what this phase does and why
2. **PRD context** -- Which requirements from the PRD this phase addresses
3. **Changes** -- Bulleted list of files created or modified with brief explanations
4. **Validation** -- Checklist of how this was verified (build, tests, manual checks)
5. **Phase context** -- "Phase {N} of {total}" with brief note on what comes next
6. **Risks & mitigations** -- Known risks and how they were addressed
7. **Review guidance** -- What reviewers should focus on

## Anti-Patterns

### Mega-Phase
**Symptom:** A single phase with 1000+ lines touching multiple layers.
**Fix:** Split by layer (data, logic, API, UI) or by feature slice.

### Skeleton Phase
**Symptom:** Phase creates empty files, stub classes, or no-op implementations with no real logic.
**Fix:** Combine with the phase that fills in the implementation. Every phase should deliver working functionality.

### Tangled Phase
**Symptom:** Phase mixes unrelated concerns (e.g., database migration + UI component + config change).
**Fix:** Split into separate phases, one per concern. Each phase should have a single clear purpose.

### Forward-Reference Phase
**Symptom:** Phase imports or references code that hasn't been created yet.
**Fix:** Reorder phases so dependencies come first, or create the referenced types/interfaces as stubs in the current phase.

### Test-Last Pile-Up
**Symptom:** All tests deferred to a single "add tests" phase at the end.
**Fix:** Include unit tests alongside the code they test within the same phase. Reserve a separate test phase only for integration or e2e tests that span multiple phases.

### Breaking Change Phase
**Symptom:** Phase modifies existing interfaces or signatures without updating all consumers.
**Fix:** Either update all consumers in the same phase, or use an additive approach (new function alongside old) and deprecate in a later phase.
