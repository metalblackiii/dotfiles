#!/bin/bash
set -euo pipefail

# Codex uninstaller
# Removes symlinks created by install.sh (leaves backups untouched)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

CODEX_TARGET="$HOME/.codex"

echo "Uninstalling Codex config..."

CODEX_ITEMS=(
    "config.toml"
    "AGENTS.md"
)

for item in "${CODEX_ITEMS[@]}"; do
    remove_symlink "$CODEX_TARGET/$item"
done

remove_symlink "$HOME/.agents/skills/personal"

echo "Codex config uninstalled."
