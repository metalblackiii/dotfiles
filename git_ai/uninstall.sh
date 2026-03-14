#!/bin/bash
set -euo pipefail

# Git AI config uninstaller
# Removes gitignore symlink and unsets core.excludesFile

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

GITIGNORE_TARGET="$HOME/.gitignore_global"

echo "Uninstalling Git AI config..."

remove_symlink "$GITIGNORE_TARGET"

if [ "$(git config --global core.excludesFile 2>/dev/null)" = "$GITIGNORE_TARGET" ]; then
    echo "  Unsetting core.excludesFile"
    git config --global --unset core.excludesFile
fi

echo "Git AI config uninstalled."
