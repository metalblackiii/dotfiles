#!/bin/bash
set -euo pipefail

# Claude Code installer
# Symlinks individual files/dirs, not the whole ~/.claude directory,
# because ~/.claude contains ephemeral data (projects/, cache/, etc.)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_SOURCE="$DOTFILES_DIR/claude/.claude"
CLAUDE_TARGET="$HOME/.claude"

echo "Installing Claude Code config..."

mkdir -p "$CLAUDE_TARGET"

CLAUDE_ITEMS=(
    "CLAUDE.md"
    "settings.json"
    "hooks"
    "skills"
    "commands"
    "agents"
    "scripts"
)

for item in "${CLAUDE_ITEMS[@]}"; do
    source_path="$CLAUDE_SOURCE/$item"
    target_path="$CLAUDE_TARGET/$item"

    if [ -e "$source_path" ]; then
        if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
            backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
            echo "  Backing up $target_path to $backup_path"
            mv "$target_path" "$backup_path"
        elif [ -L "$target_path" ]; then
            rm "$target_path"
        fi

        echo "  Linking $target_path -> $source_path"
        ln -s "$source_path" "$target_path"
    fi
done

echo "Claude Code config installed."
