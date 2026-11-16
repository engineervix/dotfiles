#!/bin/bash
# Open a kitty session (a *.kitty-session file) from anywhere. Bound to
# Super+Shift+T in keybindings.lua.
#
# Why this exists: kitty's own picker (F7 p) opens the session in the kitty
# process you press it in. Pressed inside the quick access terminal (Super+T),
# that process is the quick access one, and the session window is then shown
# and hidden with the panel (kitty#9576). This script always sends the session
# to a NORMAL kitty process over its remote control socket instead.
#
# Steps:
#   1. rofi picks a session file from $KITTY_SESSIONS_DIR (with an optional icon)
#   2. find live kitty processes: skip the quick access panel, skip dead sockets
#   3. session already open in one of them -> ask that process to go to it
#      (kitty can't always raise the window, see misc:focus_on_activate)
#   4. else open it in the first normal kitty; if there is none, start one
#
# Session files must start with new_os_window, so goto_session gives them their
# own OS window. The window class and workspace come from the session file and
# the "kitty-session" window rule in conf/rules.lua.
#
# Needs: rofi, jq, kitten (kitty), timeout, notify-send.
#
# Only `set -u`, on purpose. `set -e` would trip on the `cmd && continue` probes
# below, and `pipefail` could make `tr | grep -q` in is_panel report a panel as
# a normal kitty (grep -q exits early).
#
# Test hooks (environment variables, all optional):
#   KITTY_SESSIONS_DIR      folder with the session files
#   KITTY_SESSION_PICK      session name to use instead of asking rofi
#   KITTY_SESSION_DRY_RUN   print what would happen, change nothing
#   KITTY_SESSION_SOCK_GLOB sockets to scan (default /tmp/kitty-*)
#   KITTY_SESSION_HOST_SOCK socket for a kitty this script has to start
#   KITTY_SESSION_HOST_ARGS extra arguments for that kitty (e.g. --class x)

set -u

dir="${KITTY_SESSIONS_DIR:-$HOME/.local/share/kitty/sessions}"
glob="${KITTY_SESSION_SOCK_GLOB:-/tmp/kitty-*}"
host_sock="${KITTY_SESSION_HOST_SOCK:-${XDG_RUNTIME_DIR:-/tmp}/kitty-host}"

say() { notify-send -a kitty-session "Kitty session" "$1" 2> /dev/null || echo "$1" >&2; }

# 1. pick a session
if [[ -n "${KITTY_SESSION_PICK:-}" ]]; then
    name=$KITTY_SESSION_PICK
else
    shopt -s nullglob
    files=("$dir"/*.kitty-session)
    ((${#files[@]})) || { say "No sessions in $dir"; exit 1; }
    # Row option "name\0icon\x1f<path>" gives an entry an icon (show-icons is on in
    # config.rasi). Icon = optional <name>.svg|png|webp next to the session file.
    name=$(
        for f in "${files[@]}"; do
            n=${f##*/} n=${n%.kitty-session} icon=""
            for ext in svg png webp; do
                [[ -f $dir/$n.$ext ]] && { icon=$dir/$n.$ext; break; }
            done
            if [[ -n $icon ]]; then printf '%s\0icon\x1f%s\n' "$n" "$icon"; else echo "$n"; fi
        # -no-custom: only listed names (and it returns at once on an empty list)
        done | rofi -dmenu -no-custom -i -p session
    )
fi
[[ -n $name ]] || exit 0 # rofi was cancelled
file="$dir/$name.kitty-session"
[[ -f $file ]] || { say "No session file: $name"; exit 1; }

first=$(grep -v -E '^[[:space:]]*(#|$)' "$file" | head -1)
[[ $first == new_os_window* ]] || { say "$name: the first line must be new_os_window"; exit 1; }

# 2. find live, normal kitty processes
# The quick access panel is "kitty +kitten panel ..." and its socket name ends
# in the PID, so the command line tells it apart, even when its own window is gone.
is_panel() {
    local pid=${1##*-}
    # 2>/dev/null comes first so a dead pid's missing /proc file stays quiet
    [[ $pid =~ ^[0-9]+$ ]] && tr '\0' ' ' 2> /dev/null < "/proc/$pid/cmdline" | grep -q '+kitten panel'
}

# prints "<socket><TAB><comma separated session names>" per live normal kitty
live_kittys() {
    local s info
    # $glob is unquoted on purpose: it is a glob pattern
    for s in $glob "$host_sock"; do
        [[ -S $s && -O $s ]] || continue
        is_panel "$s" && continue
        # a dead kitty leaves its socket behind; a live one answers quickly
        info=$(timeout 2 kitten @ --to "unix:$s" ls 2> /dev/null) || continue
        printf '%s\t%s\n' "$s" "$(jq -r '[.[].tabs[].windows[].session_name] | unique | join(",")' <<< "$info")"
    done
}

target="" open_in=""
while IFS=$'\t' read -r sock names; do
    [[ -n $sock ]] || continue
    [[ -n $target ]] || target=$sock
    if [[ ",$names," == *",$name,"* ]]; then
        open_in=$sock
        break
    fi
done < <(live_kittys)

# 3. already open: let that process go to it. 4. else the first normal kitty.
sock=${open_in:-$target}

# no normal kitty at all: start one
if [[ -z $sock ]]; then
    sock=$host_sock
    if [[ -n "${KITTY_SESSION_DRY_RUN:-}" ]]; then
        echo "no normal kitty; would start one on $host_sock"
    else
        # a stale socket from an earlier host kitty blocks the new one (tested)
        [[ -S $host_sock ]] && rm -f "$host_sock"
        # shellcheck disable=SC2086  # the extra arguments are meant to split
        kitty --detach ${KITTY_SESSION_HOST_ARGS:-} --listen-on "unix:$host_sock" > /dev/null 2>&1
        # wait until it answers, not just until the socket file exists
        ready=""
        for _ in $(seq 50); do
            timeout 1 kitten @ --to "unix:$host_sock" ls > /dev/null 2>&1 && { ready=1; break; }
            sleep 0.1
        done
        [[ -n $ready ]] || { say "Could not reach a kitty"; exit 1; }
    fi
fi

if [[ -n "${KITTY_SESSION_DRY_RUN:-}" ]]; then
    echo "would run: kitten @ --to unix:$sock action goto_session $file${open_in:+ (already open there)}"
    exit 0
fi
[[ -z $open_in ]] || say "$name is already open"
exec kitten @ --to "unix:$sock" action goto_session "$file"
