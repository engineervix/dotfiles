#!/usr/bin/env bash
# Switch the font in every config that names one.
# Usage: set-font.sh jetbrains|fantasque|cascadia|maple
set -euo pipefail

case "${1:-}" in
    jetbrains) f="JetBrainsMono Nerd Font"; m="$f Mono" ;;
    fantasque) f="FantasqueSansM Nerd Font"; m="$f Mono" ;;
    cascadia)  f="CaskaydiaCove Nerd Font"; m="$f Mono" ;;
    maple)     f="Maple Mono NF"; m="$f" ;;  # Maple has no separate "Mono" family
    *) echo "usage: ${0##*/} jetbrains|fantasque|cascadia|maple" >&2; exit 1 ;;
esac

cfg="$(cd "$(dirname "$0")/.." && pwd)/.config"
# Matches any font this script can set, so it works from whatever is current.
old='(JetBrainsMono|FantasqueSansM|CaskaydiaCove) Nerd Font( Mono)?|Maple Mono NF'

# kitty wants the fixed-width "Mono" family; the rest take the plain one.
sed -Ei "s/$old/$m/g" "$cfg/kitty/kitty.conf"
sed -Ei "s/$old/$f/g" "$cfg"/{dunst/dunstrc,hypr/hyprlock.conf,rofi/config.rasi,waybar/style.css}

echo "Font set to: $f (kitty: $m). Restart waybar/dunst, reload kitty (ctrl+shift+f5)."
