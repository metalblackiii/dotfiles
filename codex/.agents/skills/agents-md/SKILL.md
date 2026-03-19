---
name: agents-md
description: ALWAYS invoke when creating, editing, auditing, or discussing AGENTS.md, CLAUDE.md, or any AI coding agent instruction file — including incidental edits during broader tasks (e.g., updating AGENTS.md after adding a feature). Do not edit or advise on these files without loading this skill first. System-prompt CLAUDE.md references do NOT count. Not for skills (use writing-skills), hooks, or settings.json.
allowed-tools: Bash, Read, Glob, Grep
---

# Writing AGENTS.md / CLAUDE.md

## Overview

Checklist-driven workflow for writing or auditing AI coding agent instruction files (AGENTS.md, CLAUDE.md, .cursorrules, .windsurfrules, copilot-instructions.md, .clinerules, .rules). Three modes: simplify an existing file (fast prune pass), full audit, or write a new one.

## The Iron Law

> If the agent could discover it by reading the repository, it does not belong in the instruction file.

**Corollary: When in doubt, leave it out.** AI agents tend to overspecify when writing or fixing instruction files — adding context "just in case" that erodes the signal-to-noise ratio. Every line has a cost: tokens consumed, compliance diluted across remaining rules, maintenance burden. The bias is always toward less.

## When to Use

**Triggers:**
- Evaluating whether a repo needs an instruction file ("should we add", "do we need", "is it worth")
- Creating a new AGENTS.md or CLAUDE.md
- Auditing an existing instruction file for quality
- Auditing based on actual agent usage ("what's working", "audit from sessions")
- Pruning a bloated instruction file
- Migrating between formats (CLAUDE.md ↔ AGENTS.md)
- Reviewing instruction file changes in a PR
- Editing AGENTS.md/CLAUDE.md as part of a broader task (e.g., adding a build command to AGENTS.md after implementing a feature)

**NOT for:**
- Writing or editing skills → use `writing-skills`
- Hook configuration or settings.json → edit directly
- README, ADR, or documentation files → not instruction files

## Reference Guide

Load reference files on demand — don't read all upfront.

| File | Load When |
|---|---|
| `references/anti-patterns.md` | Phase 3 quality gate; when checking for known failure modes |
| `references/include-exclude-guide.md` | Deciding what belongs in the file; applying the litmus test |
| `references/structural-taxonomy-template.md` | Drafting a new file; checking section structure |
| `references/platform-comparison.md` | Multi-tool repos; choosing file strategy; checking size limits |

## Phase 1: Discovery

Both modes start here. Run these checks to understand the current state.

### 1.1 Find all instruction files

```bash
# Find all known instruction file types
rg --files | rg -i '(agents\.md|claude\.md|\.cursorrules|\.windsurfrules|copilot-instructions\.md|\.clinerules|^\.rules)$'
```

Also check for nested/scoped rules:
```bash
# Claude Code scoped rules
rg --files .claude/rules/ 2>/dev/null
# Cursor scoped rules
rg --files .cursor/rules/ 2>/dev/null
```

### 1.2 Measure each file

```bash
wc -l <file>  # Flag if >200 lines
```

### 1.3 Check symlinks

For each discovered instruction file, check whether it's a symlink and resolve the target:
```bash
# Check each discovered file — not just root-level
ls -la <each discovered file> 2>/dev/null
```

Instruction files may live at non-root paths (e.g., `codex/AGENTS.md`, `claude/.claude/CLAUDE.md`). Use the discovery results from 1.1, not hardcoded root paths.

### 1.4 Classify relationship

If both an AGENTS.md and CLAUDE.md exist (at any path), determine which pattern is in use:
- **Symlinked**: Both files resolve to the same target (or one symlinks to the other) — valid; treat as single file
- **Stub redirect**: CLAUDE.md contains only `@AGENTS.md` (or vice versa) — clean
- **Independent**: Different content serving different purposes — check for contradictions
- **Duplication**: Same or near-identical content **and neither is a symlink** — anti-pattern, consolidate

### 1.5 Branch

- **No instruction files exist** → Write mode (Phase 2b)
- **Files exist, user wants simplify/prune** → Simplify mode: run Phase 2a checks 1-2 only (non-inferable details + size), then skip to Phase 3.2 bloat ratio and Phase 4 audit output
- **Files exist, user wants full audit** → Phase 2a (all 7 checks)
- **Files exist, user wants usage-based audit** → Phase 2c (conversation mining), then Phase 2a for static checks
- **Files exist, user wants rewrite** → Phase 2b

