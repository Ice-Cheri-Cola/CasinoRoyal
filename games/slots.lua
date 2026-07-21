--================================================--
-- Casino Royal
-- File: games/slots.lua
-- Description: Playable Royal Slots
--================================================--

local slots = {}

local display = require("core.display")
local gameui = require("core.gameui")
local ui = require("core.ui")
local theme = require("core.theme")
local wallet = require("core.wallet")

local handlers = {}
local betOptions = { 1, 5, 10, 25, 50, 100 }
local betIndex = 3
local message = "GOOD LUCK!"
local messageColor = colors.white
local spinning = false

local symbols = {
    { text = "CHR", color = colors.red, weight = 30, multiplier = 5 },
    { text = "LEM", color = colors.yellow, weight = 25, multiplier = 6 },
    { text = "BEL", color = colors.orange, weight = 18, multiplier = 8 },
    { text = "BAR", color = colors.white, weight = 14, multiplier = 10 },
    { text = "777", color = colors.cyan, weight = 8, multiplier = 20 },
    { text = "DMD", color = colors.lightBlue, weight = 5, multiplier = 35 }
}

local reels = {
    symbols[1],
    symbols[4],
    symbols[5]
}

math.randomseed(os.epoch("utc"))
math.random()
math.random()
math.random()

local function currentBet()
    return betOptions[betIndex]
end

local function randomSymbol()
    local total = 0
    for _, symbol in ipairs(symbols) do
        total = total + symbol.weight
    end

    local roll = math.random(total)
    local running = 0

    for _, symbol in ipairs(symbols) do
        running = running + symbol.weight
        if roll <= running then
            return symbol
        end
    end

    return symbols[1]
end

local function drawStatus(y)
    local width = display.size()
    local text = tostring(message or "")
    if #text > width - 4 then
        text = text:sub(1, width - 4)
    end
    display.center(y, text, messageColor)
end

local function drawScreen()
    ui.clear()
    display.clear()

    local width, height = display.size()
    local colorset = theme.get()

    gameui.header("ROYAL SLOTS", "LUCK FAVORS THE BOLD")
    gameui.labelValue(5, "CREDITS", wallet.getBalance(), colors.yellow)
    gameui.labelValue(7, "BET", currentBet(), colors.yellow)
    gameui.reels(9, reels)

    local smallButtonWidth = math.max(5, math.floor((width - 10) / 2))
    local leftX = 3
    local rightX = width - smallButtonWidth - 2
    local controlsY = math.min(height - 7, 14)

    ui.button("bet_down", "- BET", leftX, controlsY, smallButtonWidth, 2, function()
        if spinning then return end
        betIndex = math.max(1, betIndex - 1)
        message = "BET: " .. currentBet()
        messageColor = colors.white
        drawScreen()
    end)

    ui.button("bet_up", "BET +", rightX, controlsY, smallButtonWidth, 2, function()
        if spinning then return end
        betIndex = math.min(#betOptions, betIndex + 1)
        message = "BET: " .. currentBet()
        messageColor = colors.white
        drawScreen()
    end)

    local spinY = controlsY + 3
    ui.button(
        "spin",
        spinning and "SPINNING" or "SPIN",
        3,
        spinY,
        width - 4,
        2,
        function()
            if spinning then return end

            local bet = currentBet()
            local spent, problem = wallet.spend(bet)
            if not spent then
                message = problem or "WAGER FAILED"
                messageColor = colors.red
                drawScreen()
                return
            end

            spinning = true
            message = "SPINNING..."
            messageColor = colors.yellow
            drawScreen()

            local final = { randomSymbol(), randomSymbol(), randomSymbol() }
            local stopFrames = { 12, 18, 24 }

            for frame = 1, stopFrames[3] do
                for reel = 1, 3 do
                    if frame <= stopFrames[reel] then
                        reels[reel] = randomSymbol()
                    else
                        reels[reel] = final[reel]
                    end
                end

                gameui.reels(9, reels)
                sleep(0.07)
            end

            reels = final

            local prize = 0
            if reels[1].text == reels[2].text and reels[2].text == reels[3].text then
                prize = bet * reels[1].multiplier
                message = "ROYAL WIN! +" .. prize
                messageColor = colors.lime
            elseif reels[1].text == reels[2].text
                or reels[1].text == reels[3].text
                or reels[2].text == reels[3].text then
                prize = bet * 2
                message = "PAIR WIN! +" .. prize
                messageColor = colors.lime
            else
                message = "TRY AGAIN!"
                messageColor = colors.lightGray
            end

            if prize > 0 then
                local paid, payProblem = wallet.add(prize)
                if not paid then
                    message = payProblem or "PAYOUT FAILED"
                    messageColor = colors.red
                end
            end

            spinning = false
            drawScreen()
        end,
        colorset.primary,
        colors.white
    )

    local backY = spinY + 3
    if backY <= height - 1 then
        ui.button(
            "back",
            "BACK",
            math.max(3, math.floor(width / 2) - 4),
            backY,
            9,
            1,
            function()
                if not spinning and handlers.back then
                    handlers.back()
                end
            end,
            colors.gray,
            colors.white
        )
    end

    local statusY = math.min(height - 2, backY + 2)
    if statusY > backY then
        drawStatus(statusY)
    end
end

function slots.setBalance()
    -- Kept for compatibility. The slot screen now reads the wallet directly.
end

function slots.setHandlers(newHandlers)
    handlers = newHandlers or {}
end

function slots.open()
    spinning = false
    message = "GOOD LUCK!"
    messageColor = colors.white
    drawScreen()
end

return slots
