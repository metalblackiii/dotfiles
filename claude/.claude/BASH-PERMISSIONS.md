## Bash Permissions

All Bash deny/ask rules live in `~/.claude/hooks/bash-permissions.json` (single source of truth). Do not add Bash rules to settings.json deny/ask arrays — the bash-permissions hook is the sole enforcer.

To add a rule, add an entry to the appropriate layer in `bash-permissions.json`:
- **deny**: blocked unconditionally, reason shown to Claude
- **paths**: blocks commands referencing sensitive file patterns
- **allow**: auto-accepts commands matching trusted patterns (bypasses ask)
- **ask**: forces user confirmation prompt

Rule formats:
- `"commands": ["git stash drop"]` — human-readable, auto-converted to regex
- `"regex": "\\bsome\\s+pattern"` — escape hatch for complex patterns
- `"nudge": "Use X instead."` — optional, shown to Claude on deny (guides toward the right tool)
- `"branch": "^mjb-pho-"` — optional (allow layer only), rule only fires when current git branch matches (lazy lookup, resolves cd targets)

After any change to `bash-permissions.json` or `bash-permissions.sh`, run the regression suite:
```
bash ~/.claude/hooks/bash-permissions-test.sh
```
151+ test cases cover deny, paths, and allow layers. Add test cases to `bash-permissions-test-cases.txt` for any new or modified rule before committing.
