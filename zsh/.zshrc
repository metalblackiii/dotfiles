# Powerlevel10k instant prompt (must stay near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Default editor (used by yazi, git, etc.)
export EDITOR='code -w'
export KUBE_EDITOR='code -w'

# Disable RTK_TEE (claude token saver) for better security
export RTK_TEE=0

# Oh My Zsh — https://github.com/ohmyzsh/ohmyzsh/wiki/Settings
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  autoupdate
  bgnotify
  brew
  command-not-found
  copypath
  docker
  docker-compose
  zsh-syntax-highlighting
  fzf
  fzf-tab
  git
  helm
  kubectl
  sudo
  you-should-use
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-better-npm-completion
)

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/martinburch/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# mysql-client is keg-only — add to PATH for dbq and direct mysql usage
for _mc in /opt/homebrew/opt/mysql-client/bin /usr/local/opt/mysql-client/bin; do
  [[ -d "$_mc" ]] && { export PATH="$_mc:$PATH"; break; }
done
unset _mc

source $ZSH/oh-my-zsh.sh

# Can configure z (now) or override cd
# eval "$(zoxide init zsh --cmd cd)"
eval "$(zoxide init zsh)"

# Private env vars (API keys, tokens, credentials)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

#export AWS_DEFAULT_PROFILE=<in private env vars>

# Resolve dotfiles dir once via .zshrc symlink
_dotfiles_zsh="${${:-$HOME/.zshrc}:A:h}"

[[ -f "$_dotfiles_zsh/scripts/aws-sso-profiles.sh" ]] && \
  source "$_dotfiles_zsh/scripts/aws-sso-profiles.sh"

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Guard against Claude Code uninstall destroying runtime data
[[ -f "$_dotfiles_zsh/scripts/claude-guard.sh" ]] && \
  source "$_dotfiles_zsh/scripts/claude-guard.sh"

# fnm — fast node manager (replaces nvm)
eval "$(fnm env --use-on-cd --shell zsh)"

export PATH="$HOME/.local/bin:$PATH"
