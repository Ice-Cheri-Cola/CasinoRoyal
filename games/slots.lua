--================================================--
-- Casino Royal
-- Slots Game
--================================================--

local display =
    require("core.display")

local ui =
    require("core.ui")

local slots = {}



function slots.open()

    ui.clearButton()
    
    display.clear()

    display.center(
        2,
        "◇ SLOT MACHINE ◇"
    )


    display.center(
        5,
        "[DI]  [7]  [EM]"
    )


    display.center(
        8,
        "GOOD LUCK!"
    )


    ui.button(
        "PLAY",
        5,
        12,
        10,
        3,

        function()

            print("Spinning!")

        end
    )
    
        ui.button(
            "BACK",
            18,
            12,
            10,
            3,

        function()

                local menu = require("games.menu")

            menu.open()

        end
    )


end



return slots
