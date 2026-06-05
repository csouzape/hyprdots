hl.on("hyprland.start", function()
	---@diagnostic disable: undefined-global
	hl.exec_cmd(XDPH)
	hl.exec_cmd(Polkit)
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("waybar")
	hl.exec_cmd("swaync")
	hl.exec_cmd("discord --start-minimized --ozone-platform=wayland")
	hl.exec_cmd("sleep 2 && flatpak run com.github.zocker_160.SyncThingy")

	local pasta = "/home/carlos/Imagens/Backgrounds"
	local handle = io.popen(
		'find "' .. pasta .. '" -type f \\( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \\)'
	)
	local arquivos = {}
	for linha in handle:lines() do
		table.insert(arquivos, linha)
	end
	handle:close()

	if #arquivos > 0 then
		math.randomseed(os.time())
		local escolhido = arquivos[math.random(#arquivos)]
		hl.exec_cmd('swaybg -i "' .. escolhido .. '" -m fill')
	end
end)
