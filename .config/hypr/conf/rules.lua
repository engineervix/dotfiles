-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Suppress maximize events for all windows
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Example: Make specific apps float
hl.window_rule({
    name  = "float-blueman-manager",
    match = { class = "^(blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name  = "float-nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})
hl.window_rule({
    name  = "float-thunar-progress",
    match = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
    float = true,
})
hl.window_rule({
    name   = "float-center-imv",
    match  = { class = "^(imv)$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name   = "float-center-mpv",
    match  = { class = "^(mpv)$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name   = "float-center-zathura",
    match  = { class = "^(org.pwmt.zathura)$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name   = "float-center-okular",
    match  = { class = "^(org.kde.okular)$" },
    float  = true,
    center = true,
})

-- Window-to-workspace assignments
hl.window_rule({
    name      = "workspace-chrome",
    match     = { class = "^(google-chrome)$" },
    workspace = "1",
})
-- hl.window_rule({ name = "workspace-thunar", match = { class = "^(thunar)$" }, workspace = "2" })
hl.window_rule({
    name      = "workspace-slack",
    match     = { class = "^(Slack)$" },
    workspace = "3",
})
-- hl.window_rule({ name = "workspace-spotify", match = { class = "^(Spotify)$" }, workspace = "3" })
-- hl.window_rule({ name = "workspace-vscode", match = { class = "^(code-url-handler)$" }, workspace = "4" })
-- hl.window_rule({ name = "workspace-vscode2", match = { class = "^(VSCode)$" }, workspace = "4" })
