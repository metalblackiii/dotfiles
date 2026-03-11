#!/usr/bin/env bash
set -euo pipefail

# codex-research.sh — Reliable wrapper for codex exec in co-research workflows
#
# Reads prompt from stdin, runs codex exec, writes output to --output path.
# Avoids tee pipelines, captures output in a variable, writes atomically.
#
# Usage:
#   codex-research.sh --output path/to/file.md [--web-search] [--repo /path] <<'PROMPT'
#   Research this topic...
#   PROMPT
#
# Flags:
#   --output PATH    Required. Where to write the markdown output.
#   --web-search     Enable Codex web search tool.
#   --repo PATH      cd to this repo before running (for codebase surveys).
#   --timeout SECS   Max runtime in seconds (default: 300).

output=""
web_search=false
repo=""
timeout_secs=300

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)   output="$2"; shift 2 ;;
        --web-search) web_search=true; shift ;;
        --repo)     repo="$2"; shift 2 ;;
        --timeout)  timeout_secs="$2"; shift 2 ;;
        *)          echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$output" ]]; then
    echo "Error: --output is required" >&2
    exit 1
fi

# Read prompt from stdin
prompt=$(cat)
if [[ -z "$prompt" ]]; then
    echo "Error: no prompt provided on stdin" >&2
    exit 1
fi

# Ensure output directory exists
output_dir=$(dirname "$output")
mkdir -p "$output_dir"

# Build codex command
codex_args=(exec --full-auto)
if [[ "$web_search" == true ]]; then
    codex_args+=(-c 'web_search="live"')
fi

# Change to repo dir if specified
if [[ -n "$repo" ]]; then
    if [[ ! -d "$repo" ]]; then
        echo "Error: repo directory does not exist: $repo" >&2
        exit 1
    fi
    cd "$repo"
fi

# Temp file for atomic write — same filesystem as output for mv reliability
tmp_output="${output}.tmp.$$"
trap 'rm -f "$tmp_output"' EXIT

# Run codex, capture stdout+stderr separately
# stdout = research output, stderr = codex diagnostics
codex_exit=0
codex "${codex_args[@]}" "$prompt" > "$tmp_output" 2>/dev/null || codex_exit=$?

if [[ $codex_exit -ne 0 ]]; then
    echo "Error: codex exec failed with exit code $codex_exit" >&2
    # Still save partial output if any was produced
    if [[ -s "$tmp_output" ]]; then
        mv "$tmp_output" "$output"
        echo "Partial output saved to: $output" >&2
    fi
    exit $codex_exit
fi

# Verify we got output
if [[ ! -s "$tmp_output" ]]; then
    echo "Error: codex produced no output" >&2
    exit 1
fi

# Atomic move to final path
mv "$tmp_output" "$output"

# Report success with file size
file_size=$(wc -c < "$output" | tr -d ' ')
echo "Written: $output (${file_size} bytes)"
