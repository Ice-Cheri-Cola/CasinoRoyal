--================================================--
-- Casino Royal
-- Version: 4.1.0
-- File: games/slots.lua
-- Description: Animated Royal Slots
--================================================--

local display =
    require("core.display")

local ui =
    require("core.ui")

local bank =
    require("core.bank")

local slots = {}

--------------------------------------------------
-- Game settings
--------------------------------------------------

local spinCost =
    5

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

math.randomseed(
    os.epoch("utc")
)

--------------------------------------------------
-- Clear one monitor line
--------------------------------------------------

local function clearLine(y)
    local monitor =
        peripheral.wrap("top")

    if monitor == nil then
        return
    end

    local width =
        monitor.getSize()

    monitor.setCursorPos(
        1,
        y
    )

    monitor.write(
        string.rep(
            " ",
            width
        )
    )
end

--------------------------------------------------
-- Random symbol
--------------------------------------------------

local function randomSymbol()
    return symbols[
        math.random(
            #symbols
        )
    ]
end

--------------------------------------------------
-- Draw balance
--------------------------------------------------

local function drawBalance()
    clearLine(3)
    clearLine(4)

    display.center(
        3,
        "Credits: "
        .. tostring(
            bank.getBalance()
        )
    )

    display.center(
        4,
        "Cost: "
        .. tostring(spinCost)
    )
end

--------------------------------------------------
-- Draw message
--------------------------------------------------

local function drawMessage(message)
    clearLine(8)

    display.center(
        8,
        tostring(message)
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
-- Count matches
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
-- Process payout
--------------------------------------------------

local function payPrize(
    prize,
    message
)
    local paid, problem =
        bank.add(
            prize,
            "slots",
            message
        )

    if not paid then
        drawMessage(
            problem
            or "PAYOUT FAILED"
        )

        return false
    end

    return true
end

--------------------------------------------------
-- Spin reels
--------------------------------------------------

local function spin()
    ui.clearButton()

    drawMessage(
        "CHECKING ACCOUNT..."
    )

    local refreshed, refreshProblem =
        bank.refreshBalance()

    if not refreshed then
        drawMessage(
            refreshProblem
            or "BANK OFFLINE"
        )

        slots.drawButtons()

        return
    end

    if not bank.canAfford(
        spinCost
    )
    then
        drawMessage(
            "NOT ENOUGH CREDITS!"
        )

        slots.drawButtons()

        return
    end

    local spent, spendProblem =
        bank.spend(
            spinCost,
            "slots",
            "Royal Slots wager"
        )

    if not spent then
        drawMessage(
            spendProblem
            or "WAGER FAILED"
        )

        drawBalance()
        slots.drawButtons()

        return
    end

    bank.recordGame(
        "slots"
    )

    drawBalance()

    drawMessage(
        "SPINNING..."
    )

    animateSpin()

    local reel1 =
        randomSymbol()

    local reel2 =
        randomSymbol()

    local reel3 =
        randomSymbol()

    drawReels(
        reel1,
        reel2,
        reel3
    )

    local matches =
        getMatchCount(
            reel1,
            reel2,
            reel3
        )

    if matches == 3 then
        local prize =
            payouts[reel1]

        local paid =
            payPrize(
                prize,
                "Royal Slots jackpot"
            )

        if paid then
            drawMessage(
                "ROYAL WIN! +"
                .. tostring(prize)
            )
        end

    elseif matches == 2 then
        local prize =
            7

        local paid =
            payPrize(
                prize,
                "Royal Slots pair win"
            )

        if paid then
            drawMessage(
                "PAIR WIN! +"
                .. tostring(prize)
            )
        end

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
    display.border()

    display.center(
        2,
        "ROYAL SLOTS"
    )

    local refreshed, problem =
        bank.refreshBalance()

    if not refreshed then
        drawMessage(
            problem
            or "BANK OFFLINE"
        )
    end

    drawBalance()

    drawReels(
        "[GO]",
        "[DI]",
        "[EM]"
    )

    if refreshed then
        drawMessage(
            "GOOD LUCK!"
        )
    end

    slots.drawButtons()
end

--------------------------------------------------
-- Return module
--------------------------------------------------

return slots