## Phase 2a: Audit

Run these 7 mechanical checks against the existing file. Each produces concrete findings.

### Check 1: Non-Inferable Details Test

Read the instruction file, then read key codebase files (package.json, Makefile, README, CI config, linter config). For each line in the instruction file, ask: "Could the agent discover this by reading the repository?" Flag discoverable lines for removal.

Load `references/include-exclude-guide.md` if unsure about edge cases.

### Check 2: Size

```bash
wc -l <file>
```

- Under 100 lines: good
- 100-200 lines: acceptable, check for pruning opportunities
- Over 200 lines: flag — recommend splitting into root + satellite docs

### Check 3: Emphasis Density

```bash
rg -c '(IMPORTANT|CRITICAL|MUST|NEVER|YOU MUST)' <file>
```

- 0-5 markers: healthy
- 6-10 markers: review each — do they all protect against real failures?
- Over 10 markers: emphasis fatigue — signal has become noise

**Self-test:** Can you identify the 3-5 most critical rules by reading only the emphasized text?

### Check 4: Structure

Compare the file's heading structure against the taxonomy in `references/structural-taxonomy-template.md`. Check:
- Are non-negotiable constraints at the top? (Lost in the Middle)
- Are executable commands early with full flags?
- Is architecture descriptive (bad) or decisional (good)?
- Are references at the end, not inlined?

### Check 5: Boundary Format

Look for hard constraints. Are they expressed in the three-tier format?

| Tier | Meaning | Example |
|---|---|---|
| **Always** | Do this every time, no exceptions | "Always run `make lint` before committing" |
| **Ask first** | Check with user before proceeding | "Ask before modifying database migrations" |
| **Never** | Forbidden action | "Never push directly to main" |

If constraints are buried in prose paragraphs, flag for restructuring.

### Check 6: Hook Candidates

Identify prose rules that express absolute requirements — things that must always happen or never happen. These are hook candidates:
- "NEVER commit .env files" → pre-commit hook with secrets detection
- "Always run linter before commit" → pre-commit hook
- "Never use `rm -rf` on production paths" → bash permission hook

Flag each with: "This rule would be more reliable as a hook."

### Check 7: Cross-Platform Consistency

If multiple instruction files exist (AGENTS.md + CLAUDE.md, or .cursorrules alongside):
- Check for contradictions between files
- Verify the relationship pattern is intentional
- Flag duplication as anti-pattern

Load `references/platform-comparison.md` for relationship pattern guidance.

## Phase 2b: Write

### 2b.1 Survey the Repository

Read these files to understand the project:
- README.md (project purpose, setup)
- package.json / Cargo.toml / go.mod (stack, scripts)
- CI config (.github/workflows/, Jenkinsfile)
- Linter config (.eslintrc, biome.json, .prettierrc)
- Existing instruction files (if migrating)

### 2b.2 Interview the User

Ask for non-inferable details — things you can't discover from the repo:
- Non-obvious build/test commands and their execution order
- Operational landmines (things that break in non-obvious ways)
- Hard constraints (security, compliance, irreversible operations)
- Workflow conventions (branch naming, PR process, review expectations)
- Tool preferences not captured in config

### 2b.3 Apply the Litmus Test

For each candidate line from the survey and interview:
1. Could the agent discover this by reading the repo? → Exclude
2. Would removing this cause the agent to make mistakes? → Include if yes
3. Is this already enforced by a linter or hook? → Exclude (note the tool instead)

### 2b.4 Choose File Strategy

**Default to AGENTS.md as canonical.** It's the cross-platform standard (20+ tools, Linux Foundation governance). Use CLAUDE.md only when Claude-specific features (@imports, path-scoped rules references, skills references) add value the shared file can't express.

- **Most repos**: AGENTS.md canonical + CLAUDE.md stub (`@AGENTS.md`)
- **Claude-specific features needed**: AGENTS.md canonical + CLAUDE.md supplements (never duplicates)
- **Dotfiles repo**: Symlink strategy per `references/platform-comparison.md`
- **Large project (>100 lines of content)**: Progressive disclosure (root + satellite docs)

### 2b.5 Draft Using Taxonomy

Load `references/structural-taxonomy-template.md` and draft the file following the section order. Omit sections that have no content — an empty section is worse than a missing one.

### 2b.6 Bloat Guard (Deletion Pass)

After drafting, do a deletion pass. For each line ask: "Would removing this cause the agent to make mistakes?" If not, cut it.

