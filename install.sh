#!/bin/bash
set -euo pipefail

# Dotfiles installer
# Creates symlinks from config locations to this repo

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# ============================================================================
# Claude Code
# ============================================================================
# We symlink individual files/dirs, not the whole ~/.claude directory,
# because ~/.claude contains ephemeral data (projects/, cache/, etc.)

CLAUDE_SOURCE="$DOTFILES_DIR/claude/.claude"
CLAUDE_TARGET="$HOME/.claude"

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_TARGET"

# Files/directories to symlink
CLAUDE_ITEMS=(
    "settings.json"
    "hooks"
    "skills"
    "commands"
)

for item in "${CLAUDE_ITEMS[@]}"; do
    source_path="$CLAUDE_SOURCE/$item"
    target_path="$CLAUDE_TARGET/$item"

    if [ -e "$source_path" ]; then
        # Backup existing (non-symlink) files
        if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
            backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
            echo "  Backing up $target_path to $backup_path"
            mv "$target_path" "$backup_path"
        elif [ -L "$target_path" ]; then
            # Remove existing symlink
            rm "$target_path"
        fi

        echo "  Linking $target_path -> $source_path"
        ln -s "$source_path" "$target_path"
    fi
done

echo ""
echo "Done! Claude config is now symlinked."
echo ""
echo "Backups of original files (if any) have .backup.TIMESTAMP extension"
