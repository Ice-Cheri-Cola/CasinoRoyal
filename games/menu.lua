--================================================--
-- Casino Royal
-- Version: 0.3.0
-- File: games/menu.lua
-- Description: Main casino lobby
--================================================--

local display =
    require("core.display")

local ui =
    require("core.ui")

local theme =
    require("core.theme")



local menu = {}



--------------------------------------------------
-- Open Lobby
--------------------------------------------------

function menu.open()

    display.clear()

    display.border()


    display.center(
        2,
        "◇ CASINO ROYAL ◇",
        theme.get().primary
    )


    display.center(
        3,
        "ATM10 EDITION",
        theme.get().accent
    )



    ui.clear()



    ui.button(
        "SLOTS",
        4,
        5,
        10,
        2,

        function()

            print("Opening Slots")

        end

    )



    ui.button(
        "GAMES",
        4,
        8,
        10,
        2,

        function()

            print("Opening Games")

        end

    )



    ui.button(
        "ADMIN",
        4,
        11,
        10,
        2,

        function()

            print("Opening Admin")

        end

    )


end



return menu
