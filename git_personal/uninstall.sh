#!/bin/bash
set -euo pipefail

# Git personal config uninstaller
# Removes shared config include from ~/.gitconfig

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_CONFIG="$DOTFILES_DIR/git_personal/.gitconfig.shared"

echo "Uninstalling Git personal config..."

if git config --global --get-all include.path 2>/dev/null | grep -qF "$SHARED_CONFIG"; then
    echo "  Removing [include] path from ~/.gitconfig"
    git config --global --unset-all include.path "$SHARED_CONFIG"
fi

echo "Git personal config uninstalled."
