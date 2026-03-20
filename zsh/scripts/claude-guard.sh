# claude-guard.sh — auto-backup Claude runtime data before npm uninstall
# Sourced by .zshrc (not executed standalone)
#
# Wraps npm to intercept uninstall of claude-code. Unlike preexec hooks,
# a function wrapper can actually prevent the command from running.

npm() {
    local subcmd="${1:-}"

    # Fast path: not an uninstall subcommand, skip guard entirely
    case "$subcmd" in
    uninstall|remove|unlink|rm|r|un) ;; # npm uninstall aliases
    *) command npm "$@"; return ;;
    esac

    # Check if any argument is exactly the claude-code package
    local arg
    for arg in "$@"; do
        if [[ "$arg" == "claude-code" || "$arg" == "@anthropic-ai/claude-code" ]]; then
            echo "[claude-guard] Detected Claude Code uninstall — backing up runtime data..."
            if command -v claude-backup >/dev/null 2>&1; then
                claude-backup || {
                    echo "[claude-guard] Backup failed." >&2
                    read -rq "?Continue with uninstall anyway? [y/N] " || return 1
                    echo
                }
            else
                echo "[claude-guard] WARNING: claude-backup not found on PATH." >&2
                echo "[claude-guard] Runtime data at ~/.claude/ may be lost!" >&2
                read -rq "?Continue with uninstall anyway? [y/N] " || return 1
                echo
            fi
            break
        fi
    done

    command npm "$@"
}
