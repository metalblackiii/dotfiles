#!/bin/bash
set -euo pipefail

# RTK config uninstaller
# Removes symlink created by install.sh (leaves backups untouched)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

if [ "$(uname)" = "Darwin" ]; then
    RTK_TARGET_DIR="$HOME/Library/Application Support/rtk"
else
    RTK_TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rtk"
fi

echo "Uninstalling RTK config..."

remove_symlink "$RTK_TARGET_DIR/config.toml"

echo "RTK config uninstalled."
