#!/bin/bash
set -euo pipefail

# Codex installer
# Symlinks config to ~/.codex/ and shares skills via ~/.agents/skills/

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

CODEX_TARGET="$HOME/.codex"

echo "Installing Codex config..."

mkdir -p "$CODEX_TARGET"

symlink_with_backup "$DOTFILES_DIR/codex/.codex/config.toml" "$CODEX_TARGET/config.toml"
symlink_with_backup "$DOTFILES_DIR/codex/AGENTS.md" "$CODEX_TARGET/AGENTS.md"

# Share skills with Codex via native skill discovery
SKILLS_SOURCE="$DOTFILES_DIR/codex/.agents/skills"
SKILLS_LINK="$HOME/.agents/skills/personal"
mkdir -p "$(dirname "$SKILLS_LINK")"
symlink_with_backup "$SKILLS_SOURCE" "$SKILLS_LINK"

echo "Codex config installed."
