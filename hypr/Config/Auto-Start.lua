hl.on("hyprland.start", function()
---@diagnostic disable: undefined-global
	hl.exec_cmd(XDPH)	-- Hyprland Portals
	hl.exec_cmd(Polkit)	-- Authentication Agent
	hl.exec_cmd("discord --start-minimized")	-- Discord
	hl.exec_cmd("bash -c 'sleep 2 && flatpak run com.github.zocker_160.SyncThingy'")	-- SyncThingy
	hl.exec_cmd("nm-applet") -- Network Manager Applet
	hl.exec_cmd("waybar")
	hl.exec_cmd("bash -c 'sleep 2 && swaync'")
	hl.exec_cmd("waypaper --random")
end)

