# Dotfiles Repo — Project Rules

These rules apply only when working inside this repository.

## Canonical Editing

This configuration is managed via a dotfiles repo with symlinks.

**IMPORTANT: Always edit files in the dotfiles repo** — never edit via symlinked paths (`~/.claude/`, `~/.codex/`, `~/.agents/`). Those are deployment targets. The canonical location for skills is `codex/.agents/skills/` within this repo. Both Claude Code (`~/.claude/skills/`) and Codex (`~/.agents/skills/`) symlink to it — all skills are shared across platforms. To find the repo root, use `git rev-parse --show-toplevel` from any file inside it, or follow a symlink (e.g., `readlink ~/.claude/skills`) back to the source.

## Brewfile

CLI tools and GUI apps are managed via `Brewfile` at the repo root. When adding or removing tools, update the Brewfile — don't just `brew install` ad hoc.

@claude/.claude/BASH-PERMISSIONS.md

## RTK (Rust Token Killer)

@claude/.claude/RTK.md
