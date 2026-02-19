# Mode Selection Guide

How to recommend the right reasoning mode when the user selects "You choose."

## Signal-to-Mode Mapping

| User Signal | Recommended Mode | Rationale |
|-------------|-----------------|-----------|
| "Is this the right approach?" | Socratic Questioning | Exploring assumptions, not yet committed |
| "I'm about to commit to X" | Dialectic Synthesis | Needs strongest counter-argument |
| "What could go wrong?" | Pre-mortem Analysis | Explicitly asking about failure modes |
| "Is this secure/safe?" | Red Team | Security and adversarial framing |
| "The data shows that..." | Evidence Audit | Claims need falsification |
| "Everyone agrees that..." | Socratic Questioning | Consensus signals unexamined assumptions |
| "This will definitely work" | Pre-mortem Analysis | Overconfidence needs failure imagination |

## Decision Type Mapping

| Decision Type | Primary Mode | Secondary Mode |
|---------------|-------------|----------------|
| Technology choice | Dialectic Synthesis | Pre-mortem Analysis |
| Architecture decision | Pre-mortem Analysis | Red Team |
| Business strategy | Dialectic Synthesis | Evidence Audit |
| Security design | Red Team | Pre-mortem Analysis |
| Data-driven conclusion | Evidence Audit | Socratic Questioning |
| Migration planning | Pre-mortem Analysis | Dialectic Synthesis |
| Vendor selection | Pre-mortem Analysis | Evidence Audit |

## Multi-Mode Sequencing

| Sequence | When to Use |
|----------|-------------|
| Socratic → Dialectic | User has an untested idea. Surface assumptions first, then argue the counter. |
| Pre-mortem → Red Team | High-stakes system launch. Find internal failures, then external attacks. |
| Evidence Audit → Socratic | Data-driven proposal. Audit the evidence, then question the interpretation. |
| Dialectic → Pre-mortem | Strategic decision. Argue the counter, then stress-test the surviving position. |

**Suggest a second pass when**: The first mode reveals a category of risk the user hadn't considered, or the thesis survives largely intact and may need harder testing.

**Don't suggest a second pass when**: The user's question is narrow, the first mode already surfaced actionable changes, or the user signals they want to move on.

## Auto-Recommendation Format

```
Based on [specific context signal], I recommend **[Mode Name]** because [1-sentence rationale].

[If secondary mode relevant:]
After that, a follow-up with **[Secondary Mode]** would [1-sentence benefit].
```

Then ask the user to confirm:
- Option 1: Recommended mode (with "(Recommended)" label)
- Option 2: Secondary mode if applicable
- Option 3: "Let me pick" — return to full mode selection
