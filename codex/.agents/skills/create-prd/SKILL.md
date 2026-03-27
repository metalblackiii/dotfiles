---
name: create-prd
description: ALWAYS invoke when defining what to build before an AI implementation run, formalizing a feature idea, converting a ticket into an implementation-ready PRD, or writing feature specifications with structured requirements and acceptance criteria. Not for analyzing existing tickets or specs — use requirements-analyst.
---

# Create PRD

Interview-driven PRD generator. Produces lean PRDs optimized for decomposition and phased AI implementation.

## When to Use

- Defining what to build before kicking off an AI implementation run (auto-agent-codex, ralph loop tool, or direct AI)
- Converting a ticket, spec, or conversation into a structured PRD
- When you have a feature idea but need to formalize scope, requirements, and acceptance criteria

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Interview Questions | `references/interview-questions.md` | Neb-specific questions, structured elicitation techniques, PM/Dev hat question banks |
| Specification Template | `references/specification-template.md` | Neb-specific spec sections (feature gating, cross-service impact, Kafka events) |
| Acceptance Criteria | `references/acceptance-criteria.md` | Writing Given/When/Then acceptance criteria with neb examples |

## Step 1 — Seed

Determine starting context from input:

- **Feature description provided**: Use it as the seed for the interview
- **Path to existing doc**: Read it, extract requirements as seed
- **Conversation context available**: Summarize relevant context as seed

Display the seed summary and confirm: "Is this the right starting point?"

## Step 2 — Codebase Exploration + Scope Assessment

Before interviewing, explore the codebase to ground questions in reality:

1. Identify which files, patterns, and services relate to the feature
2. Note existing conventions (test patterns, API styles, directory structure)
3. Check for related feature flags, configuration, or existing partial implementations

Summarize findings: "Here's what I found in the codebase that's relevant..."

### Scope Assessment (Preliminary)

After exploration, estimate the blast radius. This is a **preliminary signal** — the user hasn't clarified scope yet, so don't gate or split here. Note the estimate and carry it into the interview.

| Dimension | Small | Medium | Large |
|-----------|-------|--------|-------|
| Subsystems | 1 | 2 | 3+ |
| Estimated Files | ≤12 | 13–20 | >20 |

Classify each dimension independently, then take the **higher** result. Examples: 1 subsystem + 15 files = Medium. 2 subsystems + 25 files = Large. Either dimension reaching Large is sufficient.

| Overall Scope | Action |
|---------------|--------|
| Small / Medium | Note it, proceed to interview |
| Large | Flag it — "Based on codebase exploration, this looks like it may span N subsystems. We'll revisit scope after the interview." |

Count distinct subsystems as: separate repos, or separate services within a repo. Don't count layers (data/API/UI) within a single service as separate subsystems — vertical slices through one service are normal.

**After Round 1 (scope clarification):** revisit the estimate with the user's confirmed scope. If still Large, propose specific PRD boundaries with dependency ordering and ask the user to confirm before continuing.

## Step 3 — Interview

Conduct a focused interview. Ask questions **one topic at a time** — not a wall of questions.

### Round 1: Problem & Value (PM Hat)
- What problem does this solve? Who experiences it?
- What's the desired outcome if this succeeds?
- What's in scope for this iteration? What's explicitly out?

### Round 2: Technical Shape (Dev Hat)
- Which parts of the codebase are affected? (use Step 2 findings)
- Are there security, compliance, or performance constraints?
- Does this replace existing behavior or add new behavior?
- What are the key edge cases?

### Round 3: Acceptance (Both Hats)
- How will we know each piece is done? (push for testable criteria)
- What verification commands exist? (test suites, build, lint)
- What must NOT break?

### Round 4: Slug & Branch
Derive a slug from the feature name (e.g., `login-confetti-celebration`). Propose a branch name — default to the slug itself. Present both to the user for confirmation before writing the PRD:

"Proposed slug: `<slug>` / Branch: `<branch-name>` — OK, or would you like to change either?"

The user can override slug, branch, or both. Once confirmed, these are locked for the PRD and manifest.

For neb features touching multi-tenant, feature gating, or cross-service concerns, load `references/interview-questions.md` for deeper question banks and structured elicitation guidance.

Use **structured choices** when answers have a finite set (priority, scope level, auth approach). Use **open-ended** questions for problem description, user journey, edge cases.

After each round, summarize what you heard and confirm before moving on.

## Step 4 — Approach Exploration

After the interview and before writing, present 2-3 implementation approaches with trade-offs. Don't anchor on one approach — give the user genuine choice over architectural direction.

