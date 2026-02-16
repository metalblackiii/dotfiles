#!/bin/bash
set -euo pipefail

# Claude Code uninstaller
# Removes symlinks created by install.sh (leaves backups untouched)

CLAUDE_TARGET="$HOME/.claude"

echo "Uninstalling Claude Code config..."

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
    target_path="$CLAUDE_TARGET/$item"

    if [ -L "$target_path" ]; then
        echo "  Removing symlink $target_path"
        rm "$target_path"
    fi
done

echo "Claude Code config uninstalled."
