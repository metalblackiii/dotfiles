---
command: co-research
description: Use when a topic needs multi-angle deep research before a decision. Dispatches parallel agents and Codex, then synthesizes into a reference document.
argument-hint: <research topic as a phrase>
---

# Co-Research: Claude Explores, Codex Surveys, You Decide

## Step 1 — Assess Clarity

Read `$ARGUMENTS` as a research topic phrase.

Evaluate whether the topic is clear enough to decompose into research angles:
- **Clear**: "best practices for lint tools in javascript ecosystem" — proceed to Step 2
- **Ambiguous**: "caching" — too broad. Ask 2-3 focused clarifying questions:
  - What scope? (client-side, server-side, database query, CDN, etc.)
  - What's the goal? (performance, cost reduction, offline support, etc.)
  - Any constraints? (existing stack, compliance requirements, etc.)
- Wait for answers before continuing.

Also ask: "Should I survey any repos beyond this one? If so, which?"

Record the working directory and any additional repo paths.

## Step 2 — Research Plan

Decompose the topic into 3-5 research angles. Write to `.co-research/plan.md`:

```markdown
# Research Plan: [Topic]

## Angles
1. **[Angle name]** — [What to investigate. Who handles it: Claude or Codex]
2. **[Angle name]** — [...]
3. **[Angle name]** — [...]

## Codex Survey Prompt
[Tailored prompt for first Codex pass — specific files, configs, patterns to look for]

## Additional Repos
- [repo path] (if any, otherwise "Current repo only")
```

Present to user: "Here's the research plan. Proceed or adjust?"
Wait for confirmation.

## Step 3a — Parallel First Dispatch

Launch all research streams simultaneously.

**Codex — Codebase Survey** (one per repo):

For each repo, run via `Bash` tool with `run_in_background: true`. Derive a slug from the repo directory name (e.g., `neb-www`, `neb-ms-patients`).

```bash
cd <repo-path> && codex exec --full-auto "<tailored survey prompt from plan>" | tee <absolute-path-to-working-dir>/.co-research/codex-survey-<repo-slug>.md
```

**IMPORTANT:** The `tee` path must be absolute (pointing back to the working directory where `.co-research/` was created), not relative. Codex runs from `<repo-path>`, so a relative `.co-research/` would write to the wrong location.

If only one repo, the slug is just the repo name (e.g., `codex-survey-neb-www.md`).

The Codex prompt must be self-contained (no conversation context). Structure it as:
```
Survey this codebase for [specific topic elements].

Report the following:
- Relevant dependencies (from package.json, go.mod, requirements.txt, etc.)
- Existing configuration files related to [topic]
- Current patterns in use (with file paths and brief excerpts)
- Gaps or inconsistencies you notice

Write your findings as structured markdown.
```

**Claude Subagents — Web Research** (2-3 via Task tool, parallel):

Each agent gets one research angle. Use `subagent_type: "general-purpose"` with `model: "sonnet"`. Each agent should:
- Use `WebSearch` and `WebFetch` to research its angle
- Write findings to `.co-research/claude-<angle-slug>.md`
- Include source URLs for every claim

**IMPORTANT:** Agent prompts must be directive — tell agents to do the research and write findings immediately. Do NOT leave room for agents to ask for confirmation or propose a plan. End each prompt with: "Do the research now and write your findings. Do not ask for confirmation."

Example agent prompts:
- "Research the current ecosystem landscape for [topic]. Compare major tools/libraries, their adoption, maintenance status, and community sentiment. Write findings to `.co-research/claude-ecosystem.md` with source URLs."
- "Research best practices and common pitfalls for [topic]. Focus on authoritative sources (official docs, well-known blog posts, conference talks). Write findings to `.co-research/claude-practices.md` with source URLs."
- "Research real-world case studies and migration stories for [topic]. What did teams learn? What surprised them? Write findings to `.co-research/claude-experiences.md` with source URLs."

Wait for all dispatches to complete (Bash background tasks will notify on completion; Task agents return when done).

## Step 3b — Correlation Dispatch (Conditional)

Read all findings from Step 3a. Evaluate whether a second Codex pass adds value:

- **Do correlate** when the codebase survey reveals significant existing integration that needs comparing against best practices (e.g., the repo already uses the technology and you need to assess alignment with ecosystem recommendations).
- **Skip to Step 4** when the research is primarily about external tooling/ecosystem options and the codebase survey already captured the current state clearly (e.g., "no integration exists" or "only uses feature X").

If correlating, dispatch Codex again (one per repo, `run_in_background: true`). Use absolute paths for `tee`:

```bash
cd <repo-path> && codex exec --full-auto "<correlation prompt>" | tee <absolute-path-to-working-dir>/.co-research/codex-correlation-<repo-slug>.md
```

The correlation prompt:
```
Based on these ecosystem findings, analyze how this codebase compares:

Key recommendations from research:
- [Recommendation 1]
- [Recommendation 2]
- [Recommendation 3]

For each recommendation, report:
- Current state: does the codebase already follow this? (with file paths as evidence)
- Gap: what's missing or divergent?
- Effort: what would it take to adopt? (files to change, dependencies to add/remove)

Write your findings as structured markdown.
```

Wait for all background tasks to complete.

## Step 4 — Synthesize

Read all files in `.co-research/`. Merge into a single document at `.co-research/draft.md` using this structure:

```markdown
# [Topic]: Research Summary

> Researched [date]. Based on web research and codebase analysis of [repo name(s)].

## Executive Summary
[3-5 sentences. What the research found, the key takeaway, and the recommended direction.]

## Key Concepts
[Definitions, mental models, and foundational ideas the reader needs. Write for someone encountering this topic for the first time but who is technically competent.]

## Ecosystem Landscape
[Major tools, libraries, frameworks. Comparison table where appropriate. Community health, adoption trends, maintenance status.]

| Tool/Approach | Maturity | Adoption | Key Strength | Key Weakness |
|---------------|----------|----------|--------------|--------------|
| ... | ... | ... | ... | ... |

## Best Practices
[What authoritative sources recommend. Common pitfalls. Patterns to follow and anti-patterns to avoid.]

## Current State
[From Codex survey. What exists in the codebase today. Relevant configs, dependencies, patterns in use. File paths as evidence.]

## Gap Analysis
[From Codex correlation. How the codebase compares to ecosystem recommendations. What's already aligned, what's missing, what's divergent.]

| Recommendation | Current State | Gap | Effort |
|----------------|---------------|-----|--------|
| ... | ... | ... | ... |

## Trade-offs & Decision Points
[Key choices the user will face. Present both sides. Be opinionated about which way to lean and why.]

## Recommended Approach
[Concrete, opinionated recommendation. Reference the gap analysis — what to adopt, what to skip, what to phase in. Order of operations if relevant.]

## References & Sources
[All URLs cited in the document, grouped by section]

## Open Questions
[What the research couldn't answer. What needs hands-on experimentation. What depends on team decisions.]
```

## Step 5 — Review & Save

Present the draft to the user.

Ask: "Where should I save this? Default: `docs/research-<topic-slug>.md`"

Wait for confirmation. Write the final document to the specified path.

Tell the user the `.co-research/` working directory still exists and they can delete it manually if they want:
```
rm -rf .co-research/
```
Do NOT attempt to delete it yourself — this is a destructive operation the user should run.