AI has a strong tendency to overspecify when generating these files. This step must actively counteract that by defaulting to omission over inclusion.

## Phase 2c: Usage Audit (Conversation Mining)

Empirical audit mode — analyze what the agent *actually did* in real sessions, not just what the instruction file says.

### 2c.1 Locate Session Logs

Discover available conversation history. Use `find` (not bare globs) to avoid zsh `no matches found` errors:

```bash
# Claude Code — JSONL logs: ~/.claude/projects/<project-hash>/<uuid>.jsonl
find ~/.claude/projects/ -name '*.jsonl' -maxdepth 2 -type f 2>/dev/null | head -20

# Codex — JSONL logs: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
find ~/.codex/sessions/ -name '*.jsonl' -type f 2>/dev/null | head -20

# If no logs found at known locations, ask the user where session history lives
```

Sort by modification time and pick the 5-10 most recent sessions relevant to the project being audited. If the project has a known path, filter Claude logs by project-hash directory name (path segments joined by hyphens, e.g., `-Users-martinburch-repos-myproject`).

### 2c.2 Extract and Sample

Log schemas differ by platform. Use the correct extractor:

```bash
# Claude Code: top-level "type" field — look for "user" and "assistant" records
jq -r 'select(.type == "assistant") | .content' <logfile> 2>/dev/null | head -200
jq -r 'select(.type == "user") | .content' <logfile> 2>/dev/null | head -200

# Codex: wrapped in type/payload — assistant content is in response_item records
jq -r 'select(.type == "response_item") | .payload | select(.role == "assistant" or .type == "function_call") | .content // .arguments // .name' <logfile> 2>/dev/null | head -200
jq -r 'select(.type == "event_msg") | .payload | select(.type == "user_message") | .message' <logfile> 2>/dev/null | head -200
```

If extractors return empty, the schema may have changed — sample a few raw lines with `head -5 <logfile>` and adapt the jq filters.

Focus on:
- **Tool calls the agent made** — what actions did it take?
- **User corrections** — "no, don't do that", "I said to...", "wrong approach"
- **Repeated patterns** — same mistake across sessions = missing rule
- **Rules the agent followed without needing the instruction file** — already-known behavior

### 2c.3 Cross-Reference Against Instruction File

For each rule in the instruction file, classify:

| Category | Meaning |
|---|---|
| **Followed** | Agent complied in sessions where the rule was relevant |
| **Violated** | Agent broke this rule despite it being in the file — needs strengthening or hook |
| **Untriggered** | Rule was never relevant across all sampled sessions — candidate for staleness review |
| **Undocumented pattern** | Agent needed correction but no rule exists — candidate for addition |

### 2c.4 Scope Findings

Tag each finding as:
- **LOCAL** — project-specific, belongs in the project's instruction file
- **GLOBAL** — applies everywhere, belongs in `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` (or equivalent global config)

### 2c.5 Output

Feed findings into Phase 2a (static audit) as additional context — usage evidence strengthens or weakens each check's findings. Then proceed to Phase 3.

## Phase 3: Quality Gate

Both modes converge here. Run these checks against audit findings or the draft.

### 3.1 Anti-Pattern Check

Load `references/anti-patterns.md` and verify none of the 11 anti-patterns are present. Pay special attention to:
- LLM-generated content (descriptions masquerading as instructions)
- Rules the model already follows (pure token waste)
- Architecture descriptions (agent can read the code)

### 3.2 Bloat Ratio Check

Classify each line as:
- **Directive**: commands, constraints, boundaries (things the agent should DO)
- **Descriptive**: context, explanations, architecture (things the agent should KNOW)

If descriptive lines outnumber directive lines, flag it. Instruction files should be mostly instructions, not documentation. Context is valuable only when it directly supports a directive.

### 3.3 Cross-Reference Check

If the file uses @imports or references other files, verify those files exist:
```bash
# Match line-starting @imports that reference file paths (contain a file extension)
rg -o '^@\S+\.\w+' <file> | while read -r ref; do
  path="${ref#@}"
  [ -e "$path" ] || echo "Missing reference: $path"
done
```
This matches `@.claude/rules/api.md` and `@AGENTS.md` but not `@app/api` (no extension) or inline `@team-name` mentions.

## Phase 4: Output

### Simplify Output Template

For simplify mode (checks 1-2 + bloat ratio only):

