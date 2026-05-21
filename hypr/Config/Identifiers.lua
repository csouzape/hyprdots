-- Apps
MOD = "SUPER"
Terminal = "alacritty"
Browser = "brave"
FileManager = "thunar"
Menu = "rofi -show drun"
Markdown = "obsidian"

-- Environment
Polkit       = "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
Config       = "[float;size 1800 1000] " .. Terminal .. " nvim ~/.config/hypr/hyprland.lua"
XDPH         = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
Listener     = "~/Scripts/ColorGen/Listener"

local ids = {
    mainMod = "SUPER",
    terminal = "alacritty",
    fileManager = "thunar",
    menu = "rofi -show drun",
    browser = "brave",
    markdown = "obsidian",
}

return ids
