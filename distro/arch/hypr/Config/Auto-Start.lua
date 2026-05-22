hl.on("hyprland.start", function()
    ---@diagnostic disable: undefined-global
    hl.exec_cmd(XDPH)
    hl.exec_cmd(Polkit)

    hl.exec_cmd("nm-applet")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("waypaper --random")

    hl.exec_cmd("ELECTRON_OZONE_PLATFORM_HINT=x11 discord --start-minimized")
    hl.exec_cmd("sleep 2 && flatpak run com.github.zocker_160.SyncThingy")
end)