-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- External monitor — at origin; eDP-1 auto-places to the left when both
-- connected, matching its physical position on the desk.
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "0x0", scale = 1.5 })

-- Laptop screen — `auto-left` places it at 0x0 when alone, to the left of
-- HDMI-A-1 (negative x) when both are active.
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "auto-left", scale = 1.25 })

-- Fallback for any unrecognised monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- External monitor handling (DPMS on/off for eDP-1) is done dynamically by
-- scripts/monitor-setup.sh, which listens for Hyprland monitor events.
-- Workspace-to-monitor assignment is handled by the script at runtime via
-- `hl.dsp.workspace.move` — not hardcoded here — so that workspaces are
-- never stranded on a monitor that no longer exists.
