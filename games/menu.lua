--================================================--
-- Casino Royal
-- Version: 0.5.6
-- File: games/menu.lua
-- Description: Main casino lobby
--================================================--

local display = require("core.display")
local ui = require("core.ui")
local theme = require("core.theme")
local slots = require("games.slots")

local menu = {}

--------------------------------------------------
-- Open lobby
--------------------------------------------------

function menu.open()
    ui.clear()
    display.clear()
    display.border()

    display.center(
        2,
        "CASINO ROYAL",
        theme.get().primary
    )

    display.center(
        3,
        "ATM10 EDITION",
        theme.get().accent
    )

    ui.button(
        "SLOTS",
        4,
        5,
        10,
        2,
        function()
            slots.open()
        end
    )

    ui.button(
        "GAMES",
        4,
        8,
        10,
        2,
        function()
            display.center(
                15,
                "COMING SOON!"
            )
        end
    )

    ui.button(
        "ADMIN",
        4,
        11,
        10,
        2,
        function()
            display.center(
                15,
                "COMING SOON!"
            )
        end
    )
end

return menu
