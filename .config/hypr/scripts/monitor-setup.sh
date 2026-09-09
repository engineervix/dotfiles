#!/bin/bash
# Monitor setup: use external (HDMI-A-1) when connected, laptop screen otherwise
# (or both, in extended mode — see monitor-lib.sh).
# Runs once at startup then watches Hyprland socket for plug/unplug events.

source "$(dirname "$0")/monitor-lib.sh"

configure_monitors

handle() {
    case $1 in
        monitoradded*|monitorremoved*)
            configure_monitors
            ;;
    esac
}

socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
    | while read -r line; do handle "$line"; done
