#!/bin/bash
# Monitor setup: use external (HDMI-A-1) when connected, laptop screen otherwise.
# Runs once at startup then watches Hyprland socket for plug/unplug events.

EXTERNAL="HDMI-A-1"
EXTERNAL_MODE="3840x2160@60,0x0,1.5"
INTERNAL="eDP-1"
INTERNAL_MODE="1920x1200@60,0x0,1.25"

configure_monitors() {
    if hyprctl monitors all -j | grep -q "\"name\": \"$EXTERNAL\""; then
        hyprctl keyword monitor "$INTERNAL,disable"
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_MODE"
        hyprctl keyword layout:single_window_aspect_ratio "1 1"
    else
        hyprctl keyword monitor "$INTERNAL,$INTERNAL_MODE"
        hyprctl keyword layout:single_window_aspect_ratio "0 0"
    fi
}

configure_monitors

socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
    | while read -r line; do
        case "$line" in
            monitoradded*|monitorremoved*)
                configure_monitors
                ;;
        esac
    done
