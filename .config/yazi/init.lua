-- Show the hovered file's modified time in the status bar.
-- Pattern (Status:children_add): https://yazi-rs.github.io/docs/tips#user-group-in-status
-- Hovered file:                  https://yazi-rs.github.io/docs/plugins/context#tab-folder.hovered
-- File mtime (cha.mtime):        https://yazi-rs.github.io/docs/plugins/types#cha.mtime
Status:children_add(function()
	local h = cx.active.current.hovered
	local t = h and math.floor(h.cha.mtime or 0) or 0
	if t == 0 then
		return ui.Line {}
	end
	return ui.Line { ui.Span(os.date("%Y-%m-%d %H:%M", t)):fg("blue"), ui.Span(" ") }
end, 500, Status.RIGHT)
