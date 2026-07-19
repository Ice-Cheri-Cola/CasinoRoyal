--================================================--
-- Casino Royal
-- Version: 0.8.0
-- File: games/slots.lua
-- Description: Animated Royal Slots with credits
--================================================--

local display = require("core.display")
local ui = require("core.ui")

local slots = {}

--------------------------------------------------
-- Game settings
--------------------------------------------------

local balance = 100
local spinCost = 5

local symbols = {
    "[GO]",
    "[DI]",
    "[EM]",
    "[NS]",
    "[DE]"
}

local payouts = {
    ["[GO]"] = 15,
    ["[DI]"] = 25,
    ["[EM]"] = 40,
    ["[NS]"] = 60,
    ["[DE]"] = 100
}

--------------------------------------------------
-- Random setup
--------------------------------------------------

math.randomseed(os.epoch("utc"))

--------------------------------------------------
-- Clear one monitor line
--------------------------------------------------

local function clearLine(y)
    local monitor = peripheral.wrap("top")

    if monitor then
        local width = monitor.getSize()

        monitor.setCursorPos(1, y)
        monitor.write(
            string.rep(" ", width)
        )
    end
end

--------------------------------------------------
-- Random symbol
--------------------------------------------------

local function randomSymbol()
    return symbols[
        math.random(#symbols)
    ]
end

--------------------------------------------------
-- Draw balance
--------------------------------------------------

local function drawBalance()
    clearLine(3)

    display.center(
        3,
        "CREDITS: "
        .. balance
        .. "   COST: "
        .. spinCost
    )
end

--------------------------------------------------
-- Draw message
--------------------------------------------------

local function drawMessage(message)
    clearLine(8)

    display.center(
        8,
        message
    )
end

--------------------------------------------------
-- Draw reels
--------------------------------------------------

local function drawReels(
    reel1,
    reel2,
    reel3
)
    clearLine(5)

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
        drawReels(
            randomSymbol(),
            randomSymbol(),
            randomSymbol()
        )

        sleep(0.08)
    end
end

--------------------------------------------------
-- Count matching symbols
--------------------------------------------------

local function getMatchCount(
    reel1,
    reel2,
    reel3
)
    if reel1 == reel2
    and reel2 == reel3
    then
        return 3
    end

    if reel1 == reel2
    or reel1 == reel3
    or reel2 == reel3
    then
        return 2
    end

    return 0
end

--------------------------------------------------
-- Spin reels
--------------------------------------------------

local function spin()
    if balance < spinCost then
        drawMessage(
            "NOT ENOUGH CREDITS!"
        )

        return
    end

    ui.clearButton()

    balance = balance - spinCost

    drawBalance()
    drawMessage("SPINNING...")

    animateSpin()

    local reel1 = randomSymbol()
    local reel2 = randomSymbol()
    local reel3 = randomSymbol()

    drawReels(
        reel1,
        reel2,
        reel3
    )

    local matches = getMatchCount(
        reel1,
        reel2,
        reel3
    )

    if matches == 3 then
        local prize = payouts[reel1]

        balance = balance + prize

        drawMessage(
            "ROYAL WIN! +"
            .. prize
        )

    elseif matches == 2 then
        local prize = 7

        balance = balance + prize

        drawMessage(
            "PAIR WIN! +"
            .. prize
        )

    else
        drawMessage(
            "TRY AGAIN!"
        )
    end

    drawBalance()
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

    drawBalance()

    drawReels(
        "[GO]",
        "[DI]",
        "[EM]"
    )

    drawMessage(
        "GOOD LUCK!"
    )

    slots.drawButtons()
end

return slots
