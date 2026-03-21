# Pre-Mortem Analysis

Pre-mortem methodology with second-order thinking for identifying how plans fail before they fail.

## Core Principle

A pre-mortem inverts the question. Instead of "Will this work?" ask: **"It's 6 months from now and this has failed. Why?"** This bypasses optimism bias by making failure the starting point.

## Process

1. **Set the scene** — "Imagine it's [timeframe] from now. This plan has failed."
2. **Generate failure narratives** — Write specific stories about how it failed
3. **Rank by likelihood and impact** — Not all failures are equal
4. **Trace consequence chains** — First → second → third order effects
5. **Identify early warning signs** — What would you see before the failure?
6. **Design mitigations** — Concrete actions, not vague "be careful"

## Failure Narrative Construction

Failure narratives must be specific. "It didn't scale" is not a narrative. A narrative names the trigger, the chain of events, and the consequence.

### Template

```markdown
**Failure: [Title]**

It's [timeframe] from now. [Specific trigger event]. This caused [first-order effect],
which led to [second-order effect]. The team discovered the problem when [detection point],
but by then [consequence]. The root cause was [underlying assumption that proved wrong].
```

### Specificity Checklist

- Names a specific trigger (not "something goes wrong")
- Includes a number or threshold
- Describes the chain of events, not just the end state
- Identifies who or what is affected
- Could actually happen (not a fantasy scenario)

## Second-Order Consequence Chains

```
Trigger: [event]
  → 1st order: [immediate effect]
    → 2nd order: [consequence of the 1st order effect]
      → 3rd order: [consequence of the 2nd order effect]
```

### Common Patterns

| First Order | Second Order | Third Order |
|------------|-------------|-------------|
| Feature ships late | Sales misses quarter target | Engineering loses trust, gets more oversight |
| Performance degrades | Users adopt workarounds | Workarounds become "requirements" that constrain future design |
| Team member burns out | Knowledge concentrated in fewer people | Bus factor drops, risk increases |
| Data quality issue | Downstream reports are wrong | Business decisions made on bad data |

## Inversion Technique

Ask: **"What would guarantee this fails?"** Then check if any of those conditions exist.

| Category | What Guarantees Failure |
|----------|----------------------|
| **People** | Single point of knowledge, no stakeholder buy-in |
| **Process** | No rollback plan, no incremental validation, all-or-nothing deployment |
| **Technology** | Untested at target scale, undocumented dependencies |
| **Timeline** | No buffer for unknowns, dependencies on external teams with no SLA |
| **Data** | Migration without validation, schema changes without backward compatibility |

## Early Warning Signs

| Warning Sign | What It Indicates |
|-------------|-------------------|
| "We'll figure that out later" repeated 3+ times | Critical decisions being deferred |
| No one can explain the rollback plan | Rollback hasn't been designed |
| Estimates keep growing | Hidden complexity being discovered |
| Key meetings keep getting rescheduled | Stakeholder alignment is weaker than assumed |
| Testing phase compressed | Quality will be sacrificed |
| No metrics defined for success | No one will know if this worked |

## Output Template

```markdown
## Pre-Mortem: [Plan/Decision Name]
**Timeframe:** [When would failure be evident]

### Failure Narratives

#### 1. [Title] — Likelihood: H/M/L | Impact: H/M/L
[Specific failure narrative]

**Consequence chain:** 1st → 2nd → 3rd order

#### 2. [Title] — Likelihood: H/M/L | Impact: H/M/L
[Narrative]

### Early Warning Signs
| Signal | Failure It Predicts | Check Frequency |
|--------|-------------------|-----------------|

### Mitigations
| Failure | Mitigation | Effort | Reduces Risk By |
|---------|-----------|--------|-----------------|

### Inversion Check
**What would guarantee failure:** [Top 3 conditions]
**Do any exist now?** [Yes/No with specifics]
```
