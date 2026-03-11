#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# codebase-memory-mcp — version-pinned installer
# ============================================================================
#
# What:  MCP server that indexes source code into a local SQLite knowledge
#        graph. Exposes 14 tools for structural code search, call tracing,
#        change impact, and architecture docs. Single Go binary, no Docker,
#        no external databases, no API keys.
#
# Repo:  https://github.com/DeusData/codebase-memory-mcp
#
# Vetting:
#   Passed mcp-vetting checklist 2026-03-10 (v0.3.1).
#   - Zero network egress during normal operation (GitHub API only for updates)
#   - Local-only storage (~/.cache/codebase-memory-mcp/)
#   - All deps exact-pinned, go.sum committed, no high/critical CVEs
#   - No eval, no dynamic code loading, no credential path writes
#   - HIPAA-safe: no PHI/PII handling, no data leaves the machine
#
# Upgrade:
#   1. Bump VERSION below to the new tag
#   2. Re-run mcp-vetting skill against the new version
#   3. Re-run this script — checksum verification catches download corruption
#      (but not a compromised upstream; for that, pin the hash in-repo)
# ============================================================================

VERSION="v0.3.1"
REPO="DeusData/codebase-memory-mcp"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="codebase-memory-mcp"

# --- Platform detection ---

detect_platform() {
    local os arch
    os=$(uname -s)
    arch=$(uname -m)

    case "$os" in
        Darwin) os="darwin" ;;
        Linux)  os="linux" ;;
        *)      echo "Unsupported OS: $os" >&2; exit 1 ;;
    esac

    case "$arch" in
        arm64|aarch64) arch="arm64" ;;
        x86_64|amd64)
            if [ "$os" = "darwin" ] && sysctl -n hw.optional.arm64 2>/dev/null | grep -q '1'; then
                arch="arm64"
            else
                arch="amd64"
            fi
            ;;
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
    esac

    echo "${os}-${arch}"
}

# --- Main ---

PLATFORM=$(detect_platform)
ASSET="codebase-memory-mcp-${PLATFORM}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"
CHECKSUM_URL="https://github.com/${REPO}/releases/download/${VERSION}/checksums.txt"

TMPDIR=$(mktemp -d)
cleanup() {
    [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Installing ${BINARY_NAME} ${VERSION} (${PLATFORM})"
echo ""

# Download binary + checksums
echo "Downloading ${ASSET}..."
curl -fsSL "$DOWNLOAD_URL" -o "${TMPDIR}/${ASSET}"
curl -fsSL "$CHECKSUM_URL" -o "${TMPDIR}/checksums.txt"

# Verify SHA-256
echo "Verifying checksum..."
(cd "$TMPDIR" && grep -F "$ASSET" checksums.txt | shasum -a 256 -c -)

# Extract and install
tar xzf "${TMPDIR}/${ASSET}" -C "$TMPDIR"
mkdir -p "$INSTALL_DIR"
mv "${TMPDIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
chmod 500 "${INSTALL_DIR}/${BINARY_NAME}"

echo "Installed to ${INSTALL_DIR}/${BINARY_NAME}"

# Register with Claude Code and editors
echo ""
echo "Running MCP registration..."
"${INSTALL_DIR}/${BINARY_NAME}" install

echo ""
echo "Done! Restart Claude Code and verify with /mcp"
echo "Pinned version: ${VERSION} — bump VERSION in this script to upgrade."
