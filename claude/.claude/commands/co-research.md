---
command: co-research
description: Use when a topic needs multi-angle deep research before a decision. Dispatches parallel agents and Codex, then synthesizes into a reference document.
argument-hint: <research topic as a phrase>
---

# Co-Research: Claude Explores, Codex Surveys, You Decide

## File Writing Rules

- **Main agent**: Use the `Write` tool for all `.co-research/` files (plan.md, draft.md, final output). Never use `cat`, `echo`, or heredoc redirects via Bash.
- **Claude subagent placeholders**: Before dispatching Claude subagents, use the main agent's `Write` tool to create a placeholder for each expected output file with a single line of content (e.g., `# Placeholder`). This ensures subagents get clean `Read` output (0-byte files from `touch` produce confusing warnings) and satisfies the Read-before-Write requirement.
- **Pre-dispatch setup** (run once before Step 3a): for each Claude subagent output file, use `Write` to create a placeholder:
  ```
  Write .co-research/claude-<angle1-slug>.md  →  "# Placeholder"
  Write .co-research/claude-<angle2-slug>.md  →  "# Placeholder"
  ...
  ```
  Match the number of angles (3-5) and slugs to the actual research plan.

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

Decompose the topic into 3-5 research angles. Use the `Write` tool to create `.co-research/plan.md`:

```markdown
# Research Plan: [Topic]

## Angles
1. **[Angle name]** — [What to investigate. Both Claude and Codex research each angle.]
2. **[Angle name]** — [...]
3. **[Angle name]** — [...]

## Codex Survey Prompt
[Tailored prompt for first Codex pass — specific files, configs, patterns to look for]

## Codex Web Search Prompts
1. **[Angle name]** — [Focused web search prompt for this angle]
2. **[Angle name]** — [...]
3. **[Angle name]** — [...]

## Additional Repos
- [repo path] (if any, otherwise "Current repo only")
```

Present to user: "Here's the research plan. Proceed or adjust?"
Wait for confirmation.

## Step 3a — Parallel First Dispatch

Launch all research streams simultaneously. All Codex dispatches use `~/.claude/scripts/codex-research.sh` — never inline `codex exec` commands.

**Codex — Codebase Survey** (one per repo):

For each repo, run via `Bash` tool with `run_in_background: true`. Derive a slug from the repo directory name (e.g., `neb-www`, `neb-ms-patients`).

```bash
~/.claude/scripts/codex-research.sh \
  --repo <repo-path> \
  --output <absolute-path-to-working-dir>/.co-research/codex-survey-<repo-slug>.md \
  <<'PROMPT'
Survey this codebase for [specific topic elements].

Report the following:
- Relevant dependencies (from package.json, go.mod, requirements.txt, etc.)
- Existing configuration files related to [topic]
- Current patterns in use (with file paths and brief excerpts)
- Gaps or inconsistencies you notice

Write your findings as structured markdown.
PROMPT
```

If only one repo, the slug is just the repo name (e.g., `codex-survey-neb-www.md`).

The Codex prompt must be self-contained (no conversation context). Tailor the template above to the specific survey from the research plan.

**Codex — Web Research** (one per angle, parallel):

For each research angle, run via `Bash` tool with `run_in_background: true`. Derive a slug from the angle name (e.g., `ecosystem`, `practices`, `experiences`).

```bash
~/.claude/scripts/codex-research.sh \
  --web-search \
  --output <absolute-path-to-working-dir>/.co-research/codex-web-<angle-slug>.md \
  <<'PROMPT'
Research [specific angle] for [topic].

Report the following as structured markdown:
- Key findings with source URLs for every claim
- Comparison of major options/approaches where applicable
- Notable community sentiment or adoption trends
- Any caveats, risks, or common pitfalls

Include source URLs inline next to each finding.
PROMPT
```

The Codex prompt must be self-contained and request structured markdown with source URLs. Tailor the template above to the specific angle from the research plan.

