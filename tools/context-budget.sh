#!/usr/bin/env bash
set -euo pipefail

# Context Budget Calculator
# Measures token cost of CLAUDE.md + all @imports for Claude Code sessions.
# Resolves imports through symlinks (matching Claude Code's real-path resolution).

readonly GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"

usage() {
    cat <<'EOF'
Usage: tools/context-budget.sh [-h] [PROJECT_DIR]

Measure the always-on token cost of CLAUDE.md context.

Arguments:
    PROJECT_DIR    Project root to check (default: current directory)

Options:
    -h             Show this help

Thresholds:
    <2K tokens     lean
    2K-10K tokens  healthy
    10K-25K tokens heavy — adherence starts dropping
    >25K tokens    overloaded — significant attention dilution
EOF
}

# Resolve a path, expanding ~ and following symlinks
resolve() {
    local target="${1/#\~/$HOME}"
    realpath "$target" 2>/dev/null || echo "$target"
}

# Extract @import paths from a file, resolved to absolute paths.
# Claude Code resolves @ relative to the real file location (after symlinks).
extract_imports() {
    local file="$1"
    local real_dir
    real_dir="$(dirname "$(resolve "$file")")"

    { grep -E '^@' "$file" 2>/dev/null || true; } | while IFS= read -r line; do
        local ref="${line#@}"
        ref="${ref/#\~/$HOME}"
        if [[ "$ref" = /* ]]; then
            resolve "$ref"
        else
            local candidate="$real_dir/$ref"
            if [[ -e "$candidate" ]]; then
                resolve "$candidate"
            else
                echo "$real_dir/$ref"
            fi
        fi
    done
}

# Collect scope|path pairs for an entry file and its imports (2 levels deep)
collect() {
    local entry="$1" scope="$2"
    [[ -f "$entry" ]] || return 0

    echo "$scope|$(resolve "$entry")"

    { extract_imports "$entry" || true; } | while IFS= read -r imported; do
        echo "$scope|$imported"
        # Second-level imports
        if [[ -f "$imported" ]]; then
            { extract_imports "$imported" || true; } | while IFS= read -r nested; do
                echo "$scope|$nested"
            done
        fi
    done
}

main() {
    while getopts ":h" opt; do
        case $opt in
            h) usage; exit 0 ;;
            \?) echo "Error: invalid option -${OPTARG}" >&2; exit 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    local project_dir="${1:-.}"
    local project_claude="$project_dir/CLAUDE.md"
    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT

    # Gather all files from both scopes
    collect "$GLOBAL_CLAUDE" "global" >> "$TMPFILE"
    [[ -f "$project_claude" ]] && collect "$project_claude" "project" >> "$TMPFILE"

    # Deduplicate by resolved path (first scope wins)
    local seen_file
    seen_file=$(mktemp)
    local total_tokens=0 total_lines=0 file_count=0
    local output_file
    output_file=$(mktemp)

    while IFS='|' read -r scope path; do
        [[ -z "$path" ]] && continue
        grep -qxF "$path" "$seen_file" 2>/dev/null && continue
        echo "$path" >> "$seen_file"

        local display_path="${path/#$HOME/~}"

        if [[ ! -f "$path" ]]; then
            printf "%-9s %-55s %6s %8s\n" "$scope" "$display_path" "—" "MISSING" >> "$output_file"
            continue
        fi

        local chars lines tokens
        chars=$(wc -c < "$path" | tr -d ' ')
        lines=$(wc -l < "$path" | tr -d ' ')
        tokens=$(( chars / 4 ))

        printf "%-9s %-55s %6s %8s\n" "$scope" "$display_path" "$lines" "$tokens" >> "$output_file"
        total_tokens=$(( total_tokens + tokens ))
        total_lines=$(( total_lines + lines ))
        file_count=$(( file_count + 1 ))
    done < "$TMPFILE"

    rm -f "$seen_file"

    # Rating
    local rating
    if (( total_tokens < 2000 )); then rating="lean"
    elif (( total_tokens < 10000 )); then rating="healthy"
    elif (( total_tokens < 25000 )); then rating="heavy"
    else rating="overloaded"
    fi

    # Output
    printf "Context Budget: %s tokens (~%s lines, %s files) — %s\n\n" \
        "$total_tokens" "$total_lines" "$file_count" "$rating"

    printf "%-9s %-55s %6s %8s\n" "SCOPE" "FILE" "LINES" "TOKENS"
    printf "%-9s %-55s %6s %8s\n" \
        "─────────" "───────────────────────────────────────────────────────" \
        "──────" "────────"

    cat "$output_file"
    rm -f "$output_file"

    printf "%-9s %-55s %6s %8s\n" "" "" "──────" "────────"
    printf "%-9s %-55s %6s %8s\n" "" "TOTAL" "$total_lines" "$total_tokens"
    echo ""

    if [[ "$rating" == "heavy" || "$rating" == "overloaded" ]]; then
        echo "Warning: ${total_tokens} tokens exceeds the 10K healthy target."
        echo "Consider moving low-frequency rules to skills."
    fi
}

main "$@"
