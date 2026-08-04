local ids = require("Config.Identifiers")

hl.on("hyprland.start", function()
	---@diagnostic disable: undefined-global
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
	hl.exec_cmd("systemctl --user start --no-block xdg-desktop-portal-hyprland")
	hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal")
	hl.exec_cmd(Polkit)
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("waybar")
	hl.exec_cmd("swaync")
	hl.exec_cmd("discord --start-minimized --ozone-platform=wayland")
	hl.exec_cmd("sleep 2 && flatpak run com.github.zocker_160.SyncThingy")
	hl.exec_cmd("sleep 2 && youtube-music")
	hl.exec_cmd("sleep 2 && easyeffects")

	ids.set_random_wallpaper()
end)
