# =============== Keybindings ===============
bindkey -e  # Use emacs key bindings
# vi-style word movement for Ctrl+Arrows
bindkey '^[[1;5C' vi-forward-word   # Ctrl+Right
bindkey '^[[1;5D' vi-backward-word  # Ctrl+Left
bindkey '^[[H' beginning-of-line    # Home
bindkey '^[[F' end-of-line          # End

# =============== Options ===============
setopt autocd              # Change directory by typing its name
setopt extendedglob        # Use extended globbing features
setopt interactivecomments # Allow comments in interactive shell
setopt magicequalsubst     # Filename expansion for arguments of the form 'anything=~'
setopt notify              # Report status of background jobs immediately
setopt numericglobsort     # Sort filenames numerically when globbing
setopt promptsubst         # Substitution in the prompt
setopt sharehistory        # Share history between different instances of zsh

# =============== History ===============
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history    # Save timestamps to history file
setopt appendhistory
setopt incappendhistory
setopt histignorealldups
setopt histignoredups
setopt histignorespace
setopt histreduceblanks

history() {
    if [[ $# -eq 0 ]]; then
        builtin history -i 1  # Show ISO 8601 timestamps (YYYY-MM-DD HH:MM)
    else
        builtin history "$@"
    fi
}

# =============== Paths ===============
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$PATH:/usr/sbin"

# =============== SSH Agent ===============
eval `keychain --eval --quiet ~/.ssh/id_ed25519 ~/.ssh/id_rsa`

# =============== Volta ===============
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# =============== Rust ===============
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# =============== Editor ===============
export VISUAL=nvim
export EDITOR="$VISUAL"

# =============== Pyenv ===============
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# =============== Virtualenvwrapper ===============
export WORKON_HOME="$HOME/.virtualenvs"
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.13
source /usr/bin/virtualenvwrapper-3.13

# =============== Go ===============
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# =============== Completions ===============
fpath=(~/.zfunc "$HOME/.zsh/zsh-completions/src" $fpath)
export FPATH="$HOME/.local/share/eza-completions/zsh:$FPATH"

# Enable completion cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# =============== Aliases ===============
# General
alias open="xdg-open"
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias la='eza -lah --icons --git'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias du='duf'
alias top='btop'
alias cd='z'
alias ts='date +"%Y-%m-%d-%H-%M-%S"'
alias trash='gio trash'
alias pipup='pip install --upgrade pip'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git Helper Functions
function git_current_branch() {
  git symbolic-ref --short -q HEAD
}

function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return 0
    fi
  done
  echo master
}

# Git Aliases
alias g='git'
alias gst='git status'
alias gss='git status --short'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit --verbose'
alias gcmsg='git commit --message'
alias gca='git commit --verbose --all'
alias gc!='git commit --verbose --amend'
alias gb='git branch'
alias gba='git branch --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git pull'
alias gp='git push'
alias glog='git log --oneline --decorate --graph'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'

# ggp - push current branch to origin with flexibility
function ggp() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git push origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git push origin "${b:=$1}"
  fi
}
compdef _git ggp=git-checkout

# Docker Aliases
alias dco="docker compose"
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'

# =============== Custom Functions ===============
mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

tar_max() {
  tar --exclude='.DS_Store' --exclude='node_modules' --exclude='__pycache__' -cv "$1" | xz -3e > "$2".tar.xz
}

grep_this() {
  command grep --color -inrw . -e "$1"
  echo "Matches: $(command grep -inrw . -e "$1" | wc -l)"
}

mkdir_date() {
  mkdir -p $(date '+%Y-%h-%d-%a')
}

kill_spaces() {
  command find . -name "*.$1" -type f -print0 | while IFS= read -r -d $'\0' f; do mv -v "$f" "${f// /_}"; done
}

# PDF Management
encrypt_pdf() {
  encrypted_pdf="${1%.pdf}.128.pdf"
  pdftk "$1" output ${encrypted_pdf} owner_pw "$2" allow printing verbose
  mv -v "$1" "${1%.pdf}_src.pdf"
  mv -v ${encrypted_pdf} "${encrypted_pdf%.128.pdf}.pdf"
}

split_pdf() {
  split_files="${1%.pdf}_%02d.pdf"
  pdftk "$1" burst output ${split_files} verbose
}

grep_pdf() {
  command find . -iname '*.pdf' | while IFS= read -r filename
  do
    pdftotext -enc Latin1 "$filename" - | command grep --with-filename --label="$filename" --color -i "$1"
  done
}

# Interactive ripgrep: results in fzf with bat preview on the right
rgf() {
  rg --color=always --line-number "$@" \
    | fzf --ansi --delimiter=: \
          --preview 'bat --color=always {1} --highlight-line {2}' \
          --preview-window 'right:60%:+{2}-3'
}

# use delta with diff
diff() {
  command diff --color=always "$@" | delta
}

# check python version in pyproject.toml
py_version() {
    yq '.tool.poetry.dependencies.python' pyproject.toml
}

function add_nodemodules_bin() {
    local bin_path="./node_modules/.bin"
    if [[ -d "$bin_path" && ":$PATH:" != *":$bin_path:"* ]]; then
        export PATH="$bin_path:$PATH"
    fi
}
autoload -U add-zsh-hook
add-zsh-hook chpwd add_nodemodules_bin

# =============== FZF, Zoxide, Starship ===============
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Use fd as the default source for fzf (respects .gitignore, includes hidden)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# Ctrl+T and Alt+C use fd too, for consistent behaviour
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
# Nicer fzf UI defaults
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# ============ syntax highlighting & autosuggestions =============
[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# =============== Local / Secret Config ===============
# Keep secrets and machine-specific config in .zshrc.local
# This file should NOT be tracked by git.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
