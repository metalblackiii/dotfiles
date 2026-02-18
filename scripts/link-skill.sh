#!/bin/bash
set -euo pipefail

# Creates a new skill scaffold and symlinks it into the appropriate view directories.
#
# Usage: scripts/link-skill.sh <skill-name> [shared|claude|codex]
#   shared (default) — symlinks into both claude and codex views
#   claude           — symlinks into claude view only
#   codex            — symlinks into codex view only

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    echo "Usage: $(basename "$0") <skill-name> [shared|claude|codex]"
    echo "  shared (default) — symlinks into both claude and codex views"
    echo "  claude           — symlinks into claude view only"
    echo "  codex            — symlinks into codex view only"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

SKILL_NAME="$1"
SCOPE="${2:-shared}"

case "$SCOPE" in
    shared|claude|codex) ;;
    *) echo "Error: scope must be shared, claude, or codex"; usage ;;
esac

SKILL_DIR="$DOTFILES_DIR/skills/$SCOPE/$SKILL_NAME"
CLAUDE_VIEW="$DOTFILES_DIR/claude/.claude/skills"
CODEX_VIEW="$DOTFILES_DIR/codex/.agents/skills"

# Create the skill scaffold
if [ -d "$SKILL_DIR" ]; then
    echo "Skill already exists: $SKILL_DIR"
    exit 1
fi

mkdir -p "$SKILL_DIR"
cat > "$SKILL_DIR/SKILL.md" << 'SCAFFOLD'
---
name: SKILL_NAME_PLACEHOLDER
autoInvoke: false
invocationTrigger: ""
---

# SKILL_NAME_PLACEHOLDER

TODO: Describe this skill.
SCAFFOLD

# Replace placeholder with actual skill name
sed -i '' "s/SKILL_NAME_PLACEHOLDER/$SKILL_NAME/g" "$SKILL_DIR/SKILL.md"

echo "Created $SKILL_DIR/SKILL.md"

# Create symlinks in the appropriate view directories
link_to_view() {
    local view_dir="$1"
    local rel_path="../../../skills/$SCOPE/$SKILL_NAME"

    if [ -e "$view_dir/$SKILL_NAME" ]; then
        echo "  Symlink already exists: $view_dir/$SKILL_NAME"
        return
    fi

    mkdir -p "$view_dir"
    ln -s "$rel_path" "$view_dir/$SKILL_NAME"
    echo "  Linked $view_dir/$SKILL_NAME -> $rel_path"
}

case "$SCOPE" in
    shared)
        link_to_view "$CLAUDE_VIEW"
        link_to_view "$CODEX_VIEW"
        ;;
    claude)
        link_to_view "$CLAUDE_VIEW"
        ;;
    codex)
        link_to_view "$CODEX_VIEW"
        ;;
esac

echo "Done."
