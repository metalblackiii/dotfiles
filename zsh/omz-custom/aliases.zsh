# CLI shortcuts
alias t=turbo
alias co=codex
alias cl=claude
alias cc=claude

# eza (modern ls)
alias ls='eza'
alias ll='eza -l --git'
alias la='eza -la --git'
alias tree='eza --tree'

# lazygit
alias lg='lazygit'

# yazi (cd to last dir on quit with q, stay with Q)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# bat-extras (man pages with syntax highlighting)
alias man='batman'
