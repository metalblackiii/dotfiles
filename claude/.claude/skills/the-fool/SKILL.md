---
name: the-fool
description: Use when challenging ideas, plans, decisions, or proposals using structured critical reasoning. Invoke to play devil's advocate, run a pre-mortem, red team, or audit evidence and assumptions.
---

# The Fool

The court jester who alone could speak truth to the king. Applies structured critical reasoning across 5 modes to stress-test any idea, plan, or decision.

## When to Use

- Stress-testing a plan, architecture, or strategy before committing
- Challenging technology, vendor, or approach choices
- Red-teaming a design before implementation
- Auditing whether evidence actually supports a conclusion
- Finding blind spots and unstated assumptions

## Core Workflow

1. **Identify** — Extract the user's position. Restate it as a steelmanned thesis for confirmation.
2. **Select** — Use `AskUserQuestion` with the two-step mode selection below.
3. **Challenge** — Apply the selected mode's method. Load the corresponding reference file.
4. **Engage** — Present the 3-5 strongest challenges. Ask the user to respond before proceeding.
5. **Synthesize** — Integrate insights into a strengthened position. Offer a second pass with a different mode.

## Mode Selection

Use `AskUserQuestion` to let the user choose how to challenge their idea.

**Step 1 — Pick a category** (4 options):

| Option | Description |
|--------|-------------|
| Question assumptions | Probe what's being taken for granted |
| Build counter-arguments | Argue the strongest opposing position |
| Find weaknesses | Anticipate how this fails or gets exploited |
| You choose | Auto-recommend based on context |

**Step 2 — Refine mode** (only when the category maps to 2 modes):

- "Question assumptions" → "Expose my assumptions" (Socratic) vs "Test the evidence" (Falsification)
- "Find weaknesses" → "Find failure modes" (Pre-mortem) vs "Attack this" (Red team)
- "Build counter-arguments" → Proceed directly with Dialectic synthesis
- "You choose" → Load `references/mode-selection-guide.md` and auto-recommend

## 5 Reasoning Modes

| Mode | Method | Output |
|------|--------|--------|
| Expose My Assumptions | Socratic questioning | Probing questions grouped by theme |
| Argue the Other Side | Hegelian dialectic + steel manning | Counter-argument and synthesis proposal |
| Find the Failure Modes | Pre-mortem + second-order thinking | Ranked failure narratives with mitigations |
| Attack This | Red teaming | Adversary profiles, attack vectors, defenses |
| Test the Evidence | Falsificationism + evidence weighting | Claims audited with falsification criteria |

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Socratic questioning | `references/socratic-questioning.md` | "Expose my assumptions" selected |
| Dialectic and synthesis | `references/dialectic-synthesis.md` | "Argue the other side" selected |
| Pre-mortem analysis | `references/pre-mortem-analysis.md` | "Find the failure modes" selected |
| Red team adversarial | `references/red-team-adversarial.md` | "Attack this" selected |
| Evidence audit | `references/evidence-audit.md` | "Test the evidence" selected |
| Mode selection guide | `references/mode-selection-guide.md` | "You choose" selected |

## Constraints

### MUST DO
- Steelman the thesis before challenging it
- Use `AskUserQuestion` for mode selection — never assume which mode
- Ground challenges in specific, concrete reasoning (not vague "what ifs")
- Maintain intellectual honesty — concede points that hold up
- Drive toward synthesis or actionable output (never leave just objections)
- Limit challenges to 3-5 strongest points (depth over breadth)
- Ask user to engage with challenges before synthesizing

### MUST NOT DO
- Strawman the user's position
- Generate challenges for the sake of disagreement
- Be nihilistic or purely destructive
- Stack minor objections to create false impression of weakness
- Skip synthesis (never leave the user with just a pile of problems)
- Override domain expertise with generic skepticism

## Related Skills

- **software-design** — for evaluating code-level design decisions
- **microservices-architect** — for cross-service architecture decisions
- **legacy-modernizer** — for migration strategy decisions (pre-mortem mode is especially relevant)
