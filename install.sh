#!/bin/bash
set -euo pipefail

# Dotfiles installer — runs all platform installers
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"
echo ""

for installer in "$DOTFILES_DIR"/*/install.sh; do
    bash "$installer"
    echo ""
done

echo "Done! Backups of original files (if any) have .backup.TIMESTAMP extension"
