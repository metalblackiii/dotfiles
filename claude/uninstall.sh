#!/bin/bash
set -euo pipefail

# Claude Code uninstaller
# Removes symlinks created by install.sh (leaves backups untouched)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

CLAUDE_TARGET="$HOME/.claude"

echo "Uninstalling Claude Code config..."

LEGACY_SYMLINKS=("GUARD.md")
CLAUDE_ITEMS=(
    "CLAUDE.md"
    "settings.json"
    "RTK.md"
    "BASH-PERMISSIONS.md"
    "hooks"
    "skills"
    "agents"
    "scripts"
    "commands"
)

for item in "${LEGACY_SYMLINKS[@]}" "${CLAUDE_ITEMS[@]}"; do
    remove_symlink "$CLAUDE_TARGET/$item"
done

# User-facing CLI tools
CLAUDE_BIN="$DOTFILES_DIR/claude/bin"
if [ -d "$CLAUDE_BIN" ]; then
    for script in "$CLAUDE_BIN"/*; do
        [ -f "$script" ] || continue
        remove_symlink "$HOME/.local/bin/$(basename "$script")"
    done
fi

# RTK config is installed as a Claude dependency.
RTK_UNINSTALLER="$DOTFILES_DIR/rtk/uninstall.sh"
if [ -x "$RTK_UNINSTALLER" ]; then
    bash "$RTK_UNINSTALLER"
fi

echo "Claude Code config uninstalled."
