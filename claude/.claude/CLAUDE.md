# Personal Claude Configuration

This configuration is managed via dotfiles repo with symlinks.

## Dotfiles Location

Config files live in `~/repos/dotfiles/` and are symlinked to `~/.claude/`.

**When editing Claude config, always use the dotfiles path:**

| What | Edit Here |
|------|-----------|
| Permissions, hooks | `~/repos/dotfiles/claude/.claude/settings.json` |
| Skills | `~/repos/dotfiles/claude/.claude/skills/<name>/SKILL.md` |
| Commands | `~/repos/dotfiles/claude/.claude/commands/<name>.md` |
| Agents | `~/repos/dotfiles/claude/.claude/agents/<name>.md` |
| Scripts | `~/repos/dotfiles/claude/.claude/scripts/<name>.sh` |
| This file | `~/repos/dotfiles/claude/.claude/CLAUDE.md` |

**Never edit via `~/.claude/` paths** - those are symlinks.

## Tool Preferences

- **Always use built-in tools over Bash equivalents** — `Read` not `cat`/`head`/`tail`, `Glob` not `find`/`ls`, `Grep` not `grep`/`rg`. These are denied in settings.json to enforce this. Never attempt to work around the deny rules.

## Git Preferences

- Use **conventional commit** style unless the project specifies otherwise
- Only commit or push when I explicitly ask — every commit and push requires my approval (enforced via `ask` rules in settings.json)
- Never auto-commit follow-up changes after an initial commit — always prompt again

## PR Defaults

- Default reviewers: `Chiropractic-CT-Cloud/phoenix`
- Use `-r org/team-slug` with `gh pr create` (not `--team`)
