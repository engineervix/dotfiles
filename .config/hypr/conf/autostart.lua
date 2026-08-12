-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/monitor-setup.sh")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/usr/libexec/polkit-kde-authentication-agent-1")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start awatcher.service") -- ActivityWatch (window/idle tracker)
    hl.exec_cmd("/usr/libexec/xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 1 && /usr/libexec/xdg-desktop-portal")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,keyring,ssh")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("udiskie &")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- hl.exec_cmd("wl-paste -p --watch wl-copy") -- Sync primary selection to clipboard (copy on select)

    -- Workspace apps
    hl.exec_cmd("google-chrome")
    hl.exec_cmd("kitty")
    -- hl.exec_cmd("thunar")
    hl.exec_cmd("slack")
    -- hl.exec_cmd("spotify")

    -- Set GTK Dark Mode
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme \"Adwaita-dark\"")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme \"Papirus-Dark\"")
end)
