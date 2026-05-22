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
XDPH = "/usr/lib/xdg-desktop-portal-hyprland"
Listener     = "~/Scripts/ColorGen/Listener"
Discord      = "ELECTRON_OZONE_PLATFORM_HINT=x11 discord"

local ids = {
    mainMod = "SUPER",
    terminal = "alacritty",
    fileManager = "thunar",
    menu = "rofi -show drun",
    browser = "brave",
    markdown = "obsidian",
}

return ids
