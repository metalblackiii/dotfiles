#!/bin/bash
set -euo pipefail

# Zsh config uninstaller
# Removes symlink created by install.sh (leaves backups untouched)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

echo "Uninstalling Zsh config..."

remove_symlink "$HOME/.zshrc"

echo "Zsh config uninstalled."
