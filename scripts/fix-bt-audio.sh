#!/bin/bash
# Bluetooth speaker connects but no sound (wireplumber fails to create
# the a2dp-sink node, card profile stuck on "off"). Restart the audio
# stack, reconnect, force a2dp-sink, and make it the default sink.
#
# Usage: fix-bt-audio.sh [MAC]
#   MAC optional - defaults to the first connected bluez card.

set -euo pipefail

mac="${1:-}"
if [[ -z "$mac" ]]; then
    mac=$(bluetoothctl devices Connected | awk '{print $2; exit}')
fi

if [[ -z "$mac" ]]; then
    notify-send "BT audio fix" "No connected bluetooth device found"
    exit 1
fi

systemctl --user restart pipewire wireplumber pipewire-pulse
sleep 2

bluetoothctl disconnect "$mac" >/dev/null 2>&1 || true
sleep 1
bluetoothctl connect "$mac"
sleep 2

id="${mac//:/_}"
pactl set-card-profile "bluez_card.$id" a2dp-sink
pactl set-default-sink "bluez_output.$id.1"

name=$(bluetoothctl info "$mac" | awk -F': ' '/Alias/{print $2}')
notify-send "BT audio fix" "${name:-$mac} set as default sink"
