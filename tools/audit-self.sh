#!/usr/bin/env bash
set -euo pipefail

# Fresh-eyes audit of this dotfiles repo using Claude with zero project context.
# Copies the repo to a temp dir, strips all instruction files, and runs a review.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DEFAULT_PROMPT="Fresh eyes review of this dotfiles repo. Evaluate organization, \
consistency, shell script quality, and anything that seems off or could be improved."

usage() {
    cat <<EOF
Usage: ${0##*/} [-h] [-p PROMPT]

Run a fresh-eyes audit of the dotfiles repo with no project context.

Options:
    -h          Show this help
    -p PROMPT   Custom review prompt (default: general org/quality review)
EOF
}

cleanup() {
    if [[ -n "${TMPDIR_CREATED:-}" && -d "${TMPDIR_CREATED}" ]]; then
        rm -rf "$TMPDIR_CREATED"
    fi
}

main() {
    local prompt="$DEFAULT_PROMPT"

    while getopts ":hp:" opt; do
        case $opt in
            h) usage; exit 0 ;;
            p) prompt="$OPTARG" ;;
            :) echo "Error: -${OPTARG} requires an argument" >&2; exit 1 ;;
            \?) echo "Error: invalid option -${OPTARG}" >&2; exit 1 ;;
        esac
    done

    if ! command -v claude >/dev/null 2>&1; then
        echo "Error: claude CLI not found" >&2
        exit 1
    fi

    TMPDIR_CREATED="$(mktemp -d)"
    trap cleanup EXIT

    echo "Copying dotfiles to temp dir..."
    cp -r "$DOTFILES_DIR" "$TMPDIR_CREATED/dotfiles"

    # Strip all instruction files so the review is unbiased
    find "$TMPDIR_CREATED/dotfiles" \
        \( -name 'CLAUDE.md' -o -name 'AGENTS.md' -o -name 'HANDOFF.md' \) \
        -delete

    echo "Running fresh-eyes audit (no project context)..."
    echo ""

    cd "$TMPDIR_CREATED/dotfiles"
    claude -p "$prompt" \
        --system-prompt "You are a code reviewer with no prior context about this repo." \
        --setting-sources "" \
        --no-chrome \
        --disable-slash-commands
}

main "$@"
