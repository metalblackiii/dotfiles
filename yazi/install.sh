#!/bin/bash
set -euo pipefail

# Yazi settings installer — symlinks config into yazi's config dir
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

YAZI_SOURCE="$DOTFILES_DIR/yazi"
YAZI_TARGET="$HOME/.config/yazi"

echo "Installing yazi config..."

mkdir -p "$YAZI_TARGET"

symlink_with_backup "$YAZI_SOURCE/yazi.toml" "$YAZI_TARGET/yazi.toml"

echo "Yazi config installed."
