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
        "💎  7  🍒"
    )


    display.center(
        8,
        "GOOD LUCK!"
    )


    ui.button(
        "PLAY",
        8,
        12,
        8,
        2,

        function()

            print("Spinning!")

        end
    )


end



return slots
