# Specification Template

## Full Template

```markdown
# Feature: [Name]

## Overview
[2-3 sentence description of the feature and its value to users]

**Tier**: [Good / Better / Best / All]
**Feature Flag**: [Flag name, or "None"]
**Entitlement**: [Entitlement key, or "None"]

## Repositories

[For multi-repo work, list every affected repo with its role and what
changes. Agents and loop tools read this to know which repos to
clone, branch, or verify. Omit for single-repo features.]

| Repo | Role | Changes |
|------|------|---------|
| `repo-name` | Primary implementation | [what code lives here] |
| `other-repo` | Operational impact (no code) | [config or infra changes, verification steps] |
| `another-repo` | Verification target (no code) | [what to smoke-test] |
| `ref-repo` | Reference only | [patterns to follow] |

Roles: `Primary implementation`, `Operational impact (no code)`, `Verification target (no code)`, `Reference only`, `Potential update`. Mark new repos with **(NEW — org name)**.

## Functional Requirements

### FR-001: [Requirement Name]
While <precondition>, when <trigger>, the system shall <response>.

### FR-002: [Requirement Name]
When <trigger>, the system shall <response>.

## Non-Functional Requirements

### Security
- Authentication: [Cognito JWT / Service-to-service / Public]
- Authorization: [SECURITY_SCHEMA_KEYS reference]
- PHI/PII: [Yes/No — if yes, specify what data and handling]
- Audit logging: [Required/Not required]

### Performance
- Response time: < [X]ms p95
- Expected load: [requests/minute]
- Data volume: [expected scale]

### Multi-Tenant
- Tenant-scoped: [Yes/No]
- Behavior varies by tenant type: [Legacy/GBB/Both]
- Tenant configuration: [Any per-tenant settings]

## Feature Gating

| Gate Type | Key | Behavior When Disabled |
|-----------|-----|----------------------|
| Feature flag | [PHX_FLAG_NAME] | [Hidden / Passthrough / Fallback] |
| Entitlement | [entl:feature-name] | [Hidden / Locked / Upsell prompt] |
| Legacy add-on | [CT_ADDON_NAME] | [Legacy behavior preserved] |

## Acceptance Criteria

### AC-001: [Happy Path Scenario]
Given [precondition]
When [action]
Then [expected result]

### AC-002: [Error Scenario]
Given [precondition]
When [action]
Then [expected error handling]

### AC-003: [Feature Gate Scenario]
Given tenant does not have [entitlement/flag]
When [action]
Then [gated behavior]

## Error Handling

| Error Condition | HTTP Code | User Message | Log Level |
|-----------------|-----------|--------------|-----------|
| [Condition] | [Code] | [Message] | [info/warn/error] |

## Cross-Service Impact

| Service | Change Type | Details |
|---------|------------|---------|
| [neb-ms-*] | New endpoint / Modified / None | [What changes] |
| [neb-www] | New component / Modified | [What changes] |

### Kafka Events

| Event | Publisher | Subscriber | When |
|-------|-----------|------------|------|
| [Event name] | [Service] | [Service] | [Trigger condition] |

## Implementation Phases

### Phase 1: [Foundation]
- [ ] [Data layer: migrations, models]
- [ ] [Backend: service logic, API endpoints]

### Phase 2: [Core Feature]
- [ ] [Frontend: components, pages]
- [ ] [Integration: cross-service calls]

### Phase 3: [Polish]
- [ ] [Testing: unit, integration, E2E]
- [ ] [Feature flag cleanup post-rollout]

## Out of Scope
- [Explicitly excluded capabilities]
- [Future enhancements to consider later]

## Open Questions
- [ ] [Unresolved question needing stakeholder input]
- [ ] [Technical decision pending]
```

## Required Sections Checklist

| Section | Required | Notes |
|---------|----------|-------|
| Overview + tier/flag/entitlement | Yes | Always specify gating up front |
| Repositories | If multi-repo | List each affected repo, its role, and expected changes |
| Functional Requirements (EARS) | Yes | Core of the spec |
| Non-Functional Requirements | Yes | Security and multi-tenant always relevant |
| Feature Gating | If gated | Most neb features are gated |
| Acceptance Criteria | Yes | Must be testable |
| Error Handling | Yes | Include common + feature-specific errors |
| Cross-Service Impact | If multi-service | Common in neb ecosystem |
| Implementation Phases | Recommended | Order by dependency |
| Out of Scope | Recommended | Prevents scope creep |
