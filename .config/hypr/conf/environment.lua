-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("GTK_ICON_THEME", "Papirus-Dark")
hl.env("TERMINAL", "kitty")

-- LibreOffice — use GTK3 backend (Wayland-native, avoids X11 error)
hl.env("SAL_USE_VCLPLUGIN", "gtk3")
