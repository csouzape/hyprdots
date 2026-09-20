hl.config({ xwayland = { force_zero_scaling = true } })

local function float_rule(name, size, match)
	hl.window_rule({
		name = name,
		float = true,
		center = true,
		size = size,
		match = match,
	})
end

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

hl.window_rule({
	name = "GAMES",
	workspace = "9",
	idle_inhibit = "always",
	opaque = true,
	no_dim = true,
	no_anim = true,
	no_blur = true,
	decorate = false,
	no_shadow = true,
	render_unfocused = true,
	match = { class = "^.*(steam_app_|Sober|gamescope|Lutris|Heroic).*$" },
})

float_rule("FLOAT ONLY", "monitor_w*0.75 monitor_h*0.7", {
	title = "^.*(Vivaldi Settings|OBS Studio Crash Detected|1659040).*$",
})

float_rule("FLOAT SMALL", "monitor_w*0.2 monitor_h*0.35", {
	class = "^(blueman-manager|com.network.manager|.*pupgui2|.*share-picker|solaar)$",
})

float_rule("RENAME DIALOG", "monitor_w*0.35 monitor_h*0.15", {
	title = "^.*(Insira o novo nome).*$",
})

float_rule("FLOAT MEDIUM", "monitor_w*0.45 monitor_h*0.5", {
	class = "^.*(pavucontrol-qt|lsfg-vk|xdg-|Update|org.kde.ark|easyeffects).*$",
})

float_rule("FLOAT LARGE", "monitor_w*0.5 monitor_h*0.58", {
	class = "^(.*dolphin.*|qimgv|timeshift-gtk)$",
})

float_rule("LOCALSEND", "monitor_w*0.5 monitor_h*0.7", {
	class = "org.localsend.localsend_app",
})

float_rule("MPV", "monitor_w*0.7 monitor_h*0.58", {
	class = "^mpv$",
})

float_rule("BITWARDEN", "monitor_w*0.25 monitor_h*0.6", {
	class = "^brave-nngceckbapebfimnlniiiahkandclblb-Default$",
})

float_rule("FLOAT-0.7x0.7", "monitor_w*0.7 monitor_h*0.7", {
	class = "^(spotify|imv|org.pulseaudio.pavucontrol)$",
})

float_rule("OBS", "monitor_w*0.75 monitor_h*0.80", {
	class = "com.obsproject.Studio",
})

float_rule("Waypaper", "monitor_w*0.4 monitor_h*0.6", {
	class = "waypaper",
})

float_rule("ZED-SETTINGS", "monitor_w*0.7 monitor_h*0.7", {
	class = "^dev.zed.Zed$",
	title = "^Zed — Settings$",
})

float_rule("OBSIDIAN-SETTINGS", "monitor_w*0.6 monitor_h*0.75", {
	class = "^md.obsidian.Obsidian$",
	title = "^Configurações.*Obsidian.*$",
})

float_rule("BRAVE LOGIN GOOGLE", "monitor_w*0.45 monitor_h*0.5", {
	class = "^brave%-browser$",
	title = "^Fazer login nas Contas do Google %- Brave$",
})

float_rule("HEROIC-DEFAULT", "monitor_w*0.8 monitor_h*0.8", {
	class = "^(heroic|com.heroicgameslauncher.hgl)$",
	title = "^Heroic Games Launcher$",
})

float_rule("STEAM-FRIENDS", "monitor_w*0.2 monitor_h*0.7", {
	class = "^steam$",
	title = "^Lista de amigos$",
})

float_rule("STEAM-SETTINGS", "monitor_w*0.7 monitor_h*0.8", {
	class = "^steam$",
	title = "^Steam — Configurações$",
})

float_rule("STEAM-DEFAULT", "monitor_w*0.8 monitor_h*0.8", {
	class = "^steam$",
	title = "^Steam$",
})

float_rule("STEAM-RECORDINGS", "monitor_w*0.5 monitor_h*0.7", {
	class = "^steam$",
	title = "^Gravações e capturas de tela$",
})
