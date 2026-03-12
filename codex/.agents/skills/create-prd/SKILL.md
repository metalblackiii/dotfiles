---
name: create-prd
description: ALWAYS invoke when defining what to build before a prd-loop run, formalizing a feature idea, converting a ticket into an implementation-ready PRD, or writing feature specifications with structured requirements and acceptance criteria. Not for analyzing existing tickets or specs — use requirements-analyst.
---

# Create PRD

Interview-driven PRD generator. Produces lean PRDs optimized for decomposition and phased AI implementation via the `prd-loop` CLI.

## When to Use

- Defining what to build before kicking off a prd-loop run
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

## Step 2 — Codebase Exploration

Before interviewing, explore the codebase to ground questions in reality:

1. Identify which files, patterns, and services relate to the feature
2. Note existing conventions (test patterns, API styles, directory structure)
3. Check for related feature flags, configuration, or existing partial implementations

Summarize findings: "Here's what I found in the codebase that's relevant..."

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

For neb features touching multi-tenant, feature gating, or cross-service concerns, load `references/interview-questions.md` for deeper question banks and structured elicitation guidance.

Use **structured choices** when answers have a finite set (priority, scope level, auth approach). Use **open-ended** questions for problem description, user journey, edge cases.

After each round, summarize what you heard and confirm before moving on.

## Step 4 — Write the PRD

Derive a slug from the feature name (e.g., `phx-confetti`). Propose a branch name based on the slug — default to the slug itself (e.g., `phx-confetti`). The user can override either. Write to the path: `docs/prd-<slug>.md`.

Use this lean format — optimized for prd-loop decomposition. For neb features needing feature gating tables, cross-service impact matrices, or Kafka event mappings, load `references/specification-template.md` for expanded section templates.

```markdown
# PRD: [Feature Title]

> Status: Draft
> Author: [user]
> Date: [today]
> ID: [slug]
> Branch: [branch-name]

## Problem & Outcome

[What problem, for whom, desired end state. 2-3 sentences.]

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

[Patterns to follow, API contracts to maintain, things not to break,
files not to touch. Agents read this as guardrails.]

## Open Questions

- [ ] [Unresolved question — resolve before or during implementation]
```

### Section Guidance

| Section | Purpose for Loop | Required? |
|---------|-----------------|-----------|
| Problem & Outcome | Orients decomposition — what are we building toward | Yes |
| Scope | Prevents agent drift during implementation | Yes |
| Functional Requirements | Drives phase decomposition — each FR maps to work | Yes |
| Non-Functional | Constraints every phase must respect | Yes |
| Codebase Context | Grounds specs in real code — reduces hallucination | Yes |
| Acceptance Criteria | Review step uses these to evaluate each phase | Yes |
| Verification | Codex runs these commands to validate | Yes |
| Constraints | Guardrails for Codex — what NOT to do | Yes |
| Open Questions | Flags risk — decompose step can route these to early phases | Recommended |

## Step 5 — Readiness Check

Before saving, verify against the quality bar:

- [ ] Problem and desired outcome are specific (not vague)
- [ ] In-scope and out-of-scope are explicit
- [ ] Requirements are specific enough to decompose into ≤12-file phases
- [ ] Acceptance criteria are objective and testable (not "looks good")
- [ ] Verification commands actually exist in the project
- [ ] Codebase context references real files (not assumed)
- [ ] Constraints are actionable (not aspirational)
- [ ] Open questions are either resolved or explicitly deferred

If any fail, identify which ones and suggest how to fix them.

## Step 6 — Present and Save

Show the complete PRD. Ask:

"Does this capture your requirements? Reply to proceed, or edit the PRD first."

After confirmation, display next steps:

```
PRD saved to: docs/prd-<slug>.md

To decompose and execute:
  prd-loop docs/prd-<slug>.md
```

## Constraints

- **Interview before writing** — do not generate a PRD from assumptions
- **Lean format by default** — do not add rollout plans, metrics dashboards, or approval logs. For neb features, reference files may expand existing sections (e.g., feature gating detail within Scope, cross-service impact within Codebase Context) but do not add top-level sections that the template doesn't define
- **Codebase-grounded** — every codebase context entry must reference real files you've verified exist
- **EARS format** for functional requirements — keeps them parseable and unambiguous
- **One PRD per invocation** — if the feature is too large, suggest splitting into multiple PRDs
