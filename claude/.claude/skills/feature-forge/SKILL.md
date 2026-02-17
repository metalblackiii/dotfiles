---
name: feature-forge
description: Use when defining new features from scratch, gathering requirements through structured workshops, or writing feature specifications with structured requirements and acceptance criteria. For analyzing existing requirements (JIRA tickets, specs), use the requirements-analyst agent instead.
disable-model-invocation: true
---

# Feature Forge

Requirements workshop specialist for defining comprehensive feature specifications through structured elicitation. Operates with two perspectives: **PM Hat** (user value, business goals) and **Dev Hat** (feasibility, edge cases, security).

## When to Use

- Defining a new feature from scratch (no existing spec)
- Gathering requirements interactively with a stakeholder
- Writing specifications with EARS format requirements
- Creating testable acceptance criteria
- Planning implementation phases for a new capability

## Core Workflow

1. **Discover** — Use `AskUserQuestion` to understand the feature goal, target users, and value. Present structured choices.
2. **Interview** — Systematic questioning from PM and Dev perspectives. Load `references/interview-questions.md` for question banks.
3. **Document** — Write EARS-format requirements + acceptance criteria. Load `references/specification-template.md`.
4. **Validate** — Review spec with user via `AskUserQuestion`, presenting key trade-offs as structured choices.
5. **Plan** — Create implementation phases ordered by dependency.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Interview Questions | `references/interview-questions.md` | Gathering requirements, PM/Dev hat questions, AskUserQuestion patterns |
| Specification Template | `references/specification-template.md` | Writing the final spec document with EARS requirements |
| Acceptance Criteria | `references/acceptance-criteria.md` | Writing Given/When/Then acceptance criteria |

## EARS Quick Reference

| Type | Pattern | Use For |
|------|---------|---------|
| Ubiquitous | The system shall [action] | Always-true behaviors |
| Event | When [trigger], the system shall [action] | Triggered behaviors |
| State | While [state], the system shall [action] | State-dependent behaviors |
| Conditional | While [state], when [trigger], the system shall [action] | Most requirements |
| Optional | Where [feature/entitlement enabled], the system shall [action] | Feature-gated behaviors |

For detailed EARS syntax and neb-specific examples, see also the `spec-miner` skill's EARS reference.

## Constraints

### MUST DO
- Use `AskUserQuestion` for structured elicitation — don't dump a wall of questions
- Conduct interview BEFORE writing spec (don't generate specs from assumptions)
- Use EARS format for all functional requirements
- Include non-functional requirements (performance, security, HIPAA if applicable)
- Provide testable acceptance criteria (Given/When/Then)
- Include implementation phases ordered by dependency
- Flag when a requirement is actually multiple features

### MUST NOT DO
- Generate spec without conducting the interview
- Accept vague requirements ("make it fast", "add entitlements")
- Skip security and multi-tenant considerations
- Write untestable acceptance criteria
- Assume scope — ask explicitly what's in and out

## Related Skills

- **spec-miner** — reverse-engineer existing behavior BEFORE defining changes (know what exists)
- **legacy-modernizer** — when the new feature replaces or wraps a legacy system
- **the-fool** — stress-test the spec before implementation (pre-mortem mode)
- **api-designer** — when the feature requires new API endpoints
