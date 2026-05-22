-- Configurações de entrada e dispositivos
hl.config({
    input = {
        kb_layout = "br",
        kb_variant = "abnt2",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
})

-- Bindings do Hyprland usando identificadores globais
local ids = require("Config.Identifiers")
local mainMod = ids.mainMod
local terminal = ids.terminal
local fileManager = ids.fileManager
local menu = ids.menu
local browser = ids.browser
local markdown = ids.markdown

-- aplicações
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(markdown))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

-- janelas
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

-- mídia / utilitários
hl.bind("KP_Prior", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("bash -c 'killall waybar && waybar'"))

hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper --random"))

-- desligar / sair
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

-- capturas de tela
hl.bind(
    "Print",
    hl.dsp.exec_cmd(
        'grim -g "$(slurp -b 00000044 -c ffffff00)" - | tee /home/carlos/Imagens/Capturas\\ de\\ tela/$(date +%s).png | wl-copy'
    )
)
hl.bind(
    "SHIFT + Print",
    hl.dsp.exec_cmd('grim -g "$(slurp -o)" - | tee /home/carlos/Imagens/Capturas\\ de\\ tela/$(date +%s).png | wl-copy')
)

-- foco e movimentação
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- workspaces especiais
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
