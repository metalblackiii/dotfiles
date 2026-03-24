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

### Path-conditional deny (exempt_when_path)

Deny rules can be softened for commands scoped to a trusted directory. This is useful for operations that are dangerous system-wide but safe inside git-backed repos.

```json
{
  "commands": ["rm -rf", "rm -r", "rm"],
  "category": "destructive filesystem (rm)",
  "exempt_when_path": "~/repos/",
  "exempt_decision": "ask"
}
```

When a deny rule matches and has `exempt_when_path`, the hook checks:
1. **No unsafe absolute paths** — every absolute path (`/...`) in the command must be under the safe directory. If any path is outside, the deny stands.
2. **Safe reference** — the command explicitly references the safe directory (e.g., `~/repos/foo/dist`), OR
3. **Safe cwd** — the effective working directory (actual cwd or `cd` target in compound commands) is under the safe directory.

If exempt, the deny rule is **skipped** and processing continues to the allow and ask layers. This means allow-listed patterns (e.g., skill cleanup dirs) auto-accept instead of prompting, while non-allow-listed commands still reach the ask layer and prompt as usual.

Decision matrix:

| Scenario | Result |
|---|---|
| `rm -rf dist` (cwd in ~/repos/foo) | **ask** |
| `rm -rf ~/repos/foo/dist` (any cwd) | **ask** |
| `cd ~/repos/foo && rm -rf dist` (any cwd) | **ask** |
| `rm -rf /tmp/something` (any cwd) | **deny** |
| `rm file.txt` (cwd outside ~/repos/) | **deny** |
| `rm -rf ~/repos/foo /etc/bad` (mixed paths) | **deny** |
| `rm -rf ../../Documents` (cwd in ~/repos/foo) | **deny** |
| `rm -rf "/tmp/something"` (quoted unsafe path) | **deny** |

Conservative by design — false denies are acceptable, false allows are not. Shell quotes are stripped and `..` traversal segments are rejected before any exemption check.

### Customization

If you fork this repo, update these environment-specific values:

| Value | Location | Purpose |
|---|---|---|
| `"exempt_when_path": "~/repos/"` | `bash-permissions.json` (deny layer) | Root directory where your git repos live. `~` expands to `$HOME` at runtime. Change to e.g. `~/Documents/Repos/` or `~/src/` to match your layout. |
| `"branch": "^mjb-pho-NEB-"` | `bash-permissions.json` (allow layer) | Branch naming convention for auto-accepting git push/commit/PR. Change to match your team's branch prefix. |

After any change to `bash-permissions.json` or `bash-permissions.sh`, run the regression suite:
```
bash ~/.claude/hooks/bash-permissions-test.sh
```
173+ test cases cover deny, paths, allow, and path-exemption layers. Add test cases to `bash-permissions-test-cases.txt` for any new or modified rule before committing.
