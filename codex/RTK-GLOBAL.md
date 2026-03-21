# RTK (Always-Loaded Hints)

Bash commands may be silently rewritten to `rtk <cmd>` by a Claude Code hook for token savings. This is transparent for most usage.

## When to bypass RTK

Use `rtk proxy <cmd>` only when you need **exact, parseable output** — typically for final validation or skills that parse structured output:

- **Final lint/clippy check before commit** — need exact warnings, file:line locations, counts
- **Skills parsing structured output** — unified diffs, `--porcelain`, `--name-only`
- **`git diff` for patch/review** — raw unified diff format required

**Do NOT bypass RTK for iterative development.** During active coding, let RTK compress lint/build output — the summary is sufficient for "did I break something?" checks. Only bypass at the validation gate.

## Compound commands

- `cmd1 && cmd2` are rewritten per-subcommand — `rtk proxy` only protects the subcommand it wraps
- When chaining, wrap each subcommand that needs raw output: `rtk proxy cargo clippy 2>/tmp/out.txt && rtk proxy grep "^warning" /tmp/out.txt`

Full reference: `RTK.md` (load on demand via `@` or `Read`, not auto-imported)
