---
name: test-architect
description: Use when planning high-level test strategy for features, migrations, or refactoring before implementation begins — especially when existing code needs characterization tests before changes
---

# Test Architect

Strategic test planning for features that touch existing code. TDD handles new code excellently — this skill handles the question that comes before: "what should we test, at which layer, and in what order?"

## When to Use

- Planning test coverage for a migration (e.g., many call sites changing)
- Deciding what test layers a feature needs (unit, integration, E2E)
- Introducing tests to untested existing code before modifying it
- Assessing whether current test coverage is sufficient for a planned change

## When NOT to Use

- Writing a single new function with clear inputs/outputs → use `test-driven-development`
- Running or debugging existing tests → use `systematic-debugging`

## The Test Pyramid

| Layer | Tests | Speed | Confidence | When |
|-------|-------|-------|------------|------|
| **Unit** | Isolated function/module behavior | Fast | Logic correct | Always for new code |
| **Integration** | Service boundaries, API contracts, DB queries | Medium | Components work together | Cross-boundary behavior |
| **E2E** | User workflows through the full stack | Slow | System works as user expects | Critical user journeys |

**Default ratio:** Many unit, some integration, few E2E. But migrations may invert this — characterization tests at E2E level catch regressions that unit tests miss.

## Strategy Framework

### 1. Assess What Exists

Before writing any test plan:
- What test coverage exists today for the code you're changing?
- What's the risk if existing behavior breaks silently?
- Are there manual QA scripts or runbooks that document expected behavior?

### 2. Characterize Before Changing

For existing code without tests, write **characterization tests** first:
- Test current behavior as-is, including quirks
- These aren't asserting correctness — they're capturing the contract
- If a characterization test fails after your change, you changed behavior (intentionally or not)

See `references/characterization-testing.md` for patterns.

### 3. Prioritize by Risk

Not all code paths deserve equal testing effort:

| Priority | Criteria | Example |
|----------|----------|---------|
| **P0** | Revenue/data-critical, high traffic | Payment processing, patient records |
| **P1** | User-facing, complex branching | Entitlement checks, scheduling logic |
| **P2** | Internal, mechanical changes | Rename, parameter reorder |
| **P3** | Dead code paths being removed | Legacy fallbacks |

### 4. Choose the Right Layer

| Scenario | Layer | Why |
|----------|-------|-----|
| New pure function | Unit | Fast, isolated, TDD-friendly |
| API endpoint behavior | Integration | Tests contract, catches middleware issues |
| "User on tier X sees Y" | E2E | Only full stack proves the experience |
| Database migration | Integration | Verify data integrity across migration |
| Feature flag toggle | E2E + Unit | E2E for user experience, unit for flag logic |

### 5. Plan for Migration Testing

See `references/migration-testing.md` for before/after validation, canary testing, and feature flag coverage.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Characterization Testing | `references/characterization-testing.md` | Introducing tests to untested existing code |
| Migration Testing | `references/migration-testing.md` | Before/after validation, feature flag testing, canary patterns |

## Integration with Other Skills

- **test-driven-development** — After test-architect determines what to test, TDD handles the red-green-refactor cycle for each test
- **neb-playwright-expert** — When E2E coverage is needed, neb-playwright-expert handles neb-www implementation details
- For complex features (>5 test cases across multiple layers), recommend dispatching **qa-engineer agent**

## Constraints

### MUST DO
- Assess existing coverage before planning new tests
- Write characterization tests before modifying untested code
- Prioritize test cases by risk, not by ease of writing
- Specify which test layer for each test case in the plan

### MUST NOT DO
- Skip characterization and jump to refactoring untested code
- Aim for "100% coverage" — aim for confidence in the specific change
- Write E2E tests for logic that unit tests cover (test at the lowest effective layer)
- Treat all code paths as equal priority
