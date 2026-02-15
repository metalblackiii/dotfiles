#!/bin/bash
set -euo pipefail

# Dotfiles uninstaller — runs all platform uninstallers
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Uninstalling dotfiles from $DOTFILES_DIR"
echo ""

for uninstaller in "$DOTFILES_DIR"/*/uninstall.sh; do
    bash "$uninstaller"
    echo ""
done

echo "Done! Any .backup.TIMESTAMP files were left untouched."
