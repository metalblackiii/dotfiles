#!/bin/bash
set -euo pipefail

# Claude Code installer
# Symlinks individual files/dirs, not the whole ~/.claude directory,
# because ~/.claude contains ephemeral data (projects/, cache/, etc.)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR source=../lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

CLAUDE_SOURCE="$DOTFILES_DIR/claude/.claude"
CLAUDE_TARGET="$HOME/.claude"

echo "Installing Claude Code config..."

mkdir -p "$CLAUDE_TARGET"

# Clean up renamed files from previous installs
LEGACY_SYMLINKS=("GUARD.md")
for legacy in "${LEGACY_SYMLINKS[@]}"; do
    legacy_path="$CLAUDE_TARGET/$legacy"
    if [ -L "$legacy_path" ]; then
        echo "  Removing legacy symlink $legacy_path"
        rm "$legacy_path"
    fi
done

CLAUDE_ITEMS=(
    "CLAUDE.md"
    "settings.json"
    "RTK.md"
    "RTK-GLOBAL.md"
    "LSP.md"
    "BASH-PERMISSIONS.md"
    "hooks"
    "skills"
    "agents"
    "scripts"
    "commands"
    "env-file"
)

for item in "${CLAUDE_ITEMS[@]}"; do
    source_path="$CLAUDE_SOURCE/$item"
    if [ -e "$source_path" ]; then
        symlink_with_backup "$source_path" "$CLAUDE_TARGET/$item"
    fi
done

# User-facing CLI tools (claude-backup, claude-restore)
CLAUDE_BIN="$DOTFILES_DIR/claude/bin"
if [ -d "$CLAUDE_BIN" ]; then
    mkdir -p "$HOME/.local/bin"
    for script in "$CLAUDE_BIN"/*; do
        [ -f "$script" ] || continue
        symlink_with_backup "$script" "$HOME/.local/bin/$(basename "$script")"
    done
fi

# RTK config (dependency of rtk-rewrite hook)
RTK_INSTALLER="$DOTFILES_DIR/rtk/install.sh"
if [ -x "$RTK_INSTALLER" ]; then
    bash "$RTK_INSTALLER"
fi

echo "Claude Code config installed."
