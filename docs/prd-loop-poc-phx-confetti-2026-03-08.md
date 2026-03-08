# PRD Loop POC: PHX_CONFETTI (2026-03-08)

> First end-to-end run of the prd-loop pipeline. Feature: login confetti celebration in neb-www.

## Pipeline

```
/create-prd  →  prd-loop.sh docs/prd-phx-confetti.md  →  3 phases  →  working feature
```

### 1. PRD Creation (`/create-prd` skill)

Interactive interview in Claude Code (6m30s total session):

1. **Seed** — user described the feature ("feature-flag gated confetti on login")
2. **Codebase exploration** — 3 parallel Explore agents mapped the relevant code:
   - Confetti: `canvas-confetti` library, wrapped in `confetti-util.js`, triggered from `.celebration-icon` in 2FA flow
   - Feature flags: `FEATURE_FLAGS` constants in `feature-util.js`, ~120 flags, checked via `hasFeatureOrBeta()`
   - Login flow: state machine in `neb-login-controller.js`, post-auth in `neb-session-state.js`, `loginSequenceId` for fresh login detection
3. **Interview** — 3 rounds (Problem & Value → Technical Shape → Acceptance), ~3 questions per round
4. **PRD output** — 70-line lean PRD with 4 functional requirements, 4 acceptance criteria, 6 codebase context entries, verification commands

**Observation**: The codebase exploration step was valuable — it grounded the interview questions in real file paths and patterns, and those references carried through to the decomposition and specs.

### 2. Decomposition (`prd-loop.sh`)

Claude decomposed the PRD into 3 phases (~2min):

| Phase | Title | Size | Rationale |
|-------|-------|------|-----------|
| phase-1 | Register PHX_CONFETTI feature flag | 1 line | Prerequisite — flag must exist before anything checks it |
| phase-2 | Add center-screen confetti trigger | ~30 lines + 132-line test file | Creates the function phase 3 calls |
| phase-3 | Wire confetti into practice app on login | ~33 lines + 352-line test file | Brings it all together |

Human approved phases, branch `prd-loop/phx-confetti` created.

### 3. Execution (automated, unattended)

All 3 phases completed on first attempt, zero retries.

| Phase | Duration (est.) | Codex Attempts | Peer Review | Commit |
|-------|----------------|----------------|-------------|--------|
| phase-1 | ~4min | 1 | Clean | `phase-1: Register PHX_CONFETTI feature flag` |
| phase-2 | ~8min | 1 | Clean | `phase-2: Add center-screen confetti trigger function` |
| phase-3 | ~12min | 1 | 1 Important fix (unhandled promise rejection) | `phase-3: Wire confetti into practice app on login` |

**Total automated execution: ~24min for 3 phases.**

### 4. Verification

Manual test: enabled `PHX_CONFETTI` flag for a test tenant via feature flags admin page, logged in — confetti appeared. Confirmed working.

## What Worked

- **Cross-phase context transfer** — `progress.txt` "Context for next phase" entries gave each fresh Claude instance enough information to build on prior work. Phase 3 correctly imported from both phase 1 (flag) and phase 2 (confetti function).
- **Peer review caught a real bug** — Phase 3's peer review found an unhandled promise rejection in `updated()`. Claude fixed it before committing. This is the quality gate working as designed.
- **Codex specs were well-scoped** — Each spec had targeted verification commands (single-file lint, targeted test files) rather than full suite runs. Phase 1 spec explicitly said "Do Not Touch: Any test files" which kept Codex focused.
- **Commit-per-phase** — 3 clean commits on a feature branch, each traceable to a phase. Easy to review or revert individually.
- **Codebase-grounded PRD** — The `create-prd` exploration step meant the PRD referenced real files, real patterns, and real conventions. This carried through to accurate decomposition and specs.

## What Didn't Work / Lessons

- **Codex can't run browser tests** — Codex's sandbox doesn't have Chrome, so Karma-based tests fail. This triggered "Chrome crashed" system dialogs. Phase specs should explicitly exclude browser test commands and note the sandbox limitation in `## Constraints`.
- **Overhead dominates small phases** — Phase 1 (1 line of code) took ~4min due to orchestration overhead (Codex startup, peer-review skill invocation, commit). The architecture pays for itself on phases with meaningful work (phases 2-3) but is expensive for trivial changes.
- **Full test suite risk** — Even with targeted `## Verify` commands in specs, Codex or Claude may still run broader test suites during review. This was the likely cause of the Chrome crashes. The phase prompt should be more explicit: "Only run the verification command from the spec. Do not run the full test suite."

