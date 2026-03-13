#!/bin/bash
set -euo pipefail

# RTK config uninstaller
# Removes symlink created by install.sh (leaves backups untouched)

if [ "$(uname)" = "Darwin" ]; then
    RTK_TARGET_DIR="$HOME/Library/Application Support/rtk"
else
    RTK_TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rtk"
fi

RTK_TARGET="$RTK_TARGET_DIR/config.toml"

echo "Uninstalling RTK config..."

if [ -L "$RTK_TARGET" ]; then
    echo "  Removing symlink $RTK_TARGET"
    rm "$RTK_TARGET"
elif [ -e "$RTK_TARGET" ]; then
    echo "  $RTK_TARGET is not a symlink, skipping (remove manually if desired)"
fi

echo "RTK config uninstalled."
