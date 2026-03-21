#!/bin/bash
set -euo pipefail

# Yazi settings uninstaller
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

YAZI_TARGET="$HOME/.config/yazi"

echo "Uninstalling Yazi config..."

remove_symlink "$YAZI_TARGET/yazi.toml"

echo "Yazi config uninstalled."
