#!/bin/bash
set -euo pipefail

# RTK config installer
# Symlinks config.toml to the platform config directory

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTK_SOURCE="$DOTFILES_DIR/rtk/config.toml"

# macOS: ~/Library/Application Support/rtk/
# Linux: ~/.config/rtk/
if [ "$(uname)" = "Darwin" ]; then
    RTK_TARGET_DIR="$HOME/Library/Application Support/rtk"
else
    RTK_TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rtk"
fi

RTK_TARGET="$RTK_TARGET_DIR/config.toml"

echo "Installing RTK config..."

mkdir -p "$RTK_TARGET_DIR"

if [ -e "$RTK_TARGET" ] && [ ! -L "$RTK_TARGET" ]; then
    backup_path="${RTK_TARGET}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up $RTK_TARGET to $backup_path"
    mv "$RTK_TARGET" "$backup_path"
elif [ -L "$RTK_TARGET" ]; then
    rm "$RTK_TARGET"
fi

echo "  Linking $RTK_TARGET -> $RTK_SOURCE"
ln -s "$RTK_SOURCE" "$RTK_TARGET"

echo "RTK config installed."
