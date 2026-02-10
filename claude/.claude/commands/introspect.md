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
   - `CLAUDE.md` and `.claude/rules/` if present

2. **Check for:**
   - **Conflicts:** Instructions that contradict each other
   - **Redundancy:** Multiple skills/commands doing the same thing
   - **Staleness:** Instructions that may be obsolete given current Claude capabilities
   - **Overly broad instructions:** Rules that might cause unintended side effects
   - **Missing coverage:** Common workflows without automation

3. **Output format:**
   
   ### 🔴 Conflicts Found
   (contradictory instructions that need resolution)
   
   ### 🟡 Redundancies
   (duplicated or overlapping functionality)
   
   ### 🟠 Potentially Stale
   (may no longer be needed)
   
   ### 🟢 Configuration Health
   (what's working well)
   
   ### 💡 Suggestions
   (improvements or gaps to consider)

$ARGUMENTS