**Claude Subagents — Web Research** (one per angle via Agent tool, parallel):

Each agent gets one research angle — launch one Claude subagent per angle so every angle gets dual coverage (Claude + Codex). Use `subagent_type: "research"`. Each agent should:
- Use `WebSearch` and `WebFetch` to research its angle
- Write findings to `.co-research/claude-<angle-slug>.md`
- Include source URLs for every claim

**IMPORTANT:** Agent prompts must be directive — tell agents to do the research and write findings immediately. Do NOT leave room for agents to ask for confirmation or propose a plan. End each prompt with: "Read the output file first with the Read tool, then write your findings with the Write tool. Do the research now. Do not ask for confirmation."

**IMPORTANT:** Each agent prompt MUST include this file-writing instruction: "IMPORTANT: Before writing, use the Read tool on your output file (it exists as a placeholder). Then use the Write tool to save your findings. Do NOT use Bash cat/echo/heredoc redirects."

Example agent prompts (each must include the Read-then-Write instruction from above):
- "Research the current ecosystem landscape for [topic]. Compare major tools/libraries, their adoption, maintenance status, and community sentiment. IMPORTANT: Before writing, use the Read tool on `.co-research/claude-ecosystem.md` (it exists as a placeholder). Then use the Write tool to save your findings with source URLs. Do NOT use Bash cat/echo/heredoc redirects. Do the research now. Do not ask for confirmation."
- "Research best practices and common pitfalls for [topic]. Focus on authoritative sources (official docs, well-known blog posts, conference talks). IMPORTANT: Before writing, use the Read tool on `.co-research/claude-practices.md` (it exists as a placeholder). Then use the Write tool to save your findings with source URLs. Do NOT use Bash cat/echo/heredoc redirects. Do the research now. Do not ask for confirmation."
- "Research real-world case studies and migration stories for [topic]. What did teams learn? What surprised them? IMPORTANT: Before writing, use the Read tool on `.co-research/claude-experiences.md` (it exists as a placeholder). Then use the Write tool to save your findings with source URLs. Do NOT use Bash cat/echo/heredoc redirects. Do the research now. Do not ask for confirmation."

Wait for all dispatches to complete (Bash background tasks will notify on completion; Task agents return when done).

## Step 3b — Correlation Dispatch (Conditional)

Read all findings from Step 3a. Evaluate whether a second Codex pass adds value:

- **Do correlate** when the codebase survey reveals significant existing integration that needs comparing against best practices (e.g., the repo already uses the technology and you need to assess alignment with ecosystem recommendations).
- **Skip to Step 4** when the research is primarily about external tooling/ecosystem options and the codebase survey already captured the current state clearly (e.g., "no integration exists" or "only uses feature X").

If correlating, dispatch Codex again (one per repo, `run_in_background: true`):

```bash
~/.claude/scripts/codex-research.sh \
  --repo <repo-path> \
  --output <absolute-path-to-working-dir>/.co-research/codex-correlation-<repo-slug>.md \
  <<'PROMPT'
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
PROMPT
```

Wait for all background tasks to complete.

## Step 4 — Synthesize

Read all files in `.co-research/`. When merging, cross-reference Claude and Codex web findings per angle:
- **Both agree** → high-confidence finding, state it as established
- **Only one found it** → include it but note the single source
- **They contradict** → flag the disagreement and present both sides for user judgment

Use the `Write` tool to create `.co-research/draft.md` using this structure:

```markdown
# [Topic]: Research Summary

> Researched [date]. Based on web research (Claude + Codex) and codebase analysis of [repo name(s)].

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

Ask: "Where should I save this? Default: `docs/research-<topic-slug>-YYYY-MM-DD.md`"

Wait for confirmation. Use the `Write` tool to save the final document to the specified path.

Clean up the working directory:
```
rm -rf .co-research/
```
