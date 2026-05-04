---
title: Post-Setup (Hyprland / openSUSE)
parent: Notes
nav_order: 1
---

# Post-Setup Documentation: Hyprland on openSUSE Tumbleweed

This document outlines the architectural changes and configuration logic applied to this workstation on March 22, 2026.

## 1. Keyboard & Localization
- **Change:** System-wide and session-specific keyboard layout set to `en-gb` (`gb`).
- **Mechanism:** Updated `~/.config/hypr/conf/input.conf` and executed `localectl set-x11-keymap gb`.
- **Rationale:** Ensures consistency between the TTY, the SDDM login screen, and the Hyprland Wayland session.

## 2. Security & Login Lifecycle
- **Change:** Disabled auto-login for user `victor`.
- **Mechanism:** Modified `DISPLAYMANAGER_AUTOLOGIN` in `/etc/sysconfig/displaymanager`.
- **Rationale:** Restores the mandatory password prompt at the SDDM login screen, improving system security and allowing for session selection if multiple environments (like IceWM) are present.

## 3. Configuration Architecture (Dotfiles)
- **Change:** Centralized configurations into a `~/dotfiles` repository using a "Symlink-only" approach.
- **Structure:**
  - `~/.config/chrome-flags.conf` -> `~/dotfiles/.config/chrome-flags.conf`
  - `~/.config/dunst` -> `~/dotfiles/.config/dunst`
  - `~/.config/hypr` -> `~/dotfiles/.config/hypr`
  - `~/.config/imv` -> `~/dotfiles/.config/imv`
  - `~/.config/kitty` -> `~/dotfiles/.config/kitty`
  - `~/.config/mimeapps.list` -> `~/dotfiles/.config/mimeapps.list`
  - `~/.config/rofi` -> `~/dotfiles/.config/rofi`
  - `~/.config/starship.toml` -> `~/dotfiles/.config/starship.toml`
  - `~/.config/Thunar` -> `~/dotfiles/.config/Thunar`
  - `~/.config/waybar` -> `~/dotfiles/.config/waybar`
  - `~/.config/wireplumber/wireplumber.conf.d` -> `~/dotfiles/.config/wireplumber/wireplumber.conf.d`
- **Bootstrap:** Run `~/dotfiles/install.sh` to create all symlinks on a fresh machine. It backs up any existing file or directory before replacing it and is safe to re-run.
- **Exclusion:** `~/.config/nvim` remains an independent repository (Git Submodule candidate) as it is already a managed fork of `kickstart.nvim`.
- **Rationale:** Facilitates version control, easy backups, and portability across machines while respecting existing Git hierarchies.

## 4. Modular Hyprland Implementation
- **Change:** Refactored the monolithic `hyprland.conf` into a modular system located in `~/.config/hypr/conf/`.
- **Components:**
  - `monitors.conf`: Hardware-specific display settings.
  - `input.conf`: Keyboard, mouse, and touchpad logic.
  - `environment.conf`: Toolkit and Wayland-specific environment variables.
  - `looks.conf`: Gaps, borders, animations, and shadows.
  - `keybindings.conf`: SUPER-based shortcuts for productivity.
  - `rules.conf`: Window-specific behavior (e.g., floating system dialogs).
  - `autostart.conf`: Lifecycle management for background daemons.

## 5. Productivity Stack
The following Wayland-native tools were configured with functional defaults:
- **Waybar:** Top-mounted status bar for workspace navigation and system monitoring.
- **Hypridle/Hyprlock:** Configured for a 5-minute security lock and 5.5-minute display power-down.
- **Dunst:** Notification management.
- **imv:** Wayland-native image viewer (configured as default in `mimeapps.list`).
- **Rofi (Wayland):** Application launcher (mapped to `SUPER+R`).

## 6. Maintenance Notes
- **Update Command:** Always use `sudo zypper dup` to maintain the rolling-release integrity.
- **Reloading:** Changes to the modular `.conf` files are picked up when Hyprland reloads.
- **Window Rules:** Using new unified `windowrule` syntax for compatibility with Hyprland 0.53+.

## 7. Customization & Wishlist Implementation (March 22, 2026)
Following the initial setup, several refinements were implemented to address specific user requirements:

