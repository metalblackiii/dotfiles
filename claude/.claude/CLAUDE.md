# Claude Code Configuration

Read and follow AGENTS.md for shared conventions (git, PRs, code quality, security, skills).

## Tool Preferences

- **Always use built-in tools over Bash equivalents** — `Read` not `cat`/`head`/`tail`, `Glob` not `find`/`ls`, `Grep` not `grep`/`rg`. These are denied in settings.json to enforce this. Never attempt to work around the deny rules.
