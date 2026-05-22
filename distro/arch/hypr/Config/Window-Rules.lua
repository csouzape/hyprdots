-- Regras de janelas e configurações Xwayland
hl.config({ xwayland = { force_zero_scaling = true } })

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

-- [ SCREENSHARE ]
hl.window_rule({
    name = "SCREENSHARE",
    no_screen_share = true,
    match = { class = "^(discord|vivaldi-stable|steam)$" },
})

-- [ GAMES ]
hl.window_rule({
    name             = "GAMES",
    workspace        = "9 silent",
    idle_inhibit     = "always",
    opaque           = true,
    no_dim           = true,
    no_anim          = true,
    no_blur          = true,
    decorate         = false,
    no_shadow        = true,
    render_unfocused = true,
    match = { class = "^.*(steam_app_|cs2|RimWorldLinux|osu!|Sober|gamescope).*$" },
})

-- [ FLOAT RULES ]
hl.window_rule({
    name = "FLOAT ONLY",
    float = true,
    center = true,
    match = { title = "^.*(Vivaldi Settings|OBS Studio Crash Detected|1659040).*$" },
    max_size = "monitor_w*0.75 monitor_h*0.7",
})

hl.window_rule({
    name = "FLOAT SMALL",
    float = true,
    center = true,
    size = "monitor_w*0.2 monitor_h*0.35",
    match = { class = "^(blueman-manager|com.network.manager|.*pupgui2|.*share-picker|solaar)$" },
})

hl.window_rule({
    name = "RENAME DIALOG",
    float = true,
    center = true,
    size = "monitor_w*0.35 monitor_h*0.15",
    match = { title = "^.*(Insira o novo nome).*$" },
})

hl.window_rule({
    name = "FLOAT MEDIUM",
    float = true,
    center = true,
    size = "monitor_w*0.45 monitor_h*0.5",
    match = { class = "^.*(pavucontrol-qt|lsfg-vk|xdg-|Update|org.kde.ark|easyeffects).*$" },
})

hl.window_rule({
    name = "FLOAT LARGE",
    float = true,
    center = true,
    size = "monitor_w*0.5 monitor_h*0.58",
    match = { class = "^(.*dolphin.*|qimgv|mpv|timeshift-gtk)$" },
})

hl.window_rule({
    name = "LOCALSEND",
    float = true,
    center = true,
    size = "monitor_w*0.5 monitor_h*0.7",
    match = { class = "^(localsend|LocalSend)$" },
})

