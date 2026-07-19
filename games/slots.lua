--================================================--
-- Casino Royal
-- Version: 0.7.0
-- File: games/slots.lua
-- Description: Royal Slots game
--================================================--

local display = require("core.display")
local ui = require("core.ui")

local slots = {}

--------------------------------------------------
-- Slot symbols
--------------------------------------------------

local symbols = {
    "[GO]",
    "[DI]",
    "[EM]",
    "[NS]",
    "[DE]"
}

--------------------------------------------------
-- Random setup
--------------------------------------------------

math.randomseed(os.epoch("utc"))

--------------------------------------------------
-- Select a random symbol
--------------------------------------------------

local function randomSymbol()
    return symbols[
        math.random(#symbols)
    ]
end

--------------------------------------------------
-- Draw reels
--------------------------------------------------

local function drawReels(
    reel1,
    reel2,
    reel3
)
    display.center(
        5,
        reel1
        .. " "
        .. reel2
        .. " "
        .. reel3
    )
end

--------------------------------------------------
-- Spin animation
--------------------------------------------------

local function animateSpin()
    for frame = 1, 12 do
        local reel1 = randomSymbol()
        local reel2 = randomSymbol()
        local reel3 = randomSymbol()

        drawReels(
            reel1,
            reel2,
            reel3
        )

        sleep(0.08)
    end
end

--------------------------------------------------
-- Spin the reels
--------------------------------------------------

local function spin()
    ui.clearButton()

    display.center(
        8,
        "SPINNING...   "
    )

    animateSpin()

    local reel1 = randomSymbol()
    local reel2 = randomSymbol()
    local reel3 = randomSymbol()

    drawReels(
        reel1,
        reel2,
        reel3
    )

    if reel1 == reel2
    and reel2 == reel3
    then
        display.center(
            8,
            "ROYAL WIN!   "
        )
    else
        display.center(
            8,
            "TRY AGAIN!   "
        )
    end

    slots.drawButtons()
end

--------------------------------------------------
-- Draw buttons
--------------------------------------------------

function slots.drawButtons()
    ui.clearButton()

    ui.button(
        "SPIN",
        5,
        12,
        10,
        3,
        function()
            spin()
        end
    )

    ui.button(
        "BACK",
        18,
        12,
        10,
        3,
        function()
            local menu =
                require("games.menu")

            menu.open()
        end
    )
end

--------------------------------------------------
-- Open slots
--------------------------------------------------

function slots.open()
    ui.clearButton()
    display.clear()

    display.center(
        2,
        "ROYAL SLOTS"
    )

    drawReels(
        "[GO]",
        "[DI]",
        "[EM]"
    )

    display.center(
        8,
        "GOOD LUCK!"
    )

    slots.drawButtons()
end

return slots
