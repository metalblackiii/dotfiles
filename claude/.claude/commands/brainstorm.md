---
command: brainstorm
description: Turn vague overwhelm into structured research or a PRD. Scopes the problem space, generates research angles, dispatches co-research, and routes to the right next step.
argument-hint: <topic, feeling, or path to existing docs>
---

# Brainstorm: From Vague to Actionable

You help when the user doesn't know where to start. They have a vague idea, scattered docs, or general overwhelm about a topic. Your job is to scope the problem space, figure out what needs researching, execute that research, and route to the right outcome.

## Step 1 — Intake

Read `$ARGUMENTS` as either:
- A topic phrase ("Cognito IDP migration")
- A path to one or more files (research docs, tickets, notes)
- Both ("Cognito IDP migration docs/research-*.md")

Gather everything available:
- Read any referenced files
- Check for related docs in the current repo (`docs/`, `*.md` files with relevant keywords)
- Check Jira if a ticket number is detectable (branch name, arguments)

If `$ARGUMENTS` is empty or too vague to even start exploring (e.g., "help"), ask one open-ended question: **"What's on your mind? Dump whatever you have — a sentence, a link, a feeling."** Then wait.

## Step 2 — Landscape Scan

With the gathered context, do light exploration to map the problem space. This is fast and broad, not deep:

- **Web search** (2-3 queries) to understand the general landscape
- **Codebase scan** if the topic relates to something in the current repo or additional working directories
- **Existing doc synthesis** — if the user provided research docs, extract the key themes and open questions from them

Produce a **problem space map** — not a research plan yet, but a lay of the land:

```markdown
## Problem Space: [Topic]

**What I understand so far:**
[2-3 sentences summarizing what you gathered from intake + light exploration]

**Dimensions I see:**
1. **[Dimension]** — [Why this matters. What's unknown.]
2. **[Dimension]** — [...]
3. **[Dimension]** — [...]
4. **[Dimension]** — [...]

**Existing context you have:**
- [Doc/artifact 1] — covers [what it covers], leaves open [what's missing]
- [Doc/artifact 2] — ...

**What I'd research next:**
[1-2 sentences on the direction you'd take these dimensions]
```

Present this to the user. Ask: **"Does this capture the shape of it? Anything missing or off-base?"**

Wait for response. Incorporate feedback. One round only — don't iterate into a superpowers-style Q&A loop. If their feedback changes the dimensions, update and confirm once more.

## Step 3 — Generate Research Angles

Convert the validated dimensions into 3-5 concrete research angles suitable for co-research dispatch. Each angle should be:
- **Specific enough** to be a standalone research task
- **Independent enough** to be researched in parallel
- **Actionable** — answering it moves toward a decision

Present the angles:

```markdown
## Research Angles

1. **[Angle]** — [What to investigate, what question it answers]
2. **[Angle]** — [...]
3. **[Angle]** — [...]

**Proposed approach:** Hand these to co-research for parallel deep dives, then synthesize.
```

Ask: **"These are the angles I'd research. Add, drop, or adjust?"**

Wait for confirmation. This is the last gate before spending tokens on parallel research.

## Step 4 — Dispatch to Co-Research

Invoke `/co-research` via the Skill tool with a well-formed topic that includes the angles.

Construct the co-research argument as: `[Topic]: [angle 1], [angle 2], [angle 3]`

When co-research asks its initial clarifying questions (Step 1 of co-research), answer them yourself using context from Steps 1-3 — you already did the scoping work. Specifically:
- **Clarity check:** The topic is clear — you validated it. Proceed.
- **Repo question:** Include any repos identified during landscape scan.
- **Research plan review:** If co-research proposes angles that differ from yours, reconcile — prefer yours since they were user-validated, but incorporate any good additions co-research suggests.

Let co-research run through its full process (parallel dispatch, synthesis, draft).

## Step 5 — Route the Outcome

After co-research delivers its synthesis, read the output and assess what the user needs next. Present the synthesis along with an explicit routing recommendation:

### Route A: Research Doc
The topic is still exploratory. There are open questions, no clear single path forward.
> "Here's what we found. I'd suggest reading through this and coming back when you're ready to narrow down. Saved to `[path]`."

### Route B: Decision Brief
There are 2-3 clear options with tradeoffs. The user needs to pick a direction.
> "The research points to [N] viable approaches. Here's a quick comparison:
> | Approach | Pros | Cons | Effort |
> |----------|------|------|--------|
> Pick one and I can turn it into a PRD."

### Route C: Straight to PRD
The research clearly points to one approach. The path forward is well-defined.
> "The research strongly points toward [approach]. Want me to run `/create-prd` to turn this into an implementation plan?"

If the user picks Route B or C and wants a PRD, invoke `/create-prd` via the Skill tool, passing the research doc path as context.

## Principles

- **One interaction per gate.** Steps 2 and 3 each get one user check-in. Don't turn this into 8 rounds of Q&A — the whole point is that the user is overwhelmed and needs you to drive.
- **You do the scoping work.** The user's job is to dump context and give thumbs up/down. Your job is to figure out the structure.
- **Bias toward action.** If you can route to co-research with 3 solid angles, do it. Don't over-refine the problem space map.
- **Respect existing context.** If the user already has research docs, synthesize them — don't re-research what's already known. Focus angles on the gaps.
