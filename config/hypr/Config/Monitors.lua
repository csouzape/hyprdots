local function setup_monitor(output, scale, mode)
    hl.monitor({
        output = output,
        mode = mode or "1920x1080@60",
        position = "auto",
        scale = scale,
        vrr = 2,
    })
end

setup_monitor("HDMI-A-1", 1)
setup_monitor("eDP-1", 1.25)

hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1" })
