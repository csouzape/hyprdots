-- Hyprland principal: carrega módulos separados em Config/
local source = debug.getinfo(1, "S").source
local config_dir = source:sub(2):match("(.*/)") or ""
package.path = config_dir .. "?.lua;" .. config_dir .. "Config/?.lua;" .. package.path

require("Config.Identifiers")
require("Config.Monitors")
require("Config.Auto-Start")
require("Config.Environment")
require("Config.Decorations")
require("Config.Input")
require("Config.Window-Rules")
require("Config.Miscellaneous")
