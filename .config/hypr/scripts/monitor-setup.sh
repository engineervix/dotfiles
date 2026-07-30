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
        hyprctl eval "hl.monitor({ output = '$INTERNAL', disabled = true })"
        hyprctl eval 'hl.config({ layout = { single_window_aspect_ratio = {1, 1} } })'
    else
        # External gone: re-enable eDP-1 via config reload (re-reads monitors.lua,
        # where eDP-1 has no disable). Under the Lua config, `hl.monitor({disabled
        # = false, ...})` CAN re-enable a disabled output live (unlike old hyprlang
        # `keyword monitor`, which was a silent no-op) — see MonitorRuleManager's
        # ensureMonitorStatus(). Kept as reload for now since it's the
        # already-proven path; switching to a direct hl.monitor() call is a
        # possible future simplification. Guard the reload with `hyprctl monitors`
        # (active outputs only): if eDP-1 is already active we skip it, so the
        # monitoradded event the reload itself fires doesn't reload again.
        if ! hyprctl monitors -j | grep -q "\"name\": \"$INTERNAL\""; then
            hyprctl reload
            sleep 0.5
        fi
        hyprctl eval 'hl.config({ layout = { single_window_aspect_ratio = {0, 0} } })'
        hyprctl dispatch "hl.dsp.dpms({ action = 'on', monitor = '$INTERNAL' })"
        # Pull every workspace (incl. any stranded on the FALLBACK headless
        # output created during the zero-monitor gap) back onto eDP-1, focus it.
        hyprctl workspaces -j | jq -r '.[].id' | while read -r ws; do
            hyprctl dispatch "hl.dsp.workspace.move({ workspace = $ws, monitor = '$INTERNAL' })"
        done
        hyprctl dispatch "hl.dsp.focus({ monitor = '$INTERNAL' })"
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
