# =============== Keybindings ===============
# bindkey -e  # emacs key bindings
bindkey -v  # vi key bindings
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

# =============== Ruby (rbenv) ===============
# Added by `rbenv init` on Wed 10 Jun 19:42:02 CAT 2026
eval "$(~/.rbenv/bin/rbenv init - --no-rehash zsh)"

# =============== https://github.com/tobi/try ===============
eval "$(try init)"

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
# Required by fzf-tab: let it capture the unambiguous-prefix case instead of
# zsh showing its own completion menu.
zstyle ':completion:*' menu no
# fzf-tab: colorize filenames in the completion list itself using LS_COLORS
# (Linux/openSUSE already populates LS_COLORS via /etc/zshrc's dircolors
# call before this file loads, unlike macOS — no eval needed here.)
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# fzf-tab: preview directory contents with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# =============== Carapace ===============
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# =============== Aliases ===============
# General
alias open="xdg-open"
alias ls='eza --icons=auto'
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
alias chromium='chromium --user-data-dir="$(mktemp -d)"'

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

# =============== FZF ===============
# System fzf (zypper pkg) ships integration under /usr/share/fzf/shell, not
# ~/.fzf.zsh (that file only exists for fzf's own git-clone install script).
eval "$(fzf --zsh)"
# Use fd as the default source for fzf (respects .gitignore, includes hidden)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# Ctrl+T and Alt+C use fd too, for consistent behaviour
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
# Nicer fzf UI defaults
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :100 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --level=2 {}'"

# =============== Atuin ===============
# Must load after the FZF block above — both bind Ctrl-R, and atuin should win
# in the keymaps it actually overrides. It rebinds ^R in the emacs and viins
# keymaps (i.e. normal insert-mode typing), so that's what you get almost
# always. It does NOT rebind vicmd's ^R — in vi *normal* mode (after Esc) it
# binds `/` instead, vim-style, so vicmd's ^R still falls through to fzf's
# older fzf-history-widget from the FZF block above. Intentional on atuin's
# part, just easy to forget which mode you're in.
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# =============== FZF-tab ===============
# Must load after the FZF block above (fzf's own shell integration also binds
# Tab for its `**`-trigger completion) and before the zsh-syntax-highlighting /
# zsh-autosuggestions block below — fzf-tab needs to be the last thing to bind
# Tab. See fzf-tab's README "Compatibility with other plugins".
[ -f "$HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh" ] && source "$HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh"

# =============== Forgit ===============
# Must load after the git aliases defined earlier in this file — forgit's
# aliases (ga, gd, gco, gcb, gss) intentionally win over the plain git ones.
# ga/gd/gco/gcb fall back to plain git behavior when given args, so the
# override is safe. gss has no such fallback: it replaces `git status -s`
# with forgit's stash browser entirely (unrelated command, not a superset).
# delta can't detect terminal width via ioctl when fzf pipes its preview
# pane (not a tty), so it falls back to a narrow default and wraps early.
# Force it to use fzf's exact preview-pane width instead.
export FORGIT_PREVIEW_PAGER='delta --width="$FZF_PREVIEW_COLUMNS"'
# Override glo's preview with a wrapper that also renders images (kitty icat)
# for commits touching image files — delta alone can only print "Binary
# files ... differ". FORGIT_LOG_FZF_OPTS is appended after forgit's own
# --preview flag in the same fzf options string, and fzf keeps the last
# value of a repeated flag, so this replaces it outright; the enter/yank
# --bind's are separate flags and stay untouched. See .config/forgit/log-preview.sh.
export FORGIT_LOG_FZF_OPTS="--preview=\"$HOME/.config/forgit/log-preview.sh {}\""
[ -f "$HOME/.zsh/forgit/forgit.plugin.zsh" ] && source "$HOME/.zsh/forgit/forgit.plugin.zsh"

# log-preview.sh's images use kitty's unicode-placeholder mode, which is
# supposed to be self-cleaning (the image is anchored to ordinary text, so
# it clears when that text is overwritten) — but wrap glo to sweep up any
# leftovers once the picker quits (accept, Esc, Ctrl-C) anyway, as cheap
# insurance against edge cases (e.g. a render killed mid-transfer by the
# timeout in log-preview.sh).
unalias glo 2>/dev/null
glo() {
    forgit::log "$@"
    command -v kitten &>/dev/null && timeout --signal=TERM --kill-after=1 2 kitten icat --clear-all &>/dev/null
}

# =============== Starship ===============
eval "$(starship init zsh)"

# ============ syntax highlighting & autosuggestions =============
[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# =============== Local / Secret Config ===============
# Keep secrets and machine-specific config in .zshrc.local
# This file should NOT be tracked by git.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# =============== Yazi ===============
function y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}

# =============== Glow ===============
export GLOW_STYLE="$HOME/.config/glow/catppuccin-mocha.json"

# =============== Zoxide ===============
eval "$(zoxide init zsh)"



# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
