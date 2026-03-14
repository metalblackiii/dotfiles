#!/bin/bash
set -euo pipefail

# Zsh config installer
# Symlinks .zshrc from dotfiles repo to ~/.zshrc

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

echo "Installing Zsh config..."

symlink_with_backup "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

echo "Zsh config installed."
