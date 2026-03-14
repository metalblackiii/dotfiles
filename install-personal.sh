#!/bin/bash
set -euo pipefail

# Personal config installer — shell, editor, etc.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing personal config from $DOTFILES_DIR"
echo ""

for module in zsh git_personal; do
    installer="$DOTFILES_DIR/$module/install.sh"
    if [ -x "$installer" ]; then
        bash "$installer"
        echo ""
    fi
done

echo "Personal config installed."
