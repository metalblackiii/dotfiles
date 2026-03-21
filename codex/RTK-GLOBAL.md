# RTK (Always-Loaded Hints)

Bash commands may be silently rewritten to `rtk <cmd>` by a Claude Code hook for token savings. This is transparent for most usage.

When you need **raw, unmodified CLI output** (clippy/lint warnings with file:line locations, `git diff --porcelain`, unified diffs):

- Use `rtk proxy <cmd>` to bypass filtering
- Compound commands (`cmd1 && cmd2`, `cmd1 ; cmd2`) are rewritten per-subcommand — `rtk proxy` only protects the subcommand it wraps, not later ones in the chain
- When chaining, wrap each subcommand that needs raw output: `rtk proxy cargo clippy 2>/tmp/out.txt && rtk proxy grep "^warning" /tmp/out.txt`

Full reference: `RTK.md` (load on demand via `@` or `Read`, not auto-imported)
