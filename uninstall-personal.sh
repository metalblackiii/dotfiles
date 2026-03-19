#!/bin/bash
set -euo pipefail

# Personal config uninstaller — shell, editor, etc.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Uninstalling personal config from $DOTFILES_DIR"
echo ""

for module in zsh git_personal vscode ghostty; do
    uninstaller="$DOTFILES_DIR/$module/uninstall.sh"
    if [ -x "$uninstaller" ]; then
        bash "$uninstaller"
        echo ""
    fi
done

echo "Personal config uninstalled."
