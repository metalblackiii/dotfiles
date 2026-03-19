#!/bin/bash
set -euo pipefail

# Ghostty settings installer — symlinks config into Ghostty's config dir
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

GHOSTTY_SOURCE="$DOTFILES_DIR/ghostty"
GHOSTTY_TARGET="$HOME/Library/Application Support/com.mitchellh.ghostty"

echo "Installing Ghostty config..."

mkdir -p "$GHOSTTY_TARGET"

symlink_with_backup "$GHOSTTY_SOURCE/config.ghostty" "$GHOSTTY_TARGET/config.ghostty"

echo "Ghostty config installed."
