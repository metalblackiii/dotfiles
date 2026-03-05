#!/bin/bash
set -euo pipefail

# Git config uninstaller
# Removes symlink and unsets core.excludesFile

GIT_TARGET="$HOME/.gitignore_global"

echo "Uninstalling Git config..."

if [ -L "$GIT_TARGET" ]; then
    echo "  Removing symlink $GIT_TARGET"
    rm "$GIT_TARGET"
fi

if [ "$(git config --global core.excludesFile 2>/dev/null)" = "$GIT_TARGET" ]; then
    echo "  Unsetting core.excludesFile"
    git config --global --unset core.excludesFile
fi

echo "Git config uninstalled."
