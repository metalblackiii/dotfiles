# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook (`rtk-rewrite.sh`).
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

Refer to CLAUDE.md for full command reference.

## Bypassing the Rewrite Hook

Skills that parse raw git output (unified diffs, `--name-only`, `--porcelain`) need unmodified output — rtk's compact format will break them.

**Bypass pattern:** Use `rtk proxy` to execute the command without filtering. The rewrite hook passes `rtk proxy ...` through unchanged (input equals output, so the hook is a no-op).

```bash
# Rewritten to rtk (compact output):
git diff --staged

# Bypasses rtk (raw unified diff):
rtk proxy git diff --staged --no-color -U3
```

Note: env-var prefixes (`GIT_PAGER=cat git diff ...`) do NOT bypass the rewrite — rtk preserves the prefix and still rewrites `git` to `rtk git`.
