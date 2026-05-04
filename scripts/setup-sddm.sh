#!/usr/bin/env bash

# SDDM Setup Script for UK Layout and ML4W Theme
# This script should be run with sudo
#
# Adapted from: https://github.com/mylinuxforwork/dotfiles/blob/master/dotfiles/.config/ml4w/scripts/ml4w-install-sddm

set -e # Exit on error

# 1. Define paths
THEME_DIR="/usr/share/sddm/themes/ml4w"
CONF_DIR="/etc/sddm.conf.d"
WALLPAPER="/usr/share/wallpapers/openSUSEdefault/contents/images/default-dark.png"

echo ":: Starting SDDM Configuration..."

# 2. Configure Keyboard Layout (UK)
echo ":: Configuring UK Keyboard Layout..."
mkdir -p "$CONF_DIR"
echo -e "[Input]\nLayout=gb" | tee "$CONF_DIR/keyboard.conf"

# 3. Install ML4W Theme if not present
if [ ! -d "$THEME_DIR" ]; then
    echo ":: Downloading ML4W SDDM Theme..."
    rm -rf /tmp/ml4w-sddm
    git clone --depth 1 https://github.com/mylinuxforwork/ml4w-sddm.git /tmp/ml4w-sddm
    
    echo ":: Installing theme to $THEME_DIR..."
    mkdir -p "$THEME_DIR"
    cp -rf /tmp/ml4w-sddm/. "$THEME_DIR/"
    rm -rf /tmp/ml4w-sddm
else
    echo ":: ML4W Theme already installed."
fi

# 4. Activate the Theme
echo ":: Activating ML4W Theme..."
echo -e "[Theme]\nCurrent=ml4w" | tee "$CONF_DIR/theme.conf"

# 5. Sync Wallpaper
if [ -f "$WALLPAPER" ]; then
    echo ":: Syncing wallpaper to SDDM theme..."
    mkdir -p "$THEME_DIR/backgrounds"
    cp "$WALLPAPER" "$THEME_DIR/backgrounds/ml4w.jpg"
else
    echo ":: Warning: Default wallpaper not found at $WALLPAPER"
fi

echo ":: SDDM Setup Complete! Please logout or reboot to see changes."
