#!/bin/bash
# Flip between switch mode (external replaces laptop screen) and extended
# mode (both active). Bound to a key in keybindings.lua.

source "$(dirname "$0")/monitor-lib.sh"

if [[ "$(get_mode)" == "extended" ]]; then
    echo switch > "$STATE_FILE"
    notify-send "Monitors" "Switch mode"
else
    echo extended > "$STATE_FILE"
    notify-send "Monitors" "Extended desktop"
fi

configure_monitors