## Architecture Validation

This POC validates the three-layer architecture from `research-ai-coding-automation.md`:

| Layer | Role | Validated? |
|-------|------|-----------|
| **Bash** (deterministic) | Loop, state, circuit breaker, branch, commit validation | Yes — branch created, 3 commits landed, state tracked correctly |
| **Claude** (orchestrator) | Plan, spec, review, peer-review, state update per phase | Yes — specs were self-contained, peer review caught a real issue |
| **Codex** (implementer) | Fresh context, implements one spec | Yes — clean implementations on first attempt for all 3 phases |

Key design decisions that held up:
- **Fresh context per phase** — no context rot across phases
- **File-backed state** — `state.json` + `progress.txt` were inspectable throughout
- **Human approval gate** — decomposition was reviewed before execution started
- **`claude -p` with skills** — confirmed skills (including peer-review) work in headless mode

## Comparison: prd-loop vs auto-agent-codex

Both tools implement the Ralph Loop pattern. This POC confirms prd-loop is viable for single-repo features. See `research-ai-coding-automation.md` for the full ecosystem analysis.

| Dimension | prd-loop (this run) | auto-agent-codex |
|-----------|-------------------|-----------------|
| PRD creation | `create-prd` skill (interview-driven) | Manual or external |
| Decomposition | 1 phase = 1 commit | 1 phase = 1 PR + 1 repo |
| Multi-repo | Not supported | First-class (`phase_owner` per phase) |
| Review | Peer-review skill (Claude) | PR review task (Codex) + remediation loop |
| Orchestrator | ~200 lines bash | ~2,269 lines JS |
| Best for | Single-repo features | Cross-repo features spanning microservices |

**PRD format is compatible** — `create-prd` output works with both tools. auto-agent-codex additionally needs a `prd_list.json` manifest (trivially generated).

## Backlog (from this POC)

1. **Add ID/Branch metadata to PRD header** — `create-prd` should ask for branch name during interview, embed in PRD. `prd-loop.sh` reads branch from PRD instead of deriving from filename.
2. **Sandbox test constraints in phase prompt** — Add explicit guidance: "Codex sandbox has no browser. Do not run Karma/Chrome-based tests. Only run the verification command from the spec."
3. **Thin adapter for auto-agent-codex** — Script that reads PRD metadata and generates `prd_list.json` manifest, enabling the same PRD to drive either pipeline.
4. **Stress test with larger PRD** — Run an 8-10 phase PRD to validate retry logic, circuit breaker, and cross-phase context at scale.
5. **JSON schema validation for state.json** — Replace `jq -e '.'` with proper schema check (types, required fields, valid status values).

## Saved Transcripts

/create-prd

⏺ I'll help you create a PRD. Let's start with the seed.

  What feature or capability do you want to define? You can provide:
  - A description of what you want to build
  - A path to an existing doc or ticket
  - Or just describe the idea and we'll go from there

❯ Ok for neb-www I want to create a feature-flag gated feature (PHX_CONFETTI) that, when enabled for a tenant, causes login to
   show confetti (similar to how 2fa setup shows confetti)

⏺ Seed summary: Tenant-gated feature flag PHX_CONFETTI that shows a confetti animation on successful login, reusing the existing
  confetti pattern from 2FA setup.

  Is that the right starting point? While you confirm, let me explore the codebase for relevant patterns.

⏺ 3 Explore agents finished (ctrl+o to expand)
   ├─ Explore confetti implementation · 14 tool uses · 27.4k tokens
   │  ⎿  Done
   ├─ Explore feature flag patterns · 31 tool uses · 67.9k tokens
   │  ⎿  Done
   └─ Explore login flow · 29 tool uses · 70.2k tokens
      ⎿  Done