```markdown
# Simplify: <filename>

## Summary
<1-2 sentences: current state and reduction potential>

| Metric | Value |
|---|---|
| Lines | <count> |
| Bloat ratio | <directive:descriptive> |

## Lines to Remove
<numbered list with reason for each>

## Recommended Actions
1. ...
```

### Full Audit Output Template

For full audit mode (all 7 checks):

```markdown
# Instruction File Audit: <filename>

## Summary
<1-2 sentences: overall assessment>

## Dimension Scores

| Dimension | Score | Notes |
|---|---|---|
| Non-inferable content | STRONG/NEEDS WORK/WEAK | |
| Size | STRONG/NEEDS WORK/WEAK | <line count> |
| Emphasis discipline | STRONG/NEEDS WORK/WEAK | <marker count> |
| Structure | STRONG/NEEDS WORK/WEAK | |
| Boundary format | STRONG/NEEDS WORK/WEAK | |
| Hook opportunities | STRONG/NEEDS WORK/WEAK | |
| Cross-platform | STRONG/NEEDS WORK/WEAK | |

**Overall: STRONG / NEEDS WORK / WEAK**

## Lines to Remove
<numbered list with reason for each>

## Lines to Add
<numbered list with rationale — tag each as LOCAL (project file) or GLOBAL (user-wide config)>

## Potentially Outdated
<rules that were never triggered across sampled sessions, or that the agent consistently followed without needing the rule — candidates for removal. Only populated when Phase 2c was run.>

## Hook Candidates
<rules that should become hooks>

## Anti-Patterns Detected
<from the 11-pattern checklist>

## Recommended Actions (Priority Order)
1. ...
2. ...
```

### Write Output Template

```markdown
# Draft: <filename>

<the drafted instruction file>

---

## Decisions Made
- File strategy: <chosen pattern and why>
- Sections included/omitted: <rationale>
- Lines excluded by litmus test: <count>

## Post-Creation Checklist
- [ ] Verify all referenced files/paths exist
- [ ] Run any mentioned commands to confirm they work
- [ ] If AGENTS.md + CLAUDE.md, verify relationship is clean
- [ ] If using @imports, verify Claude Code resolves them
- [ ] Review emphasis markers — are they all protecting against real failures?
- [ ] Schedule first maintenance review (suggest: 30 days or next major refactor)
```

## Writing Style Guidance

When drafting instruction file content:
- **Directive for behavior**: "Run `npm test` before committing" (imperative, verifiable)
- **Descriptive for context**: "The legacy-auth module is deprecated but still in production" (factual, brief)
- **Positive over negative**: "Use X for Y" beats "Never use Z" — positive instructions have higher compliance
- **Specific and verifiable**: "Use 2-space indentation" not "Format code properly"
- **Concise**: "Like onboarding a new hire — define terms, name inputs, remove ambiguity" (Anthropic)
- **Structured**: Use markdown headers, bullets, and tables — structure helps agents parse and follow

## Anti-Hallucination Rules

These checks must be performed mechanically, not estimated:
- **Actually count lines** with `wc -l` — don't estimate "about 150 lines"
- **Actually grep** for emphasis markers — don't eyeball "a few IMPORTANTs"
- **Actually read** codebase files before classifying instruction lines as inferable
- **Actually check** that referenced files exist — don't assume
- **Actually diff** AGENTS.md vs CLAUDE.md if both exist — don't assume they match

**Anti-bloat rule:** When writing or fixing instruction files, resist the urge to add "helpful context." If a proposed addition doesn't pass the litmus test, do not include it regardless of how useful it seems. The research is clear: more content = worse compliance across all rules.

## Grading Rubric

### Per Dimension

| Grade | Meaning |
|---|---|
| **STRONG** | No issues found; follows best practices |
| **NEEDS WORK** | Minor issues; file works but could be improved |
| **WEAK** | Significant issues; file likely hurts more than it helps |

### Overall Grade

| Overall | Criteria |
|---|---|
| **STRONG** | No dimensions rated WEAK |
| **NEEDS WORK** | 1-3 dimensions rated WEAK |
| **WEAK** | 4+ dimensions rated WEAK, OR any critical anti-pattern (LLM-generated content, >300 lines, emphasis on >10% of rules) |

## Related Skills

- `introspect` — Audits the whole agent config surface (settings, hooks, skills, instruction files). Use when you need a broad config health check, not just instruction file quality.
- `writing-skills` — For writing skill files (SKILL.md), not instruction files. Different format, different purpose.
- `prompt-engineer` — For LLM prompt design. Instruction files are a specialized form of prompting, but prompt-engineer covers the general case.
