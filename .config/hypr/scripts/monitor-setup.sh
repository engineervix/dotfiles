#!/bin/bash
# Monitor setup: use external (HDMI-A-1) when connected, laptop screen otherwise.
# Runs once at startup then watches Hyprland socket for plug/unplug events.
#
# Disables eDP-1 (not just DPMS) when external is active — Hyprland moves all
# workspaces to HDMI-A-1 automatically, so no manual moveworkspacetomonitor needed.

EXTERNAL="HDMI-A-1"
INTERNAL="eDP-1"
INTERNAL_MODE="1920x1200@60,0x0,1.25"

configure_monitors() {
    if hyprctl monitors all -j | grep -q "\"name\": \"$EXTERNAL\""; then
        # External connected: disable eDP-1 entirely so Hyprland moves all workspaces
        # to HDMI-A-1 and no phantom workspace is created on the inactive screen.
        hyprctl keyword monitor "$INTERNAL,disable"
        hyprctl keyword layout:single_window_aspect_ratio "1 1"
    else
        # External gone: re-enable eDP-1 at origin, reset external rule,
        # disable aspect ratio constraint.
        hyprctl keyword monitor "$INTERNAL,$INTERNAL_MODE"
        hyprctl keyword layout:single_window_aspect_ratio "0 0"
        hyprctl keyword monitor "$EXTERNAL,preferred,auto,1.5"
    fi
}

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