⏺ Great, here's what I found in the codebase that's relevant:

  Confetti
  - Uses canvas-confetti library, wrapped in packages/neb-utils/confetti-util.js
  - Triggered in neb-security.js via triggerConfettiAtElement() — explodes from a .celebration-icon element
  - Configures 200 particles, 120° spread, green/blue/gold colors, z-index 9999

  Feature Flags
  - Defined in packages/neb-utils/feature-util.js as FEATURE_FLAGS constants (~120 flags)
  - PHX_ prefixed flags already exist (e.g., PHX_TREATMENT_PLAN_REDESIGN_V2, PHX_GBB_ENTITLEMENTS)
  - Checked via hasFeatureOrBeta(flagName) (async) or hasFeatureOrBetaSync(flagName) (sync)
  - Lit directive featureGate() available for conditional rendering
  - Feature flags admin UI exists at neb-form-feature-flags.js / neb-page-feature-flags.js

  Login Flow
  - Login state machine in neb-login-controller.js (handles login form, 2FA, tenant selection, etc.)
  - Post-auth logic in neb-session-state.js — dispatches SESSION_AUTHENTICATED
  - neb-practice-app.js responds to session becoming active, shows onboarding popups
  - No existing confetti or celebration animation on login success

  ---
  Now let's interview. Round 1: Problem & Value

  What problem does this solve, or is this more of a fun/engagement feature (team morale, tenant delight, etc.)? And what's the
  desired trigger — should confetti fire immediately after successful credential validation, or after tenant selection (for
  multi-tenant users)?

✻ Churned for 1m 41s

❯ This is both a fun excersize, and a way to smoke test the prd creation process.
   after successful credential validation is fine

⏺ Got it — fun exercise + PRD process smoke test. Confetti fires after successful credential validation.

  Round 2: Technical Shape

  A few targeted questions:

  1. Where to trigger — The login controller transitions through several states. Should confetti fire right when credentials are
  validated (before 2FA/tenant selection if those are needed), or only after the full login sequence completes and the practice app
   loads? Given the flow: credentials → optional 2FA → optional tenant selection → app loads.
  2. Confetti anchor element — In the 2FA flow, confetti explodes from a celebration icon. For login, should it fire from the login
   button, the center of the screen, or something else?
  3. One-shot behavior — Should confetti fire on every login for flagged tenants, or just once (like the 2FA celebration)?

❯ 1. Ideally after app loads
  2. Center of screen is fine
  3. Let's do it every time

⏺ Round 3: Acceptance

  Last few:

  1. Verification — Are there existing tests for the login flow or practice app load that we should extend, or is manual
  verification sufficient for this?
  2. What must NOT break — I assume the core login flow must remain unaffected when the flag is off. Anything else you're concerned
   about?
  3. Scope boundaries — Just to confirm: no admin UI changes needed (the flag just needs to be addable via the existing feature
  flags page), no backend changes, purely frontend?

❯ 1. Manual testing is enough for this
  2. No this obviously should not break anything else
  3. Adding the flag should be as simple as adding it to the right file, the rest of the pages should work fine

⏺ Clear. Let me write the PRD.

⏺ Write(docs/prd-phx-confetti.md)
  ⎿  Wrote 70 lines to docs/prd-phx-confetti.md
      1 # PRD: Login Confetti Celebration
      2
      3 > Status: Draft
      4 > Author: Martin Burch
      5 > Date: 2026-03-08
      6
      7 ## Problem & Outcome
      8
      9 There is no celebratory feedback when users log in. When the `PHX_CONFETTI` feature flag is enabled for a tenant, su
        ccessful login should trigger a confetti animation after the practice app loads, adding delight to the login experie
        nce.
     … +60 lines (ctrl+o to expand)

⏺ Readiness check:

  - Problem and outcome are specific
  - In-scope and out-of-scope are explicit
  - Requirements are decomposable (4 FRs, small scope)
  - Acceptance criteria are objective and testable
  - Verification commands exist in the project
  - Codebase context references real files
  - Constraints are actionable
  - One open question flagged (color scheme)

  ---
  Does this capture your requirements? Reply to proceed, or edit the PRD first.

  Once confirmed:

  PRD saved to: docs/prd-phx-confetti.md

  To decompose and execute:
    /prd-loop docs/prd-phx-confetti.md                        (interactive decompose + approve)

  Or directly in terminal:
    ~/.claude/scripts/prd-loop.sh docs/prd-phx-confetti.md    (non-interactive: full run)

✻ Brewed for 38s

❯ /exit
  ⎿  Goodbye!


~/.claude/scripts/prd-loop.sh docs/prd-phx-confetti.md

=== Decomposing PRD into phases ===
Decomposition complete. Three phases:

