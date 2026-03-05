#!/bin/bash
set -euo pipefail

# Git config installer
# Symlinks global gitignore and sets core.excludesFile

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_SOURCE="$DOTFILES_DIR/git/.gitignore_global"
GIT_TARGET="$HOME/.gitignore_global"

echo "Installing Git config..."

if [ -e "$GIT_TARGET" ] && [ ! -L "$GIT_TARGET" ]; then
    backup_path="${GIT_TARGET}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up $GIT_TARGET to $backup_path"
    mv "$GIT_TARGET" "$backup_path"
elif [ -L "$GIT_TARGET" ]; then
    rm "$GIT_TARGET"
fi

echo "  Linking $GIT_TARGET -> $GIT_SOURCE"
ln -s "$GIT_SOURCE" "$GIT_TARGET"

git config --global core.excludesFile "$GIT_TARGET"

echo "Git config installed."
