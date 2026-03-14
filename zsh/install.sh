#!/bin/bash
set -euo pipefail

# Zsh config installer
# Symlinks .zshrc from dotfiles repo to ~/.zshrc

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_SOURCE="$DOTFILES_DIR/zsh/.zshrc"
ZSH_TARGET="$HOME/.zshrc"

echo "Installing Zsh config..."

if [ -e "$ZSH_TARGET" ] && [ ! -L "$ZSH_TARGET" ]; then
    backup_path="${ZSH_TARGET}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up $ZSH_TARGET to $backup_path"
    mv "$ZSH_TARGET" "$backup_path"
elif [ -L "$ZSH_TARGET" ]; then
    rm "$ZSH_TARGET"
fi

echo "  Linking $ZSH_TARGET -> $ZSH_SOURCE"
ln -s "$ZSH_SOURCE" "$ZSH_TARGET"

echo "Zsh config installed."
