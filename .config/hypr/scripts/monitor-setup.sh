#!/bin/bash
# Monitor setup: use external (HDMI-A-1) when connected, laptop screen otherwise.
# Runs once at startup then watches Hyprland socket for plug/unplug events.
#
# Uses DPMS off (not monitor disable) for eDP-1 when external is active.
# This avoids a zero-monitor state during hot-unplug, which would leave the
# compositor in a broken state with no usable display.

EXTERNAL="HDMI-A-1"
EXTERNAL_MODE="3840x2160@60,0x0,1.5"
INTERNAL="eDP-1"
INTERNAL_MODE="1920x1200@60,0x0,1.25"

configure_monitors() {
    if hyprctl monitors all -j | grep -q "\"name\": \"$EXTERNAL\""; then
        # External connected: place HDMI-A-1 at origin, move eDP-1 to the right so
        # the two monitors don't overlap in the layout (overlap causes a compositor
        # warning and layout corruption). eDP-1's logical offset = HDMI-A-1 width /
        # scale = 3840 / 1.5 = 2560px. DPMS off keeps eDP-1 alive (no zero-monitor
        # gap) while turning the backlight off.
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_MODE"
        hyprctl keyword monitor "$INTERNAL,1920x1200@60,2560x0,1.25"
        hyprctl dispatch dpms off "$INTERNAL"
        hyprctl dispatch moveworkspacetomonitor 1 "$EXTERNAL"
    else
        # External gone: wake eDP-1, move it back to origin, reset the external rule.
        hyprctl dispatch dpms on "$INTERNAL"
        hyprctl keyword monitor "$INTERNAL,$INTERNAL_MODE"
        hyprctl dispatch moveworkspacetomonitor 1 "$INTERNAL"
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