For each approach, cover:
- **Name** — a short label (e.g., "Polling-based", "Event-driven")
- **How it works** — 2-3 sentences
- **Trade-offs** — what you gain, what you pay
- **Fits best when** — the conditions that make this approach the right call

Present them side-by-side, then ask: "Which approach fits best, or would you like to explore a hybrid?"

The selected approach becomes the architectural backbone of the PRD. Capture the decision and reasoning in the Constraints section so downstream agents don't revisit it.

**Skip only if** the user explicitly says they've already chosen an approach (e.g., "I want to use WebSockets" during the interview). In that case, confirm the choice and note it — don't silently skip.

## Step 5 — Write the PRD

Use the slug and branch name confirmed in the interview (Step 3, Round 4). Write to the path: `docs/prd-<slug>.md`.

Use this lean format — optimized for AI-driven phase decomposition. For neb features needing feature gating tables, cross-service impact matrices, or Kafka event mappings, load `references/specification-template.md` for expanded section templates.

```markdown
# PRD: [Feature Title]

> Status: Draft
> Author: [user]
> Date: [today]
> ID: [slug]
> Branch: [branch-name]

## Problem & Outcome

[What problem, for whom, desired end state. 2-3 sentences.]

## Repositories

[Always list every affected repo — even for single-repo features.
Agents and loop tools read this to know which repos to clone, branch,
or verify. A single-row table is fine.]

| Repo | Role | Changes |
|------|------|---------|
| `repo-name` | Primary implementation | [what code lives here] |
| `other-repo` | Operational impact (no code) | [config or infra changes, verification steps] |
| `another-repo` | Verification target (no code) | [what to smoke-test] |
| `ref-repo` | Reference only | [patterns to follow] |

Roles: `Primary implementation`, `Operational impact (no code)`, `Verification target (no code)`, `Reference only`, `Potential update`. Mark new repos with **(NEW — org name)**.

## Scope

### In Scope
1. [Specific capability or behavior]
2. [Specific capability or behavior]

### Out of Scope
1. [Explicit non-goal — prevents agent drift]
2. [Explicit non-goal]

## Requirements

### Functional
Use EARS format (Event/Action/Response/State):

- **FR-1: [Name]** — When [trigger], the system shall [response].
- **FR-2: [Name]** — While [state], when [trigger], the system shall [response].

### Non-Functional
- **Security**: [authn/authz, PHI/PII handling, audit requirements]
- **Performance**: [latency, throughput, data volume expectations]
- **Compliance**: [HIPAA, SOC2, or N/A]

## Codebase Context

[Key files, existing patterns, services affected, relevant conventions.
This section grounds the PRD in reality — agents read this to understand
where and how to implement.]

- `path/to/relevant/file` — [what it does, why it matters]
- `path/to/pattern/example` — [convention to follow]

## Acceptance Criteria

Each criterion must be objectively testable. Load `references/acceptance-criteria.md` for Given/When/Then patterns and neb-specific examples (feature gating, authorization, legacy compat).

- **AC-1**: Given [precondition], when [action], then [expected result]
- **AC-2**: Given [precondition], when [action], then [expected result]

## Verification

Commands that confirm correctness:
- Build: `[command]`
- Test: `[command]`
- Lint: `[command]`

## Constraints

**Chosen approach**: [Name from Step 4] — [1-sentence rationale]

[Patterns to follow, API contracts to maintain, things not to break,
files not to touch. Agents read this as guardrails.]

## Open Questions

- [ ] [Unresolved question — resolve before or during implementation]
```

### Section Guidance

| Section | Purpose for Decomposition | Required? |
|---------|--------------------------|-----------|
| Problem & Outcome | Orients decomposition — what are we building toward | Yes |
| Repositories | Tells agents/loop tools which repos to clone, branch, or verify | Yes |
| Scope | Prevents agent drift during implementation | Yes |
| Functional Requirements | Drives phase decomposition — each FR maps to work | Yes |
| Non-Functional | Constraints every phase must respect | Yes |
| Codebase Context | Grounds specs in real code — reduces hallucination | Yes |
| Acceptance Criteria | Review step uses these to evaluate each phase | Yes |
| Verification | Agent runs these commands to validate | Yes |
| Constraints | Guardrails for the implementing agent — what NOT to do | Yes |
| Open Questions | Flags risk — decompose step can route these to early phases | Recommended |

## Step 6 — Readiness Check

Before saving, verify against the quality bar:

