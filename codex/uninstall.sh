#!/bin/bash
set -euo pipefail

# Codex uninstaller
# Removes symlinks created by install.sh (leaves backups untouched)

CODEX_TARGET="$HOME/.codex"

echo "Uninstalling Codex config..."

CODEX_ITEMS=(
    "config.toml"
)

for item in "${CODEX_ITEMS[@]}"; do
    target_path="$CODEX_TARGET/$item"

    if [ -L "$target_path" ]; then
        echo "  Removing symlink $target_path"
        rm "$target_path"
    fi
done

# Remove shared skills symlink
SKILLS_LINK="$HOME/.agents/skills/personal"
if [ -L "$SKILLS_LINK" ]; then
    echo "  Removing symlink $SKILLS_LINK"
    rm "$SKILLS_LINK"
fi

echo "Codex config uninstalled."
