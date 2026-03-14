#!/bin/bash
set -euo pipefail

# RTK config installer
# Symlinks config.toml to the platform config directory

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

RTK_SOURCE="$DOTFILES_DIR/rtk/config.toml"

# macOS: ~/Library/Application Support/rtk/
# Linux: ~/.config/rtk/
if [ "$(uname)" = "Darwin" ]; then
    RTK_TARGET_DIR="$HOME/Library/Application Support/rtk"
else
    RTK_TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rtk"
fi

echo "Installing RTK config..."

mkdir -p "$RTK_TARGET_DIR"
symlink_with_backup "$RTK_SOURCE" "$RTK_TARGET_DIR/config.toml"

echo "RTK config installed."
