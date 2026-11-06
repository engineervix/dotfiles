# Shared by monitor-setup.sh (socket listener) and monitor-mode-toggle.sh
# (manual keybind) so both act on the same state and logic.

EXTERNAL="HDMI-A-1"
INTERNAL="eDP-1"
STATE_FILE="$XDG_RUNTIME_DIR/hypr/monitor-mode"

# Mode is "switch" (default, external replaces laptop screen) or "extended"
# (both active side by side, per the positions in monitors.lua).
get_mode() {
    cat "$STATE_FILE" 2>/dev/null || echo switch
}

external_connected() {
    hyprctl monitors all -j | grep -q "\"name\": \"$EXTERNAL\""
}

# Re-enable eDP-1 if it's currently disabled, via config reload (re-reads
# monitors.lua, where eDP-1 has no disable). Guarded on active-monitor state
# so we skip the reload — and the monitoradded event it fires — when eDP-1 is
# already active.
ensure_internal_active() {
    if ! hyprctl monitors -j | grep -q "\"name\": \"$INTERNAL\""; then
        hyprctl reload
        sleep 0.5
    fi
}

configure_monitors() {
    if external_connected && [[ "$(get_mode)" == "switch" ]]; then
        # Disable eDP-1 entirely so Hyprland moves all workspaces to
        # HDMI-A-1 and no phantom workspace is created on the inactive screen.
        hyprctl eval "hl.monitor({ output = '$INTERNAL', disabled = true })"
        hyprctl eval 'hl.config({ layout = { single_window_aspect_ratio = {1, 1} } })'
    elif external_connected; then
        # Extended mode: make sure eDP-1 is active. It has no disable in
        # monitors.lua; the external monitors' auto-left/auto-right positions
        # put it on the correct side.
        # Re-enabling eDP-1 makes Hyprland return the workspaces it held before
        # switch mode disabled it. Snapshot what's on HDMI-A-1 and move it back,
        # so the external keeps them all and eDP-1 gets a fresh one. No-op when
        # eDP-1 was already active.
        local ws
        ws=$(hyprctl workspaces -j | jq -r ".[] | select(.monitor == \"$EXTERNAL\") | .id")
        ensure_internal_active
        for id in $ws; do
            hyprctl dispatch "hl.dsp.workspace.move({ workspace = $id, monitor = '$EXTERNAL' })"
        done
        # single_window_aspect_ratio is global, not per-monitor — still needs
        # the external-monitor constraint here, else a leftover {0,0} from
        # laptop-only mode stretches lone windows full-width on HDMI-A-1 too.
        # ponytail: laptop's dwindle windows get the same 1:1 constraint as a
        # side effect (Hyprland has no per-output override for this) — upgrade
        # to a real per-monitor fix only if that constraint starts to bother
        # laptop-side single-window layout.
        hyprctl eval 'hl.config({ layout = { single_window_aspect_ratio = {1, 1} } })'
    else
        # External gone: re-enable eDP-1 and reclaim workspaces onto it.
        ensure_internal_active
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
