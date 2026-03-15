#!/bin/bash
set -euo pipefail

# Zsh config installer
# Symlinks .zshrc from dotfiles repo to ~/.zshrc

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

echo "Installing Zsh config..."

symlink_with_backup "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
symlink_with_backup "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
symlink_with_backup "$DOTFILES_DIR/zsh/omz-custom/aliases.zsh" "$HOME/.oh-my-zsh/custom/aliases.zsh"

echo "Zsh config installed."
