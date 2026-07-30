-- HYPRLAND CONFIGURATION (Lua)
-- Migrated from hyprlang; see LUA-MIGRATION.md. Companion tools (hypridle,
-- hyprlock, hyprpaper) stay on hyprlang for now — only the compositor moved.

require("conf/environment")
require("conf/monitors")
require("conf/input")
require("conf/looks")
require("conf/keybindings")
require("conf/autostart")

-- Window Rules (Basic)
require("conf/rules")
require("conf/custom")
