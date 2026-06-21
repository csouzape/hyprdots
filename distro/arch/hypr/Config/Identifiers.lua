-- Apps
MOD = "SUPER"
Terminal = "alacritty"
Browser = "brave"
FileManager = "thunar"
Menu = "rofi -show drun"
Markdown = "obsidian"

-- Environment
Polkit = "systemctl --user start hyprpolkitagent.service"
Config = "[float;size 1800 1000] " .. Terminal .. " nvim ~/.config/hypr/hyprland.lua"
XDPH = "/usr/lib/xdg-desktop-portal-hyprland"
Listener = "~/Scripts/ColorGen/Listener"
Discord = "ELECTRON_OZONE_PLATFORM_HINT=wayland discord"

local ids = {
	mainMod = "SUPER",
	terminal = "alacritty",
	fileManager = "thunar",
	menu = "rofi -show drun",
	browser = "brave",
	markdown = "obsidian",
	wallpaperDir = "/home/carlos/Imagens/Backgrounds",
}

-- Sorteia um wallpaper da pasta e aplica via swaybg.
-- opts.kill = true mata o swaybg atual antes (uso no bind de troca).
function ids.set_random_wallpaper(opts)
	opts = opts or {}
	local handle = io.popen(
		'find "' .. ids.wallpaperDir .. '" -type f \\( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \\)'
	)
	if not handle then return end

	local arquivos = {}
	for linha in handle:lines() do
		table.insert(arquivos, linha)
	end
	handle:close()

	if #arquivos > 0 then
		math.randomseed(os.time())
		local escolhido = arquivos[math.random(#arquivos)]
		local prefix = opts.kill and "pkill swaybg; " or ""
		hl.exec_cmd(prefix .. 'swaybg -i "' .. escolhido .. '" -m fill')
	end
end

return ids
