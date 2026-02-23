# AI-Native PRD Template

Use this template when a PRD will feed human + AI-assisted implementation. The goal is to keep intent clear enough for automation while preserving human control over risk and release.

## Document Metadata

- PRD title:
- Owner:
- Date:
- Status: Draft | In Review | Approved | In Progress | Done
- Version:
- Related links: ticket, epic, design doc, dashboard, PRs

## 1. Problem and Outcome

### Problem Statement

[Describe the user/business problem in plain language.]

### Desired Outcome

[Describe the end state if this succeeds.]

### Why Now

[State urgency, opportunity window, or risk of inaction.]

## 2. Users and Use Cases

### Primary Users

[Who is directly affected?]

### Key Jobs-to-be-Done

1. [JTBD 1]
2. [JTBD 2]
3. [JTBD 3]

### Core User Scenarios

1. [Scenario 1]
2. [Scenario 2]
3. [Scenario 3]

## 3. Scope

### In Scope

1. [Requirement or capability]
2. [Requirement or capability]
3. [Requirement or capability]

### Out of Scope

1. [Explicit non-goal]
2. [Explicit non-goal]
3. [Explicit non-goal]

## 4. Requirements

### Functional Requirements

1. [System must...]
2. [System must...]
3. [System must...]

### Non-Functional Requirements

1. Reliability: [SLO/SLA target]
2. Performance: [latency/throughput targets]
3. Security: [authn/authz, data handling requirements]
4. Compliance: [HIPAA/SOC2/GDPR/etc if relevant]
5. Observability: [logs, metrics, traces required]

## 5. Data and Integrations

### Data Inputs

1. [Source, owner, expected quality]
2. [Source, owner, expected quality]

### Data Outputs

1. [Destination and consumers]
2. [Destination and consumers]

### Integrations

1. [Service/API dependency and contract assumptions]
2. [Service/API dependency and contract assumptions]

## 6. UX and Workflow

### User Experience Expectations

[Describe expected behavior in normal and error paths.]

### Edge Cases

1. [Edge case and expected behavior]
2. [Edge case and expected behavior]
3. [Edge case and expected behavior]

## 7. Acceptance Criteria (Definition of Done)

Each criterion should be objectively verifiable.

1. [Given/When/Then criterion]
2. [Given/When/Then criterion]
3. [Given/When/Then criterion]

## 8. Success Metrics

### Leading Indicators

1. [Metric, target, timeframe]
2. [Metric, target, timeframe]

### Lagging Indicators

1. [Metric, target, timeframe]
2. [Metric, target, timeframe]

### Guardrail Metrics

1. [Metric that must not regress]
2. [Metric that must not regress]

## 9. Risks, Assumptions, Dependencies

### Assumptions

1. [Assumption]
2. [Assumption]

### Risks

1. [Risk, likelihood, impact, mitigation]
2. [Risk, likelihood, impact, mitigation]

### Dependencies

1. [Upstream/downstream team/system dependency]
2. [Upstream/downstream team/system dependency]

## 10. AI Execution Plan (PRD -> Code)

### Implementation Phases

1. Phase 1: [foundation]
2. Phase 2: [core behavior]
3. Phase 3: [hardening + rollout]

### Agent Task Units

Break work into tasks that can be validated independently:

1. [Task unit + expected artifact]
2. [Task unit + expected artifact]
3. [Task unit + expected artifact]

### Repository Instructions and Constraints

List explicit instructions the agent must follow:

1. [coding standards]
2. [security constraints]
3. [review/test requirements]

### Stop Conditions

The execution loop stops when:

1. All acceptance criteria pass
2. Regression suite passes
3. Required human approvals are complete

## 11. Verification and Evals

### Required Test Suites

1. Unit tests:
2. Integration tests:
3. E2E tests:
4. Static checks (lint/type/security scans):

### Capability Evals

1. [Can the implementation perform required behavior X?]
2. [Can it perform required behavior Y?]

### Regression Evals

1. [Previously working behavior A still passes]
2. [Previously working behavior B still passes]

### Release Gate

Ship only if:

1. Acceptance criteria pass
2. Required test/eval suites pass
3. Risk sign-offs are complete

## 12. Rollout Plan

### Rollout Strategy

[Dark launch, percentage rollout, feature flag, region rollout, etc.]

### Monitoring Plan

[What will be monitored and by whom in the first 24h/7d/30d.]

### Rollback Plan

[Specific rollback trigger and rollback procedure.]

## 13. Open Questions

1. [Question]
2. [Question]
3. [Question]

## 14. Approval Log

- Product:
- Engineering:
- Security/Compliance (if required):
- Design (if required):
- Date approved:

---

## Optional: Machine-Readable Block for Agents

Use this compact block to feed tools that benefit from structured context.

```yaml
prd:
  title: ""
  owner: ""
  status: "Draft"
  problem: ""
  desired_outcome: ""
  in_scope: []
  out_of_scope: []
  functional_requirements: []
  non_functional_requirements:
    reliability: ""
    performance: ""
    security: ""
    compliance: ""
  acceptance_criteria: []
  success_metrics:
    leading: []
    lagging: []
    guardrails: []
  implementation_phases: []
  agent_task_units: []
  required_checks:
    unit_tests: true
    integration_tests: true
    e2e_tests: false
    lint: true
    typecheck: true
    security_scan: true
  stop_conditions:
    - "all_acceptance_criteria_pass"
    - "regression_suite_passes"
    - "human_approval_complete"
```

## PRD Readiness Checklist

Mark complete before implementation:

- [ ] Problem and desired outcome are specific
- [ ] In-scope and out-of-scope are explicit
- [ ] Acceptance criteria are objective and testable
- [ ] Success metrics include targets and time windows
- [ ] Key risks and assumptions are documented
- [ ] Required test/eval suites are defined
- [ ] Rollout and rollback plans are documented
- [ ] Open questions are either resolved or explicitly deferred
