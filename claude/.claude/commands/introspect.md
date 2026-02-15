---
description: Review Claude configuration for conflicts, redundancy, and staleness
allowed-tools: Read, Glob, Grep
---

Perform a configuration introspection.

## What to Analyze

1. **Read current configuration files:**
   - `~/.claude/settings.json` (global settings)
   - `.claude/settings.json` (project settings if present)
   - All files in `~/.claude/skills/` and `.claude/skills/`
   - All files in `~/.claude/commands/` and `.claude/commands/`
   - `CLAUDE.md` and `AGENTS.md`

2. **Check for:**
   - **Conflicts:** Instructions that contradict each other
   - **Redundancy:** Multiple skills/commands doing the same thing
   - **Staleness:** Instructions that may be obsolete given current Claude capabilities
   - **Overly broad instructions:** Rules that might cause unintended side effects
   - **Missing coverage:** Common workflows without automation

   **Known-intentional patterns (do NOT flag these):**
   - Empty `attribution` fields in settings.json — these intentionally suppress Claude's default attribution behavior

3. **Prompt Quality Audit** (invoke the `prompt-engineer` skill for this section):

   For each skill, evaluate the **description** field against these criteria:
   - **Trigger-only?** Does it say WHEN to use, not HOW it works? Descriptions containing process steps cause agents to follow the brief summary instead of reading the full skill.
   - **Specific enough?** Would a model reliably match this description to the right user request? Vague descriptions like "Use for development" won't trigger correctly.
   - **Overlap detection:** Do any two descriptions match the same user request? If so, which one wins and is the precedence clear?
   - **Completeness:** Are there common triggering scenarios the description misses? (e.g., a SQL skill that doesn't mention "migration" won't trigger during migration work)

   Rate each skill description: STRONG / NEEDS WORK / WEAK, with a one-line explanation.

4. **Output format:**

   ### 🔴 Conflicts Found
   (contradictory instructions that need resolution)

   ### 🟡 Redundancies
   (duplicated or overlapping functionality)

   ### 🟠 Potentially Stale
   (may no longer be needed)

   ### 🎯 Prompt Quality Audit
   (per-skill description effectiveness rating with improvement suggestions)

   ### 🟢 Configuration Health
   (what's working well)

   ### 💡 Suggestions
   (improvements or gaps to consider)

$ARGUMENTS