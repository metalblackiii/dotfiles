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
| This file | `~/repos/dotfiles/claude/.claude/CLAUDE.md` |

**Never edit via `~/.claude/` paths** - those are symlinks.
