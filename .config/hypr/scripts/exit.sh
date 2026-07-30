#!/bin/sh
# Gracefully close all windows before exiting Hyprland
hyprctl clients -j | jq -r '.[].address' | xargs -I{} hyprctl dispatch "hl.dsp.window.close({ window = 'address:{}' })"
sleep 1
hyprctl dispatch 'hl.dsp.exit()'
