# RTK (Always-Loaded Hints)

Bash commands may be silently rewritten to `rtk <cmd>` by a Claude Code hook for token savings. This is transparent for most usage.

## RTK proxy is a retry tool, not a first choice

**NEVER use `rtk proxy` proactively.** Always run the normal command first and let RTK compress the output. The compressed output is sufficient for the vast majority of tasks.

Use `rtk proxy <cmd>` **only as a retry** when:
- RTK output is garbled, truncated, or missing information you need to proceed
- You cannot parse the compressed output for a specific value (file path, line number, error code)

If the normal command's output works — even if it's compressed — do not retry with `rtk proxy`. The whole point of RTK is token savings; bypassing it defeats the purpose.

## Compound commands

- `cmd1 && cmd2` are rewritten per-subcommand — `rtk proxy` only protects the subcommand it wraps

Full reference: `RTK.md` (load on demand via `@` or `Read`, not auto-imported)
