# Interview Questions

## PM Hat Questions

Focus on user value and business goals.

| Area | Questions |
|------|-----------|
| **Problem** | What problem does this solve? Who experiences it? How often? |
| **Users** | Who are the target users? Roles? Technical level? |
| **Value** | How will users benefit? Business value? |
| **Scope** | What's in scope? What's explicitly out? MVP vs full? |
| **Success** | How will we measure success? Key metrics? |
| **Priority** | Must-have, should-have, or nice-to-have? |
| **Timeline** | Deadline? Dependencies on other work? |

## Dev Hat Questions

Focus on technical feasibility and edge cases.

| Area | Questions |
|------|-----------|
| **Integration** | Which services are affected? New endpoints needed? |
| **Data** | New tables/columns? Migrations? What's stored? Retention? |
| **Security** | Auth required? HIPAA implications? PHI/PII involved? |
| **Multi-Tenant** | Per-tenant behavior differences? Tenant-scoped data? |
| **Feature Gating** | Behind a feature flag? Entitlement-gated? Which tier? |
| **Performance** | Expected load? Response time requirements? Async OK? |
| **Edge Cases** | What happens when X fails? Empty states? Limits? |
| **Cross-Service** | Which other neb services need to know? Kafka events? |
| **Legacy** | Does this replace or coexist with existing behavior? |

## Neb-Specific Questions

These come up for most features in the neb ecosystem:

### Feature Gating
- Is this behind a feature flag? Which one?
- Is this entitlement-gated? Which tier (Good/Better/Best)?
- Does this replace an existing add-on check?
- What should non-entitled tenants see? (hidden vs locked vs upsell)

### Multi-Tenant
- Does behavior differ by tenant type (legacy vs GBB)?
- Is data tenant-scoped? (it almost always should be)
- Are there tenant-specific configurations?

### Cross-Service Impact
- Which backend services need changes? (registry, billing, claims, partner)
- Are there Kafka events to publish or consume?
- Do other services need new API endpoints?

### HIPAA / Security
- Does this feature handle PHI (Protected Health Information)?
- Are there audit logging requirements?
- Does data need encryption at rest beyond standard?

## Using AskUserQuestion

Use structured choices when questions have a finite set of likely answers. Use open-ended follow-up when answers are unbounded.

### When to Use Structured Options

| Question Pattern | Options Style |
|-----------------|---------------|
| Priority/ranking | Single select: Must-have, Should-have, Nice-to-have |
| Scope decisions | Single select: MVP, Full, Phased |
| Feature gating | Single select: Feature flag, Entitlement, Both, None |
| Tier assignment | Single select: Good, Better, Best |
| Auth level | Single select: Public, Authenticated, Role-based |

### When to Use Open-Ended

- "Describe the user journey in your own words"
- "What problem does this solve?"
- "Walk me through the workflow"
- "What happens when [X] fails?"

## Interview Flow

### Phase 1: Discovery (Open-Ended → Structured)
1. "Tell me about this feature in your own words"
2. "What problem are we solving?"
3. Then `AskUserQuestion`: Target users, priority, scope (MVP/Full/Phased)

### Phase 2: Details (Structured → Open-Ended)
1. `AskUserQuestion`: Feature gating approach, tier assignment, key capabilities
2. Then open-ended: "Walk me through the user journey"

### Phase 3: Edge Cases (Structured → Open-Ended)
1. `AskUserQuestion`: Error handling approach, data limits
2. Then open-ended: "What happens when [X] fails?"

### Phase 4: Validation
1. Present spec summary
2. `AskUserQuestion`: "Does this capture your requirements?" (Yes / Needs changes / Major gaps)

## Pre-Discovery: Codebase Exploration

For features touching multiple services, explore the codebase BEFORE starting the interview. This ensures questions are grounded in what actually exists.

Use the `spec-miner` skill to reverse-engineer existing behavior, or dispatch parallel agents:

```
Before interview, launch in parallel:
- Agent 1: Explore codebase for existing patterns related to this feature
- Agent 2: Check which services/repos are affected
- Agent 3: Find existing feature flags, entitlements, add-ons related to this area

Collect findings → Use them to inform interview questions
```

This is especially valuable when the `requirements-analyst` agent invokes feature-forge — the agent has already explored the codebase and can feed that context into the workshop.
