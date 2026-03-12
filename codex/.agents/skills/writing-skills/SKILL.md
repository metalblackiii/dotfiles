---
name: writing-skills
description: ALWAYS invoke when creating, updating, testing, or optimizing skills in this repo.
---

# Writing Skills

## Overview

Skills are reusable methodology guides that agents load when relevant. Good skills are discoverable, concise, and actionable. The format follows the open [Agent Skills spec](https://agentskills.io/specification) — skills work across Claude Code, Codex, and other compatible agents.

This skill covers the full lifecycle: authoring conventions, eval-driven iteration, and description optimization for triggering accuracy.

## Skill Precedence

- This is the primary skill for all skill work in this repo — creation, maintenance, testing, and optimization.
- Do not rely on name shadowing (e.g., creating a local `skill-creator`) to override system behavior. Runtime precedence is implementation-dependent and may change.

## Frontmatter Reference

### Standard fields (agentskills.io spec)

These fields are recognized by all spec-compliant agents:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | **Yes** | Must match parent directory name. Lowercase letters, numbers, hyphens only. Max 64 chars. No leading/trailing/consecutive hyphens. |
| `description` | **Yes** | When to use this skill. Agents use this to decide when to load it. Max 1024 chars. |
| `license` | No | License name or reference to bundled license file |
| `compatibility` | No | Environment requirements (e.g., "Requires git, docker"). Max 500 chars. |
| `metadata` | No | Arbitrary key-value pairs (e.g., `author`, `version`) |
| `allowed-tools` | No | Space-delimited tools the skill may use (experimental, support varies) |

### Claude Code extensions

These fields are only recognized by Claude Code and are ignored by other agents:

| Field | Description |
|-------|-------------|
| `argument-hint` | Hint shown during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | Set `true` to prevent auto-loading. For manual-only workflows. |
| `user-invokable` | Set `false` to hide from `/` menu. For background knowledge skills. |
| `model` | Model to use when skill is active (e.g., `opus`, `sonnet`) |
| `context` | Set to `fork` to run in isolated subagent context |
| `agent` | Subagent type when `context: fork` (e.g., `Explore`, `Plan`) |
| `hooks` | Skill-scoped hooks (see Hooks documentation) |

### Codex extensions (optional/future-facing)

When available in a Codex runtime, these fields live in `agents/openai.yaml` inside the skill directory (not in SKILL.md frontmatter). Some environments may not support this file yet.

| Field (in `agents/openai.yaml`) | Description |
|---|---|
| `policy.allow_implicit_invocation` | Set `false` to prevent auto-selection. Codex equivalent of `disable-model-invocation`. Default: `true`. |
| `interface.display_name` | User-facing skill name in the Codex app |
| `interface.short_description` | User-facing description |

When disabling auto-invocation, set `disable-model-invocation: true` in SKILL.md frontmatter (Claude Code) and, when `agents/openai.yaml` is supported, set `allow_implicit_invocation: false` there for cross-platform consistency.

**Max frontmatter size:** 1024 characters total

## Description Best Practices

The description determines when Claude loads your skill. It's the primary triggering mechanism.

```yaml
# BAD: Summarizes workflow - Claude may follow description instead of reading skill
description: Use for TDD - write test first, watch it fail, write minimal code

# BAD: Too vague
description: For debugging

# BAD: Passive "Use when" - achieves ~77% activation (650-trial study)
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes

# GOOD: Directive + negative constraint - achieves 100% activation
description: ALWAYS invoke for bugs, test failures, flaky tests, or unexpected behavior with a non-obvious root cause. Do not debug directly. Not for typos or single-line fixes where the cause is already clear.
```

**Rules:**
- Start with "ALWAYS invoke for..." for user-invocable skills
- Include a negative constraint ("Do not X directly") to block the model's default path of answering without the skill
- End with "Not for..." to define the boundary and prevent overtriggering
- Background/non-invocable skills may use concise declarative descriptions with "not invoked directly" or equivalent boundary language
- Describe triggers/symptoms, NOT what the skill does
- Max 1024 characters (spec limit), aim for under 500
- Include adjacent phrasings and edge-case contexts to cover how users actually ask

**Why this works:** Passive descriptions leave the model a choice; directive descriptions with negative constraints close the escape hatch. For the full evidence base (650-trial study, academic research, root cause analysis), see `references/research-skill-invocation.md`.

## SKILL.md Template

```markdown
---
name: skill-name
description: ALWAYS invoke for [triggering conditions]. Do not [action] directly. Not for [boundary].
---

# Skill Name

## Overview
Core principle in 1-2 sentences.

## When to Use
- Symptoms and situations
- When NOT to use

## The Iron Law (for discipline skills)
The non-negotiable rule.

## [Core Content]
Techniques, patterns, quick reference tables.

## Common Rationalizations (for discipline skills)
| Excuse | Reality |
|--------|---------|

## Red Flags - STOP
Bullet list of warning signs.
```

**Writing guidelines:**
- Use imperative form in instructions
- Explain the *why* behind instructions — reasoning is more effective than rigid MUSTs
- Keep SKILL.md under 500 lines; push heavy reference to `references/`, reusable code to `scripts/`
- For large reference files (>300 lines), include a table of contents
- Make skills general, not narrow to specific examples — avoid overfitting

## Creating a New Skill

### Capture Intent

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs (file transforms, code generation, fixed workflow steps) benefit most. Skills with subjective outputs (writing style, methodology) often don't need them.

Proactively ask about edge cases, input/output formats, success criteria, and dependencies before writing.

### Write the Skill

Create the skill directory in the canonical location:

```bash
mkdir codex/.agents/skills/my-skill-name
# Then create SKILL.md with proper frontmatter
```

Both Claude and Codex share this directory — Claude accesses it via a symlink at `claude/.claude/skills`.

### Authoring Workflow

1. Define the trigger and boundary first — write a trigger-only description
2. Create the canonical folder in `codex/.agents/skills/<skill-name>/` with `name` matching directory name
3. Keep SKILL.md lean, push heavy detail to `references/`, reusable code to `scripts/`, templates to `assets/`
4. Maintain optional Codex UI metadata when used — keep `agents/openai.yaml` aligned with SKILL.md semantics
5. Run validation checks before completion

### Validation Snippets

```bash
# Ensure each skill has SKILL.md
rg --files codex/.agents/skills | rg '/SKILL\.md$'

# Ensure required frontmatter keys exist
for f in codex/.agents/skills/*/SKILL.md; do
  rg -q '^name: ' "$f" && rg -q '^description: ' "$f" || echo "Missing keys: $f"
done

# Ensure description style matches intended invocability
for f in codex/.agents/skills/*/SKILL.md; do
  if rg -q '^user-invocable:[[:space:]]*false' "$f" || rg -q '^description: .*not invoked directly' "$f"; then
    continue
  fi
  rg -q '^description: ALWAYS invoke' "$f" || echo "Description style issue (expected 'ALWAYS invoke' prefix): $f"
done

# Ensure referenced relative files exist
for f in codex/.agents/skills/*/SKILL.md; do
  d=$(dirname "$f")
  rg -o --no-filename '`(\.\./[^`]+|references/[^`]+|scripts/[^`]+|assets/[^`]+)`' "$f" | tr -d '`' | while read -r p; do
    [ -e "$d/$p" ] || echo "Missing reference: $f -> $p"
  done
done
```

## Directory Structure

```
codex/.agents/skills/         # Source of truth — all skills live here
  skill-name/
    SKILL.md              # Required - main content
    scripts/              # Optional - executable code
    references/           # Optional - detailed docs, loaded on demand
    assets/               # Optional - templates, schemas, data files
```

**Keep inline:** Principles, code patterns (<50 lines), everything else
**Separate files (`references/`):** Heavy reference (100+ lines), loaded on demand by the agent
**Executable code (`scripts/`):** Reusable executable helpers the agent can run

## Quick Checklist

- [ ] Name: required, must match directory name, lowercase/numbers/hyphens only, no leading/trailing/consecutive hyphens
- [ ] Description: "ALWAYS invoke for..." for user-facing skills; declarative style allowed for clearly non-invocable/background skills
- [ ] Overview: core principle in 1-2 sentences
- [ ] Content: actionable, scannable (tables, bullets)
- [ ] For discipline skills: Iron Law, rationalizations table, red flags
- [ ] README: if adding or removing a skill, update the skills table in repo root README
- [ ] Size: <500 words for most skills, <200 for frequently-loaded

---

## Description Optimization

After creating or improving a skill, validate the description for triggering accuracy using eval queries and manual testing.

### Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger (8-10) and should-not-trigger (8-10). Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

**Query quality matters.** Queries must be realistic — concrete, specific, with detail like file paths, personal context, column names, casual speech, typos, varied lengths. Focus on edge cases, not clear-cut matches.

Bad: `"Format this data"`, `"Create a chart"`

Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage"`

**Should-trigger queries:** Different phrasings of the same intent — formal and casual. Include cases where the user doesn't explicitly name the skill but clearly needs it. Uncommon use cases and competitive triggers where this skill should win.

**Should-not-trigger queries:** Near-misses are the most valuable — queries sharing keywords or concepts but needing something different. Adjacent domains, ambiguous phrasing where naive keyword matching would falsely trigger. Don't use obviously irrelevant queries.

### Step 2: Review with user

Present the eval set using the HTML template:

1. Read `assets/eval_review.html`
2. Replace `__EVAL_DATA_PLACEHOLDER__` with the JSON array, `__SKILL_NAME_PLACEHOLDER__` with the skill name, `__SKILL_DESCRIPTION_PLACEHOLDER__` with current description
3. Write to a temp file and open it: `open /tmp/eval_review_<skill-name>.html`
4. User edits queries, toggles triggers, clicks "Export Eval Set"
5. Read the exported file from `~/Downloads/eval_set.json`

### Step 3: Manual trigger testing

Test a handful of should-trigger and should-not-trigger queries in a live interactive session. Observe whether the skill triggers or the agent answers directly. Focus on edge cases and near-misses — the queries you're least confident about.

If a should-trigger query doesn't trigger, iterate on the description: add adjacent phrasings, make trigger conditions more explicit, or broaden the symptom language. Retest.

### Step 4: Apply the result

Update the skill's SKILL.md frontmatter with the improved description. Show the user before/after.

---

## Eval-Driven Iteration

For skills with objectively verifiable outputs, run test prompts to measure quality and iterate.

### When to use evals

Use the full eval loop when a skill produces structured, verifiable output — file transforms, code generation, data extraction, fixed workflow steps. Skip it for subjective/methodology skills (debugging process, review checklists) where human judgment is the only meaningful evaluation.

### The core loop

1. Write 2-3 realistic test prompts (save to `evals/evals.json` — see `references/schemas.md`)
2. Spawn subagent test runs: with-skill vs baseline, in parallel
3. Grade outputs against assertions
4. Launch the eval viewer for human review
5. Read feedback, improve the skill, repeat

For the detailed step-by-step workflow (workspace layout, subagent prompts, grading, benchmarking, viewer commands), read `references/eval-workflow.md`.

### Improvement Philosophy

When iterating on a skill based on eval feedback:

1. **Generalize from feedback.** The few test cases help iterate fast, but the skill will be used across many different prompts. Avoid overfitting to specific examples — if something is stubbornly failing, try different approaches or metaphors rather than adding rigid constraints.

2. **Keep the skill lean.** Read the test transcripts, not just final outputs. If the skill makes the agent waste time on unproductive steps, remove those instructions.

3. **Explain the why.** Frame instructions around reasoning rather than rigid rules. ALWAYS/NEVER in caps is a yellow flag — reframe with the reasoning so the model understands what matters and can generalize.

4. **Extract repeated work.** If all test runs independently build similar helper scripts or take the same multi-step approach, that's a signal to bundle the script in `scripts/` so future invocations don't reinvent it.

---

## Bundled Resources

This skill includes infrastructure for eval-driven iteration:

- `agents/` — Subagent instructions for grading (`grader.md`), blind comparison (`comparator.md`), and analysis (`analyzer.md`)
- `eval-viewer/` — HTML viewer for reviewing test outputs (`viewer.html`)
- `assets/` — Eval review HTML template for description optimization
- `references/` — JSON schemas (`schemas.md`) and detailed eval workflow (`eval-workflow.md`)

## Cross-References

**For introspect integration**, when `introspect` rates a description NEEDS WORK or WEAK, feed it into the Description Optimization workflow above.

**For the open spec**, see [agentskills.io/specification](https://agentskills.io/specification). Platform skill docs: [Claude Code](https://code.claude.com/docs/en/skills) | [Codex](https://developers.openai.com/codex/skills).

## Anti-Patterns

- **Workflow in description** — Claude follows description instead of reading skill
- **Narrative examples** — "In session X, we found..." — not reusable
- **Multi-language examples** — One excellent example beats many mediocre ones
- **Generic names** — `helper`, `utils`, `process` — name by what you DO
- **Overfitting to test cases** — Rigid constraints for specific examples rather than general principles
- **Heavy-handed MUSTs** — Explain the reasoning instead of shouting
- **Routing/delegation patterns** — Skills should be self-contained reference files, not routers that point to external SKILL.md files. If content is shared, inline it or use `references/` subdirectories.
