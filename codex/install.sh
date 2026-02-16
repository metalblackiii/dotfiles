#!/bin/bash
set -euo pipefail

# Codex installer
# Symlinks config to ~/.codex/ and shares skills via ~/.agents/skills/

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_TARGET="$HOME/.codex"

echo "Installing Codex config..."

mkdir -p "$CODEX_TARGET"

# config.toml lives in codex directory
CODEX_CONFIG="$DOTFILES_DIR/codex/.codex/config.toml"
TARGET_CONFIG="$CODEX_TARGET/config.toml"

if [ -e "$TARGET_CONFIG" ] && [ ! -L "$TARGET_CONFIG" ]; then
    backup_path="${TARGET_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up $TARGET_CONFIG to $backup_path"
    mv "$TARGET_CONFIG" "$backup_path"
elif [ -L "$TARGET_CONFIG" ]; then
    rm "$TARGET_CONFIG"
fi
echo "  Linking $TARGET_CONFIG -> $CODEX_CONFIG"
ln -s "$CODEX_CONFIG" "$TARGET_CONFIG"

# Share skills with Codex via native skill discovery
SKILLS_LINK="$HOME/.agents/skills/personal"
mkdir -p "$(dirname "$SKILLS_LINK")"

if [ -L "$SKILLS_LINK" ]; then
    rm "$SKILLS_LINK"
fi

SKILLS_SOURCE="$DOTFILES_DIR/claude/.claude/skills"
echo "  Linking $SKILLS_LINK -> $SKILLS_SOURCE"
ln -s "$SKILLS_SOURCE" "$SKILLS_LINK"

echo "Codex config installed."
