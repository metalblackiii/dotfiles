#!/bin/bash
set -euo pipefail

# Git AI config uninstaller
# Removes gitignore symlink and unsets core.excludesFile

GITIGNORE_TARGET="$HOME/.gitignore_global"

echo "Uninstalling Git AI config..."

if [ -L "$GITIGNORE_TARGET" ]; then
    echo "  Removing symlink $GITIGNORE_TARGET"
    rm "$GITIGNORE_TARGET"
fi

if [ "$(git config --global core.excludesFile 2>/dev/null)" = "$GITIGNORE_TARGET" ]; then
    echo "  Unsetting core.excludesFile"
    git config --global --unset core.excludesFile
fi

echo "Git AI config uninstalled."
