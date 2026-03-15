#!/bin/bash
set -euo pipefail

# VS Code config uninstaller
# Removes symlink created by install.sh (leaves backups untouched)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

# macOS: ~/Library/Application Support/Code/User/
# Linux: ~/.config/Code/User/
if [ "$(uname)" = "Darwin" ]; then
    VSCODE_TARGET="$HOME/Library/Application Support/Code/User"
else
    VSCODE_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User"
fi

echo "Uninstalling VS Code config..."

remove_symlink "$VSCODE_TARGET/settings.json"

echo "VS Code config uninstalled."
