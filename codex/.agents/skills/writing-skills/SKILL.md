---
name: writing-skills
description: ALWAYS invoke when creating, updating, or optimizing skills in this repo.
---

# Writing Skills

## Overview

Skills are reusable methodology guides that agents load when relevant. Good skills are discoverable, concise, and actionable. The format follows the open [Agent Skills spec](https://agentskills.io/specification) — skills work across Claude Code, Codex, and other compatible agents.

This skill covers authoring conventions and description optimization for triggering accuracy.

## Skill Precedence

- This is the primary skill for all skill work in this repo — creation, maintenance, and optimization.
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

**Repo policy: disabling auto-invocation requires both platforms.** When setting `disable-model-invocation: true` in SKILL.md, always also create `agents/openai.yaml` with `allow_implicit_invocation: false`. Claude Code reads the frontmatter; Codex reads the YAML when supported. Omitting either may leave the skill auto-invocable on that platform. This is a repo convention to ensure consistent behavior — not a universal runtime guarantee, since Codex support for `agents/openai.yaml` varies by environment.

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

# GOOD: Directive + escape-hatch blocker - achieves 100% activation
description: ALWAYS invoke for bugs, test failures, flaky tests, or unexpected behavior with a non-obvious root cause. Do not debug directly.
```

**Rules:**
- Start with "ALWAYS invoke for..." for user-invocable skills
- Include a negative constraint ("Do not X directly") when it blocks the model's default path of answering without the skill — this is the high-value constraint
- "Not for..." boundaries are optional. Only add them when overtriggering between two specific skills is an observed problem, not a theoretical one. Every token in the description is loaded into every session context
- Background/non-invocable skills may use concise declarative descriptions with "not invoked directly" or equivalent boundary language
- Describe triggers/symptoms, NOT what the skill does
- Max 1024 characters (spec limit), aim for under 500
- Include adjacent phrasings and edge-case contexts to cover how users actually ask

**Why this works:** Passive descriptions leave the model a choice; directive descriptions with negative constraints close the escape hatch. For the full evidence base (650-trial study, academic research, root cause analysis), see `references/research-skill-invocation.md`.

## SKILL.md Template

```markdown
---
name: skill-name
description: ALWAYS invoke for [triggering conditions]. Do not [action] directly.
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

1. Define the trigger first — write a trigger-only description (add "Not for..." boundaries only when overtriggering is observed, per Description Best Practices)
2. Create the canonical folder in `codex/.agents/skills/<skill-name>/` with `name` matching directory name
3. Keep SKILL.md lean, push heavy detail to `references/`, reusable code to `scripts/`, templates to `assets/`
4. If `disable-model-invocation: true`, also create `agents/openai.yaml` with `allow_implicit_invocation: false` (repo policy — see Codex extensions above)
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
# Skills with disable-model-invocation: true use declarative style (no "ALWAYS invoke")
for f in codex/.agents/skills/*/SKILL.md; do
  if rg -q '^user-invocable:[[:space:]]*false' "$f" || rg -q '^description: .*not invoked directly' "$f"; then
    continue
  fi
  if rg -q '^disable-model-invocation:[[:space:]]*true' "$f"; then
    continue  # manual-only skills use declarative descriptions
  fi
  rg -q '^description: ALWAYS invoke' "$f" || echo "Description style issue (expected 'ALWAYS invoke' prefix): $f"
done

# Ensure disable-model-invocation skills have agents/openai.yaml (repo policy)
for f in codex/.agents/skills/*/SKILL.md; do
  if rg -q '^disable-model-invocation:[[:space:]]*true' "$f"; then
    d=$(dirname "$f")
    [ -f "$d/agents/openai.yaml" ] && rg -q 'allow_implicit_invocation:[[:space:]]*false' "$d/agents/openai.yaml" \
      || echo "Missing or incomplete agents/openai.yaml: $f (disable-model-invocation requires both)"
  fi
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

### Runtime Paths

The source path (`codex/.agents/skills/`) is where you edit. But skills that reference helper scripts at runtime must use the **installed** paths, which differ by platform:

| Platform | Runtime path |
|----------|-------------|
| Codex | `~/.agents/skills/personal/<skill-name>/` |
| Claude Code | `~/.claude/skills/<skill-name>/` |

When documenting script invocation in SKILL.md, list both paths and use a resolve-with-fallback pattern:

```bash
# Resolve script path (Codex first, Claude Code fallback)
SCRIPT_PATH="$HOME/.agents/skills/personal/<skill-name>/scripts/<script>.sh"
[[ -x "$SCRIPT_PATH" ]] || SCRIPT_PATH="$HOME/.claude/skills/<skill-name>/scripts/<script>.sh"
```

Do not use the source path (`codex/.agents/skills/...`) in runtime references — it only exists in the dotfiles repo, not on the installed system.

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

Present the eval queries for review. Walk through edge cases — are the should-trigger queries realistic? Are the should-not-trigger queries genuine near-misses? Adjust based on feedback.

### Step 3: Manual trigger testing

Test a handful of should-trigger and should-not-trigger queries in a live interactive session. Observe whether the skill triggers or the agent answers directly. Focus on edge cases and near-misses — the queries you're least confident about.

If a should-trigger query doesn't trigger, iterate on the description: add adjacent phrasings, make trigger conditions more explicit, or broaden the symptom language. Retest.

### Step 4: Apply the result

Update the skill's SKILL.md frontmatter with the improved description. Show the user before/after.

---

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
