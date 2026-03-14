#!/bin/bash
set -euo pipefail

# Zsh config uninstaller
# Removes symlink created by install.sh (leaves backups untouched)

ZSH_TARGET="$HOME/.zshrc"

echo "Uninstalling Zsh config..."

if [ -L "$ZSH_TARGET" ]; then
    echo "  Removing symlink $ZSH_TARGET"
    rm "$ZSH_TARGET"
elif [ -e "$ZSH_TARGET" ]; then
    echo "  $ZSH_TARGET is not a symlink, skipping (remove manually if desired)"
fi

echo "Zsh config uninstalled."
