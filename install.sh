#!/usr/bin/env bash
# =============================================================================
# Script: install.sh
# Description: Bootstrap dotfiles by creating symlinks from ~/.config to this
#              repository. Backs up any existing file or directory before
#              replacing it. Safe to re-run (idempotent).
#
# Usage: chmod +x install.sh && ./install.sh
# =============================================================================

set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn()  { echo -e "${YELLOW}[WARNING] $1${NC}"; }
info()  { echo -e "${CYAN}[INFO] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create a timestamped backup of a path, then remove it so a symlink can take its place
backup_and_remove() {
    local target="$1"
    local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
    warn "Backing up existing '${target}' to '${backup}'"
    mv "$target" "$backup"
}

# Create a symlink, backing up whatever is currently at the destination
link() {
    local src="$1"   # path inside dotfiles repo
    local dest="$2"  # path in the live system

    if [ ! -e "$src" ]; then
        warn "Source '${src}' does not exist — skipping."
        return
    fi

    # Already the correct symlink — nothing to do
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        info "Already linked: ${dest}"
        return
    fi

    # Existing symlink pointing elsewhere — remove it
    if [ -L "$dest" ]; then
        warn "Removing stale symlink: ${dest}"
        rm "$dest"
    fi

    # Existing real file or directory — back it up
    if [ -e "$dest" ]; then
        backup_and_remove "$dest"
    fi

    ln -s "$src" "$dest"
    log "Linked: ${dest} -> ${src}"
}

log "--- Dotfiles Bootstrap ---"
info "Dotfiles directory: ${DOTFILES_DIR}"

mkdir -p "$HOME/.config"

link "${DOTFILES_DIR}/.zshrc"               "$HOME/.zshrc"
link "${DOTFILES_DIR}/.zshrc.local"         "$HOME/.zshrc.local"
link "${DOTFILES_DIR}/.config/dunst"        "$HOME/.config/dunst"
link "${DOTFILES_DIR}/.config/hypr"         "$HOME/.config/hypr"
link "${DOTFILES_DIR}/.config/imv"          "$HOME/.config/imv"
link "${DOTFILES_DIR}/.config/kitty"        "$HOME/.config/kitty"
link "${DOTFILES_DIR}/.config/mimeapps.list" "$HOME/.config/mimeapps.list"
link "${DOTFILES_DIR}/.config/qt6ct"         "$HOME/.config/qt6ct"
link "${DOTFILES_DIR}/.config/rofi"         "$HOME/.config/rofi"
link "${DOTFILES_DIR}/.config/satty"        "$HOME/.config/satty"
link "${DOTFILES_DIR}/.config/starship.toml" "$HOME/.config/starship.toml"
link "${DOTFILES_DIR}/.config/Thunar"       "$HOME/.config/Thunar"
link "${DOTFILES_DIR}/.config/chrome-flags.conf" "$HOME/.config/chrome-flags.conf"
link "${DOTFILES_DIR}/.config/wireplumber/wireplumber.conf.d" "$HOME/.config/wireplumber/wireplumber.conf.d"
link "${DOTFILES_DIR}/.config/waybar"       "$HOME/.config/waybar"
link "${DOTFILES_DIR}/.config/zathura"     "$HOME/.config/zathura"
link "${DOTFILES_DIR}/.config/yazi"        "$HOME/.config/yazi"
link "${DOTFILES_DIR}/.config/atuin"       "$HOME/.config/atuin"
link "${DOTFILES_DIR}/.config/glow"        "$HOME/.config/glow"
link "${DOTFILES_DIR}/.config/forgit"      "$HOME/.config/forgit"
link "${DOTFILES_DIR}/.config/hunk"        "$HOME/.config/hunk"
link "${DOTFILES_DIR}/.config/traefik"     "$HOME/.config/traefik"

mkdir -p "$HOME/.config/systemd/user"
link "${DOTFILES_DIR}/.config/systemd/user/swayosd-server.service" "$HOME/.config/systemd/user/swayosd-server.service"
link "${DOTFILES_DIR}/.config/systemd/user/traefik.service"        "$HOME/.config/systemd/user/traefik.service"

mkdir -p "$HOME/.gnupg"
link "${DOTFILES_DIR}/.gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"

mkdir -p "$HOME/.task"
link "${DOTFILES_DIR}/.task/hooks"          "$HOME/.task/hooks"

log "Dotfiles symlinks set up successfully."
