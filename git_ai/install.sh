#!/bin/bash
set -euo pipefail

# Git AI config installer
# Symlinks global gitignore (controls what AI agents see in repos)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITIGNORE_SOURCE="$DOTFILES_DIR/git_ai/.gitignore_global"
GITIGNORE_TARGET="$HOME/.gitignore_global"

echo "Installing Git AI config..."

if [ -e "$GITIGNORE_TARGET" ] && [ ! -L "$GITIGNORE_TARGET" ]; then
    backup_path="${GITIGNORE_TARGET}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up $GITIGNORE_TARGET to $backup_path"
    mv "$GITIGNORE_TARGET" "$backup_path"
elif [ -L "$GITIGNORE_TARGET" ]; then
    rm "$GITIGNORE_TARGET"
fi

echo "  Linking $GITIGNORE_TARGET -> $GITIGNORE_SOURCE"
ln -s "$GITIGNORE_SOURCE" "$GITIGNORE_TARGET"

git config --global core.excludesFile "$GITIGNORE_TARGET"

echo "Git AI config installed."
