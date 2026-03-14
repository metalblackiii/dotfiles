#!/bin/bash
set -euo pipefail

# Git AI config installer
# Symlinks global gitignore (controls what AI agents see in repos)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

GITIGNORE_SOURCE="$DOTFILES_DIR/git_ai/.gitignore_global"
GITIGNORE_TARGET="$HOME/.gitignore_global"

echo "Installing Git AI config..."

symlink_with_backup "$GITIGNORE_SOURCE" "$GITIGNORE_TARGET"
git config --global core.excludesFile "$GITIGNORE_TARGET"

echo "Git AI config installed."
