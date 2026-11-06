-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Laptop screen is the fixed anchor at 0x0. Each external monitor places
-- itself on the side of the laptop that matches its desk at that location.
-- Hyprland places explicit positions first, then auto-* ones relative to them.
-- When an external monitor is the only active output (switch mode), its
-- direction is ignored and it lands at 0x0.

-- External monitors — matched by description since both locations use
-- HDMI-A-1.
-- Primary: Philips 4K — to the right of the laptop.
hl.monitor({
	output = "desc:Philips Consumer Electronics Company PHL 278E1 0x00000A6A",
	mode = "3840x2160@60",
	position = "auto-right",
	scale = 1.5,
})
-- Secondary: HP EliteDisplay E240 1080p — to the left of the laptop.
hl.monitor({ output = "desc:Hewlett Packard HP E240 CNK7150MC5", mode = "1920x1080@60", position = "auto-left", scale = 1 })

-- Laptop screen
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1.25 })

-- Fallback for any unrecognised monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- External monitor handling (DPMS on/off for eDP-1) is done dynamically by
-- scripts/monitor-setup.sh, which listens for Hyprland monitor events.
-- Workspace-to-monitor assignment is handled by the script at runtime via
-- `hl.dsp.workspace.move` — not hardcoded here — so that workspaces are
-- never stranded on a monitor that no longer exists.
