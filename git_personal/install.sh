#!/bin/bash
set -euo pipefail

# Git personal config installer
# Adds [include] for shared config (delta, merge style) to ~/.gitconfig

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_CONFIG="$DOTFILES_DIR/git_personal/.gitconfig.shared"

echo "Installing Git personal config..."

if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$SHARED_CONFIG"; then
    echo "  Adding [include] path = $SHARED_CONFIG to ~/.gitconfig"
    git config --global --add include.path "$SHARED_CONFIG"
else
    echo "  [include] path already set in ~/.gitconfig"
fi

echo "Git personal config installed."
