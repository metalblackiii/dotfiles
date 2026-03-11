#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# codebase-memory-mcp — uninstaller
# ============================================================================
#
# Removes:
#   1. MCP registrations from Claude Code, Codex CLI, Cursor, Windsurf,
#      VS Code, Zed (via built-in `uninstall` command)
#   2. Skills installed by `codebase-memory-mcp install`
#   3. The binary itself (~/.local/bin/codebase-memory-mcp)
#   4. Graph databases (~/.cache/codebase-memory-mcp/) — prompted, optional
# ============================================================================

INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="codebase-memory-mcp"
BINARY_PATH="${INSTALL_DIR}/${BINARY_NAME}"
CACHE_DIR="$HOME/.cache/codebase-memory-mcp"

if [[ ! -x "$BINARY_PATH" ]]; then
    echo "Binary not found at ${BINARY_PATH} — nothing to uninstall."
    exit 0
fi

# Deregister from editors and remove skills
echo "Deregistering MCP server from editors..."
"$BINARY_PATH" uninstall

# Remove binary
rm -f "$BINARY_PATH"
echo "Removed ${BINARY_PATH}"

# Prompt before removing graph data
if [[ -d "$CACHE_DIR" ]]; then
    echo ""
    printf "Remove graph databases at %s? [y/N] " "$CACHE_DIR"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        rm -rf "$CACHE_DIR"
        echo "Removed ${CACHE_DIR}"
    else
        echo "Kept ${CACHE_DIR} — remove manually if no longer needed."
    fi
fi

echo ""
echo "Done. Restart Claude Code to complete removal."
