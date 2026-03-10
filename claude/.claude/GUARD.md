## Bash Permissions

All Bash deny/ask rules live in `~/.claude/hooks/guard-rules.json` (single source of truth). Do not add Bash rules to settings.json deny/ask arrays — the guard hook is the sole enforcer.

To add a rule, add an entry to the appropriate layer in `guard-rules.json`:
- **deny**: blocked unconditionally, reason shown to Claude
- **paths**: blocks commands referencing sensitive file patterns
- **allow**: auto-accepts commands matching trusted patterns (bypasses ask)
- **ask**: forces user confirmation prompt

Rule formats:
- `"commands": ["git stash drop"]` — human-readable, auto-converted to regex
- `"regex": "\\bsome\\s+pattern"` — escape hatch for complex patterns
- `"nudge": "Use X instead."` — optional, shown to Claude on deny (guides toward the right tool)
