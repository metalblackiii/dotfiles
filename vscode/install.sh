#!/bin/bash
set -euo pipefail

# VS Code settings installer — symlinks settings.json into VS Code's config dir
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

VSCODE_SOURCE="$DOTFILES_DIR/vscode"

# macOS: ~/Library/Application Support/Code/User/
# Linux: ~/.config/Code/User/
if [ "$(uname)" = "Darwin" ]; then
    VSCODE_TARGET="$HOME/Library/Application Support/Code/User"
else
    VSCODE_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User"
fi

echo "Installing VS Code config..."

mkdir -p "$VSCODE_TARGET"

symlink_with_backup "$VSCODE_SOURCE/settings.json" "$VSCODE_TARGET/settings.json"

echo "VS Code config installed."
