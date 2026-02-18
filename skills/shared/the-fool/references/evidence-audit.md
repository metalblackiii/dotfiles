# Evidence Audit

Falsificationism and evidence quality assessment for auditing whether claims are actually supported by evidence.

## Core Principle

A claim is only meaningful if you can specify what would disprove it. Extract claims from proposals, design falsification criteria, assess evidence quality, and surface competing explanations.

## Process

1. **Extract claims** — Identify the specific claims being made (often implicit)
2. **Design falsification criteria** — For each claim, specify what would disprove it
3. **Assess evidence quality** — Evaluate the evidence supporting each claim
4. **Identify cognitive biases** — Check for systematic errors in reasoning
5. **Surface competing explanations** — Find alternative explanations for the same evidence

## Claim Types

| Type | Example | Hidden In |
|------|---------|-----------|
| **Causal** | "X causes Y" | "Our refactor improved performance" |
| **Predictive** | "X will happen" | "Users will adopt this feature" |
| **Comparative** | "X is better than Y" | "Bottom-Up is the better approach for us" |
| **Existential** | "X exists/doesn't exist" | "There's no alternative that meets our needs" |
| **Quantitative** | "X is N" | "This will save 200 hours per quarter" |

## Falsification Criteria

For each claim, design a test that would disprove it:

| Claim | Falsification Criterion | Test |
|-------|------------------------|------|
| "Users want feature X" | <10% engage within 30 days | Feature flag, measure adoption |
| "This will scale to 100K users" | Response time >500ms at 50K | Load test at target scale |
| "Migration will take 3 months" | >2 unknowns discovered in month 1 | Track surprise count |
| "This will reduce costs" | TCO exceeds current within 12 months | TCO analysis with all costs |

### Unfalsifiable Claims (Red Flag)

| Pattern | Example | Problem |
|---------|---------|---------|
| Vague outcome | "This will improve things" | No measurable criterion |
| Moving goalposts | "It'll work eventually" | No time boundary |
| Circular reasoning | "This is best because experts recommend it" | Evidence is the claim restated |

## Evidence Quality

| Grade | Description | Reliability |
|-------|-------------|------------|
| **A** | Controlled experiment, large sample, reproducible | High confidence |
| **B** | Observational data, reasonable sample, consistent | Moderate confidence |
| **C** | Case study, small sample, single source | Low — needs corroboration |
| **D** | Anecdote, opinion, vendor marketing | Insufficient alone |
| **F** | No evidence cited | Claim is unsupported |

### Weak Evidence Patterns

| Pattern | Why It's Weak |
|---------|---------------|
| Survivorship bias | Ignores failures using the same approach |
| Cherry-picked metrics | Other metrics may have worsened |
| Vendor benchmarks | Optimized for vendor's strengths |
| Appeal to authority | "Google does it this way" — Google's constraints aren't yours |
| Anchoring | First estimate unchanged despite new data |

## Cognitive Bias Checklist

| Bias | Detection Signal |
|------|-----------------|
| **Confirmation bias** | Only positive evidence cited |
| **Sunk cost fallacy** | "We've already spent 6 months on this" as justification |
| **Availability heuristic** | Decision based on one memorable incident |
| **Bandwagon effect** | "Everyone is doing it" without fitness assessment |
| **Status quo bias** | "It's always been this way" |

## Competing Explanations

For every conclusion, ask: "What else could explain this evidence?"

```
Evidence: "Deployment failures dropped 50% after adopting tool X."
Proposed: Tool X is better than the old tool.
Alternatives:
  1. The team also started doing more code review in the same period
  2. A particularly error-prone service was retired last month
  3. The team gained experience that would have improved results with any tool
```

## Output Template

```markdown
## Evidence Audit: [Proposal/Decision]

### Claims Extracted
| # | Claim | Type | Evidence Cited |
|---|-------|------|---------------|

### Falsification Criteria
| Claim | What Would Disprove It | How to Test |
|-------|----------------------|-------------|

### Evidence Quality
| Claim | Grade | Key Weakness |
|-------|-------|--------------|

### Bias Check
| Bias Detected | Where | Impact |
|--------------|-------|--------|

### Competing Explanations
| Evidence | Proposed Explanation | Alternatives |
|----------|---------------------|-------------|

### Verdict
**Overall evidence strength:** Strong / Moderate / Weak / Insufficient
```
