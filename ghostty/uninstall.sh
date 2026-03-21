#!/bin/bash
set -euo pipefail

# Ghostty settings uninstaller
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Ghostty uninstaller is macOS-only. Skipping."
    exit 0
fi

GHOSTTY_TARGET="$HOME/Library/Application Support/com.mitchellh.ghostty"

echo "Uninstalling Ghostty config..."

remove_symlink "$GHOSTTY_TARGET/config.ghostty"

echo "Ghostty config uninstalled."
