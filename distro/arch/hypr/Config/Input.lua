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
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("bash -c 'killall waybar && waybar'"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -r"))
hl.bind(mainMod .. " + SHIFT + W", function()
    local pasta = "/home/carlos/Imagens/Backgrounds"
    local handle = io.popen('find "' .. pasta .. '" -type f \\( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \\)')
    local arquivos = {}
    for linha in handle:lines() do
        table.insert(arquivos, linha)
    end
    handle:close()

    if #arquivos > 0 then
        math.randomseed(os.time())
        local escolhido = arquivos[math.random(#arquivos)]
        hl.exec_cmd('pkill swaybg; swaybg -i "' .. escolhido .. '" -m fill')
    end
end)



-- desligar / sair
hl.bind(
    mainMod .. " + SHIFT + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

-- capturas de tela
hl.bind(
    "Print",
    hl.dsp.exec_cmd(
        "bash -c 'grim -g \"$(slurp -b 00000044 -c ffffff00)\" - | tee /home/carlos/Imagens/Capturas\\ de\\ tela/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy'"
    )
)
hl.bind(
    "SHIFT + Print",
    hl.dsp.exec_cmd("bash -c 'grim -g \"$(slurp -o)\" - | tee /home/carlos/Imagens/Capturas\\ de\\ tela/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy'")
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

hl.bind(mainMod .. " + L", hl.dsp.layout("splitratio 0.05"), { repeating = true })
hl.bind(mainMod .. " + H", hl.dsp.layout("splitratio -0.05"), { repeating = true })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