| Phase | Title | Key Files | Verification |
|-------|-------|-----------|-------------|
| **phase-1** | Register PHX_CONFETTI feature flag | `packages/neb-utils/feature-util.js`, test | Lint + feature-util unit test |
| **phase-2** | Add center-screen confetti trigger | `packages/neb-utils/confetti-util.js`, new test | Lint + confetti-util unit test |
| **phase-3** | Wire confetti into practice app on login | `packages/neb-www-practice/src/components/neb-practice-app.js`, test | Lint + practice-app unit test + build |

**Why this ordering:**
- Phase 1 is a prerequisite — the flag constant must exist before anything can check it
- Phase 2 creates the center-screen trigger function that phase 3 calls
- Phase 3 brings it all together — checks the flag on fresh login (via `loginSequenceId`) and fires confetti

Each phase is well under the 400-line / 12-file limits (phase 1 is ~3 lines, phase 2 is ~30 lines, phase 3 is ~50-80 lines).

=== Proposed 3 phases ===

  phase-1: Register PHX_CONFETTI feature flag
        Add the PHX_CONFETTI constant to the FEATURE_FLAGS object in feature-util.js following the existing PHX_* naming convention. This comes first because all subsequent phases depend on the flag existing.

  phase-2: Add center-screen confetti trigger function
        Add a triggerConfettiAtCenter() function to confetti-util.js that fires confetti from screen center (origin 0.5/0.5) without requiring an anchor element, plus unit tests. This comes second because the practice app integration in phase 3 needs this function.

  phase-3: Wire confetti into practice app on login
        In neb-practice-app.js, after session establishes on a fresh login (using loginSequenceId to distinguish from page refreshes), check the PHX_CONFETTI flag via hasFeatureOrBeta() and call triggerConfettiAtCenter(). Add corresponding unit tests.

Review the phases above. You can also edit .prd-loop/state.json directly.
Proceed with execution? [y/N] y

=== Starting execution loop ===
Switched to a new branch 'prd-loop/phx-confetti'
=== Created branch: prd-loop/phx-confetti ===

=== Phase: phase-1 — Register PHX_CONFETTI feature flag (attempt 1/3) ===
Phase 1 complete.

**Summary**: Added `PHX_CONFETTI: 'phx-confetti'` to the `FEATURE_FLAGS` object in `packages/neb-utils/feature-util.js:100`, placed alongside the existing `PHX_*` flags. ESLint passes, all existing tests pass, peer review clean (no findings). Committed as `08c4d1ed65`.
  1 commit(s) in this phase
=== Phase phase-1: completed ===

=== Phase: phase-2 — Add center-screen confetti trigger function (attempt 1/3) ===
Phase 2 is complete.

**Summary:**
- Added `triggerConfettiAtCenter(options)` to `packages/neb-utils/confetti-util.js` — fires confetti at screen center with origin `{ x: 0.5, y: 0.5 }`
- Extracted shared `styleConfettiCanvases()` helper to eliminate duplication between the two trigger functions
- Added `__confettiLib` test seam for stubbing `canvas-confetti`
- Created `packages/neb-utils/test/confetti-util.unit.test.js` with 6 tests — all passing
- ESLint clean, peer review clean (no Critical findings)
- Committed as `f164796531`
  1 commit(s) in this phase
=== Phase phase-2: completed ===

=== Phase: phase-3 — Wire confetti into practice app on login (attempt 1/3) ===
## Phase 3 complete.

**Summary**: Wired `triggerConfettiAtCenter()` into `neb-practice-app.js` to fire on every fresh login when the `PHX_CONFETTI` feature flag is enabled.

**Changes:**
- `neb-practice-app.js` — imported `triggerConfettiAtCenter`, added `__triggerLoginConfettiIfEnabled()` method with `loginSequenceId`-based de-duplication, called from `updated()` with try/catch protection
- `neb-practice-app-confetti.unit.test.js` — 4 tests covering: flag enabled, flag disabled, page refresh skip, repeat login fire

**Verification:** ESLint clean, 4/4 tests pass, peer review clean (no Critical findings).

All 3 PRD phases are now complete.
  1 commit(s) in this phase
=== Phase phase-3: completed ===

=== All phases complete ===
  phase-1 [completed]: Register PHX_CONFETTI feature flag
  phase-2 [completed]: Add center-screen confetti trigger function
  phase-3 [completed]: Wire confetti into practice app on login

=== Run complete. Review .prd-loop/progress.txt for details ===