- [ ] Problem and desired outcome are specific (not vague)
- [ ] Repositories section included with at least the primary repo (roles and changes specified)
- [ ] In-scope and out-of-scope are explicit
- [ ] Requirements are specific enough to decompose into ≤12-file phases
- [ ] Acceptance criteria are objective and testable (not "looks good")
- [ ] Verification commands actually exist in the project
- [ ] Codebase context references real files (not assumed)
- [ ] Constraints include the chosen approach from Step 4 with rationale
- [ ] Constraints are actionable (not aspirational)
- [ ] Open questions are either resolved or explicitly deferred

If any fail, identify which ones and suggest how to fix them.

## Step 7 — Present and Save

Show the complete PRD. Ask:

"Does this capture your requirements? Reply to proceed, or edit the PRD first."

After confirmation, save the PRD to `docs/prd-<slug>.md`.

Then ask: "Would you like me to generate an auto-agent-codex manifest too?"

If yes, generate at `docs/prd_list-<slug>.json` — colocated with the PRD so they travel as a pair (one manifest per PRD — do not append to existing manifests for different projects). See `references/auto-agent-codex-prd-list.example.json` for the schema:

```json
{
  "version": "1.0",
  "project_name": "<slug>",
  "state_dir": ".<slug>",
  "log_dir": ".<slug>/agent_logs-codex",
  "experimental_playwright_validation_enabled": false,
  "prds": [
    {
      "id": "prd-<slug>",
      "prd_path": "prd-<slug>.md",
      "branch_name": "<branch-name>",
      "description": "<one-line summary from Problem & Outcome>"
    }
  ]
}
```

Display next steps. Adapt the block based on whether the manifest was generated and whether `/requirements-analyst` was already invoked during this session.

**Requirements-analyst check:** If `/requirements-analyst` was already invoked on this PRD during the current session, omit the "Before implementation, consider running /requirements-analyst" line. Only include it if the skill was NOT run.

**If manifest was generated:**
```
PRD saved to: docs/prd-<slug>.md
Manifest saved to: docs/prd_list-<slug>.json

[Only if /requirements-analyst was NOT run this session:]
Before implementation, consider running /requirements-analyst on the PRD
to surface gaps, risks, and hidden assumptions a fresh perspective catches.

Execute with:
  1. AI direct:         Open the PRD in Claude Code or Codex and implement directly
  2. auto-agent-codex:  Manifest generated at docs/prd_list-<slug>.json
                         (requires auto-agent-codex runner installed separately)
  3. Ralph loop tool:   Feed the PRD to any iterative execution runner (e.g., ralph, prd-loop)
```

**If manifest was skipped:**
```
PRD saved to: docs/prd-<slug>.md

[Only if /requirements-analyst was NOT run this session:]
Before implementation, consider running /requirements-analyst on the PRD
to surface gaps, risks, and hidden assumptions a fresh perspective catches.

Execute with:
  1. AI direct:         Open the PRD in Claude Code or Codex and implement directly
  2. Ralph loop tool:   Feed the PRD to any iterative execution runner (e.g., ralph, prd-loop)
```

## Constraints

- **Interview before writing** — do not generate a PRD from assumptions
- **Explore approaches before committing** — do not write the PRD around a single approach without presenting alternatives (Step 4)
- **Lean format by default** — do not add rollout plans, metrics dashboards, or approval logs. For neb features, reference files may expand existing sections (e.g., feature gating detail within Scope, cross-service impact within Codebase Context) but do not add top-level sections that the template doesn't define
- **Codebase-grounded** — every codebase context entry must reference real files you've verified exist
- **EARS format** for functional requirements — keeps them parseable and unambiguous
- **One PRD per invocation** — if the scope assessment (revisited after Round 1) confirms Large, propose specific PRD boundaries before continuing

### Red Flags — Rationalizations That Skip Steps

If you catch yourself thinking any of these, stop and follow the process:

| Rationalization | Reality |
|----------------|---------|
| "The user already described what they want, I don't need to interview" | Descriptions are incomplete. The interview surfaces what they forgot. |
| "This is a simple feature, I can skip codebase exploration" | Simple features in complex codebases still need grounding. |
| "I already know the right approach" | You don't. Present options (Step 4). |
| "The requirements are clear enough without EARS format" | Unstructured requirements create ambiguous decomposition. |
| "One acceptance criterion is enough for this" | One criterion means one thing gets tested. Everything else is assumed. |
| "The scope is obviously fine, I don't need to count subsystems" | Count anyway. The heuristic exists because vibes-based scoping fails. |
