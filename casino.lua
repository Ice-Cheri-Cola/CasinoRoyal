--================================================--
-- Casino Royal
-- Version: 0.5.4
-- File: casino.lua
-- Description: Main application controller
--================================================--

local logger = require("core.logger")
local menu = require("games.menu")
local display = require("core.display")
local ui = require("core.ui")

logger.info("Casino Application Starting")

--------------------------------------------------
-- Initialize monitor
--------------------------------------------------

display.init("top")

--------------------------------------------------
-- Load lobby
--------------------------------------------------

menu.open()

--------------------------------------------------
-- Touchscreen loop
--------------------------------------------------

while true do
    local event, side, x, y =
        os.pullEvent("monitor_touch")

    if side == "top" then
        ui.handleTouch(x, y)
    end
end
