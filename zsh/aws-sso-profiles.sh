#!/bin/bash
# AWS SSO Profile Management Script — Lazy Loading
# Source this file in your shell configuration (e.g., .zshrc, .bashrc)
#
# Zero AWS CLI calls at load time:
#   - Profiles discovered by parsing ~/.aws/config (awk, no CLI)
#   - Region read from config file (awk, no CLI)
#   - Credentials fetched only on explicit profile switch
#   - AWS_PROFILE and AWS_REGION set immediately from config

# ── Guard ─────────────────────────────────────────────────────────────────────

# Configuration - you MUST set this before sourcing this script
# Example: export AWS_DEFAULT_PROFILE="ptek-dev"
if [[ -z "${AWS_DEFAULT_PROFILE:-}" ]]; then
    echo "AWS_DEFAULT_PROFILE not set — AWS profile aliases disabled." >&2
    echo "Add to your .zshrc/.bashrc before sourcing: export AWS_DEFAULT_PROFILE=\"<profile>\"" >&2
    return 1
fi

if [[ ! -f "${HOME}/.aws/config" ]]; then
    echo "~/.aws/config not found — AWS profile aliases disabled." >&2
    return 1
fi

# ── Pure-shell config parsers (no aws CLI) ────────────────────────────────────

# List profile names from [profile X] and [default] sections
__aws_parse_profiles() {
    awk '
        /^\[default\]/ { print "default" }
        /^\[profile /  { gsub(/\[profile |\]/, ""); print }
    ' "${HOME}/.aws/config"
}

# Read a key from a specific profile section
# Handles both [profile X] and [default] section formats
# Usage: __aws_config_get <profile> <key>
__aws_config_get() {
    local target_profile="$1" target_key="$2"
    awk -v prof="${target_profile}" -v key="${target_key}" '
        /^\[default\]/ {
            active = (prof == "default")
            next
        }
        /^\[profile / {
            gsub(/\[profile |\]/, "")
            active = ($0 == prof)
            next
        }
        /^\[/ { active = 0; next }
        active && $0 ~ "^[[:space:]]*"key"[[:space:]]*=" {
            sub(/^[^=]*=[[:space:]]*/, "")
            sub(/[[:space:]]*$/, "")
            print
            exit
        }
    ' "${HOME}/.aws/config"
}

# Get the sso_session referenced by a profile, or fall back to first in config
__aws_get_sso_session() {
    local profile="${1:-${AWS_PROFILE:-${AWS_DEFAULT_PROFILE}}}"
    local session
    session=$(__aws_config_get "${profile}" "sso_session")
    if [[ -z "${session}" ]]; then
        session=$(awk '/^\[sso-session /{gsub(/\[sso-session |\]/,""); print; exit}' "${HOME}/.aws/config")
    fi
    echo "${session}"
}

# ── Core functions ────────────────────────────────────────────────────────────

aws-clear() {
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    unset AWS_PROFILE AWS_REGION
    echo "AWS environment variables cleared"
}

# Fetch and export credentials (single aws CLI call, on-demand only)
__aws_populate_credentials() {
    local profile="${1:-${AWS_PROFILE}}"
    [[ -z "${profile}" ]] && { echo "No profile specified" >&2; return 1; }

    echo "Fetching credentials for ${profile}..."
    local creds
    creds=$(aws configure export-credentials --profile "${profile}" --format env-no-export 2>/dev/null) || {
        echo "Could not fetch credentials for ${profile} — run sso-login" >&2
        return 1
    }

    local key value
    while IFS='=' read -r key value; do
        value="${value%\"}"
        value="${value#\"}"
        case "${key}" in
            AWS_ACCESS_KEY_ID)     export AWS_ACCESS_KEY_ID="${value}" ;;
            AWS_SECRET_ACCESS_KEY) export AWS_SECRET_ACCESS_KEY="${value}" ;;
            AWS_SESSION_TOKEN)     export AWS_SESSION_TOKEN="${value}" ;;
        esac
    done <<< "${creds}"
    echo "Credentials loaded"
}

# Switch profile: set env vars + fetch credentials
__aws_switch_profile() {
    local profile="$1"
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

    export AWS_PROFILE="${profile}"

    # Region from config — no CLI call
    local region
    region=$(__aws_config_get "${profile}" "region")
    [[ -n "${region}" ]] && export AWS_REGION="${region}"

    __aws_populate_credentials "${profile}"
    aws-whoami
    __aws_show_aliases
}

aws-whoami() {
    echo "Current AWS Profile: ${AWS_PROFILE:-not set}"
    echo "Current AWS Region: ${AWS_REGION:-not set}"
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
        aws sts get-caller-identity 2>/dev/null || echo "Credentials expired — run sso-login"
    else
        echo "No credentials loaded — switch to a profile to fetch"
    fi
}

sso-login() {
    local profile="${AWS_PROFILE:-${AWS_DEFAULT_PROFILE}}"
    local sso_session
    sso_session=$(__aws_get_sso_session "${profile}")
    if [[ -n "${sso_session}" ]]; then
        aws sso login --sso-session "${sso_session}"
    else
        echo "No SSO session found for profile ${profile}" >&2
        return 1
    fi
    __aws_switch_profile "${profile}"
}

aws-profiles() {
    echo "Available AWS Profiles:"
    echo ""
    local profile safe_alias
    while IFS= read -r profile; do
        [[ -z "${profile}" ]] && continue
        local marker=""
        [[ "${AWS_PROFILE:-}" == "${profile}" ]] && marker=" (current)"
        safe_alias="${profile//-/_}"
        echo "  ${profile}${marker}  ->  ${safe_alias}"
    done < <(__aws_parse_profiles)
    echo ""
    echo "Usage: <alias> to switch | aws-whoami | sso-login"
}

__aws_show_aliases() {
    local aliases=()
    local profile safe_alias
    while IFS= read -r profile; do
        [[ -z "${profile}" ]] && continue
        safe_alias="${profile//-/_}"
        aliases+=("${safe_alias}")
    done < <(__aws_parse_profiles)

    if [[ ${#aliases[@]} -gt 0 ]]; then
        local alias_list
        alias_list=$(printf '%s/' "${aliases[@]}")
        alias_list="${alias_list%/}"
        echo "Switch: ${alias_list}"
    fi
}

# ── Dynamic alias creation (pure shell, instant) ─────────────────────────────
# Creates shell functions (not aliases) so each can run multi-line logic

__aws_setup_aliases() {
    local profile safe_alias
    while IFS= read -r profile; do
        [[ -z "${profile}" ]] && continue
        safe_alias="${profile//-/_}"
        # Shell-safe name validation
        [[ "${safe_alias}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || continue
        # Profile name validation — alphanumeric, hyphens, underscores only
        [[ "${profile}" =~ ^[a-zA-Z0-9_-]+$ ]] || continue
        eval "${safe_alias}() { __aws_switch_profile '${profile}'; }"
    done < <(__aws_parse_profiles)
}

# ── Initialization (all instant — no CLI calls) ──────────────────────────────

__aws_init() {
    __aws_setup_aliases

    # Set profile + region from config without fetching credentials
    export AWS_PROFILE="${AWS_DEFAULT_PROFILE}"
    local init_region
    init_region=$(__aws_config_get "${AWS_DEFAULT_PROFILE}" "region")
    [[ -n "${init_region}" ]] && export AWS_REGION="${init_region}"

    echo "AWS: ${AWS_PROFILE} (${AWS_REGION:-no region}) | credentials load on first switch"
    __aws_show_aliases
}

__aws_init
