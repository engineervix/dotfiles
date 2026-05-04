#!/bin/sh
# Gracefully close all windows before exiting Hyprland
hyprctl clients -j | jq -r '.[].address' | xargs -I{} hyprctl dispatch closewindow address:{}
sleep 1
hyprctl dispatch exit
