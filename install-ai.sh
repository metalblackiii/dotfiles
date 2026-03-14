#!/bin/bash
set -euo pipefail

# AI tools installer — Claude Code, Codex, global gitignore
# RTK is installed via claude/install.sh (dependency of rtk-rewrite hook)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing AI tool config from $DOTFILES_DIR"
echo ""

for module in claude codex git; do
    installer="$DOTFILES_DIR/$module/install.sh"
    if [ -x "$installer" ]; then
        bash "$installer"
        echo ""
    fi
done

echo "AI tool config installed."