### 🖥️ Display & Aesthetics
- **Wallpaper:** Migrated `hyprpaper.conf` to the new block syntax (`wallpaper { monitor = ..., path = ... }`) required by hyprpaper v0.7+. Using `monitor =` (empty) as a fallback ensures the wallpaper applies to any connected display — laptop screen or external monitor.
- **SDDM Theme:** Integrated the **ML4W SDDM Theme** for a modern login experience.
  - **Script:** `scripts/setup-sddm.sh` automates the installation and syncs the desktop wallpaper to the login screen.
- **Workspaces:** Updated Waybar to only show active workspaces, reducing visual clutter.

### 📊 Waybar Modules
- **Weather Widget:** Added a custom `weather.sh` script using `wttr.in`. It features Nerd Font icons (󰖙, 󰖐, etc.) and auto-detects location via IP.
- **Network:** Simplified the module to a single icon with `nm-connection-editor` accessible on click.
- **Clock:** Refined format to `HH:MM | Day, Date Month` (omitting year for space) and fixed duplicate month display in tooltips.

### ⌨️ Keybindings & Utilities
- **Image Viewer:** Installed `imv` (Wayland-native) and configured it as the default MIME application for all image types via `mimeapps.list`.
- **Hardware Controls:** Added functional mapping for Volume (`wpctl`) and Brightness (`brightnessctl`) keys.
- **Screenshots:** Integrated `grim` and `slurp`:
  - `Print`: Full screen to file.
  - `Shift+Print`: Area selection to file.
  - `SUPER+Print`: Area selection to clipboard.
- **Clipboard Management:** Configured `wl-paste` with `cliphist`. History is accessible via `SUPER+H` using a Rofi selector.
- **Auto-mount:** Added `udiskie` to the background autostart for automatic USB/Disk mounting.

### 🔔 Notifications
- **Dunst Style:** Applied a custom **Catppuccin Mocha** color scheme to `dunstrc` with rounded corners (10px) and JetBrainsMono Nerd Font support.

### 📁 File Management (Thunar)
- **Terminal Integration:** Fixed the "Open Terminal Here" custom action in Thunar to use `kitty --directory %f` directly, resolving the `exo-open` "TerminalEmulator not found" error.
- **Environment:** Defined `env = TERMINAL,kitty` in `environment.conf` for system-wide consistency.

## 8. Work-Ready Refinements (March 22, 2026)

### 🎨 Theming
- **Rofi:** Added `~/.config/rofi/config.rasi` with a self-contained Catppuccin Mocha theme. Compact dropdown from top of screen, Papirus-Dark icons, JetBrainsMono Nerd Font. Explicitly overrides all element states to prevent rofi's built-in Solarized Light defaults bleeding through.
- **Hyprlock:** Replaced plain dark background with a blurred screenshot of the desktop. Added a live clock and date label. Styled the input field with Catppuccin Mocha colours (mauve accent, yellow for checking, red for failure).
- **Qt Theming:** Replaced deprecated `QT_QPA_PLATFORMTHEME=gtk3` with `qt6ct`. Added missing Wayland Qt env vars: `QT_QPA_PLATFORM=wayland;xcb`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `QT_AUTO_SCREEN_SCALE_FACTOR=1`. Requires `qt6ct` package (`sudo zypper install qt6ct`).

### ⌨️ Keybindings
- **Lock Screen:** Added `SUPER+L` → `hyprlock` for quick screen locking.
- **Window Switcher:** Added `ALT+TAB` → `rofi -show window` for switching between open windows across all workspaces.
- **Resize Mode:** Added `SUPER+W` submap — enter to resize active window with arrow keys, exit with `ESC`/`ENTER`.
- **Workspace Navigation:** Added `SUPER+TAB` (toggle last workspace), `SUPER+SHIFT+left/right` (move window to prev/next workspace).

### 🖥️ Multi-Monitor
- **Layout:** Laptop (eDP-1, 1920x1200) on the left, Philips 4K (HDMI-A-1, 3840x2160) on the right, both at 1.5x scale.
- **Workspace rule:** Workspace 1 prefers HDMI-A-1 when connected, falls back to laptop when not.
- **Lid close:** When external monitor is connected, closing the laptop lid does not suspend (systemd default). When no external monitor is connected, lid close suspends as normal.

### 🔵 Bluetooth
- **Stack:** Installed `bluez` and `blueman`. Enabled `bluetooth.service` via systemd.
- **Autostart:** Added `blueman-applet` to `autostart.conf` for system tray integration.
- **First-time pairing:** Use `blueman-manager` to pair devices.

### 🌐 Default Applications
- **Browser:** Set Google Chrome as default browser for `text/html` and `x-scheme-handler/*` in `mimeapps.list`.
