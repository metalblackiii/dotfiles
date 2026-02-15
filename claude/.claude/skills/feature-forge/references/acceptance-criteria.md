# Acceptance Criteria

## Given-When-Then Format

```markdown
### AC-001: [Scenario Name]
Given [context/precondition]
When [action taken]
Then [expected result]
```

## Scenario Types

### Happy Path

```markdown
### AC-001: Successful Eligibility Check
Given a patient with active insurance
When the provider runs a real-time eligibility check
Then the system displays coverage details
And the verification status is updated to "verified"
```

### Error Cases

```markdown
### AC-002: Eligibility Check — Payer Timeout
Given a patient with active insurance
When the provider runs an eligibility check and the payer does not respond within 30 seconds
Then the system displays "Payer unavailable — try again later"
And the verification status remains unchanged
And the timeout is logged as a warning
```

### Feature-Gated Scenarios

```markdown
### AC-003: Entitlement — Feature Accessible
Given a tenant with the real-time-eligibility entitlement
When the provider navigates to the eligibility page
Then the eligibility check controls are visible and functional

### AC-004: Entitlement — Feature Gated
Given a tenant WITHOUT the real-time-eligibility entitlement
When the provider navigates to the eligibility page
Then the eligibility check controls are not displayed
```

### Authorization

```markdown
### AC-005: Permission Check
Given a user without the "verify_eligibility" permission
When they attempt to run an eligibility check
Then the system returns 403 Forbidden
And the check is not executed
```

### Multi-Tenant / Legacy

```markdown
### AC-006: Legacy Tenant Behavior
Given a legacy tenant (PHX_GBB_ENTITLEMENTS disabled)
When hasEntitlement() is called
Then the system delegates to legacy hasAddOn() checks
And behavior is identical to pre-migration
```

### Edge Cases

```markdown
### AC-007: Empty State
Given a patient with no insurance on file
When the provider opens the eligibility page
Then the system displays "No insurance information available"
And the eligibility check button is disabled

### AC-008: Concurrent Updates
Given two users editing the same patient record simultaneously
When both submit changes
Then the second submission receives a conflict error
And is prompted to refresh and retry
```

## INVEST Criteria

Good acceptance criteria follow INVEST:

| Criterion | Description | Check |
|-----------|-------------|-------|
| **I**ndependent | Can be tested alone | No dependencies on other ACs |
| **N**egotiable | Details can be discussed | Not over-specified |
| **V**aluable | Delivers user value | Ties to a requirement |
| **E**stimable | Effort can be estimated | Clear scope |
| **S**mall | Testable in one session | Not too broad |
| **T**estable | Pass/fail is clear | Objective criteria |

## Quick Reference

| Scenario Type | Given | When | Then |
|---------------|-------|------|------|
| Happy path | Valid state | Valid action | Success result |
| Error | Invalid state/input | Action | Error message + graceful handling |
| Feature gate | Entitlement present/absent | Access attempt | Feature shown/hidden |
| Authorization | User role/permission | Protected action | Appropriate access |
| Legacy compat | Legacy tenant | Same action | Same behavior as before |
| Edge case | Boundary condition | Action | Graceful handling |
