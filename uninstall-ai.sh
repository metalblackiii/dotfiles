#!/bin/bash
set -euo pipefail

# AI tools uninstaller — Claude Code, Codex, RTK, global gitignore
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Uninstalling AI tool config from $DOTFILES_DIR"
echo ""

for module in claude codex rtk git_ai; do
    uninstaller="$DOTFILES_DIR/$module/uninstall.sh"
    if [ -x "$uninstaller" ]; then
        bash "$uninstaller"
        echo ""
    fi
done

echo "AI tool config uninstalled."
