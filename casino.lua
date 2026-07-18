--================================================--
-- Casino Royal
-- Version: 0.3.0
-- File: casino.lua
-- Description: Main application controller
--================================================--


local logger =
    require("core.logger")


local menu =
    require("games.menu")


local hardware =
    require("core.hardware")



logger.info(
    "Casino Application Starting"
)



--------------------------------------------------
-- Load Lobby
--------------------------------------------------

menu.open()



--------------------------------------------------
-- Touchscreen Loop
--------------------------------------------------

local monitor =
    peripheral.wrap("top")



while true do

    local event,
          side,
          x,
          y =
        os.pullEvent("monitor_touch")



    if side == "top" then

        local ui =
            require("core.ui")


        ui.handleTouch(
            x,
            y
        )

    end

end
