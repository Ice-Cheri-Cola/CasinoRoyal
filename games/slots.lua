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
local hardware = require("core.hardware")

local handlers = {}
local betOptions = { 1, 5, 10, 25, 50, 100 }
local betIndex = 3
local message = "GOOD LUCK!"
local messageColor = colors.white
local spinning = false
local celebrationTitle = nil
local celebrationColor = nil

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

local function speakerNote(instrument, pitch, volume)
    local speaker = hardware.getSpeaker()
    if not speaker or not speaker.playNote then return end
    pcall(speaker.playNote, instrument or "bell", volume or 1, pitch or 12)
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

local function nextSymbol(symbol)
    for index, candidate in ipairs(symbols) do
        if candidate == symbol then
            return symbols[index % #symbols + 1]
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

local function drawScreen(borderColors)
    ui.clear()
    display.clear()

    local width, height = display.size()
    local colorset = theme.get()

    if celebrationTitle then
        gameui.header(celebrationTitle, "CASINO ROYAL")
        display.center(2, celebrationTitle, celebrationColor or colors.yellow)
    else
        gameui.header("ROYAL SLOTS", "LUCK FAVORS THE BOLD")
    end

    gameui.labelValue(5, "CREDITS", wallet.getBalance(), colors.yellow)
    gameui.reels(7, reels, borderColors)

    display.center(13, "BET: " .. tostring(currentBet()), colors.yellow)

    local betButtonWidth = math.max(6, math.floor(width / 4))
    local controlsY = 14
    local leftX = 3
    local rightX = width - betButtonWidth - 2

    ui.button("bet_down", "-", leftX, controlsY, betButtonWidth, 1, function()
        if spinning then return end
        betIndex = math.max(1, betIndex - 1)
        message = "BET: " .. currentBet()
        messageColor = colors.white
        drawScreen()
    end)

    ui.button("bet_up", "+", rightX, controlsY, betButtonWidth, 1, function()
        if spinning then return end
        betIndex = math.min(#betOptions, betIndex + 1)
        message = "BET: " .. currentBet()
        messageColor = colors.white
        drawScreen()
    end)

    local spinY = 16
    ui.button(
        "spin",
        spinning and "SPINNING" or "SPIN",
        4,
        spinY,
        width - 6,
        2,
        function()
            if spinning then return end

            celebrationTitle = nil
            celebrationColor = nil

            local bet = currentBet()
            local spent, problem = wallet.spend(bet)
            if not spent then
                message = problem or "WAGER FAILED"
                messageColor = colors.red
                speakerNote("bass", 4, 1)
                drawScreen()
                return
            end

            spinning = true
            message = "SPINNING..."
            messageColor = colors.yellow
            speakerNote("hat", 10, 0.7)
            drawScreen()

            local final = { randomSymbol(), randomSymbol(), randomSymbol() }
            local stopFrames = { 14, 21, 29 }
            local stopped = { false, false, false }

            for frame = 1, stopFrames[3] do
                for reel = 1, 3 do
                    if frame < stopFrames[reel] then
                        reels[reel] = nextSymbol(reels[reel])
                    else
                        reels[reel] = final[reel]
                        if not stopped[reel] then
                            stopped[reel] = true
                            speakerNote("hat", 7 + reel * 2, 1)
                        end
                    end
                end

                gameui.reels(7, reels)
                sleep(frame > 20 and 0.11 or 0.075)
            end

            reels = final

            local prize = 0
            local winningReels = { false, false, false }
            local jackpot = false

            if reels[1].text == reels[2].text and reels[2].text == reels[3].text then
                prize = bet * reels[1].multiplier
                message = "ROYAL WIN! +" .. prize
                messageColor = colors.lime
                winningReels = { true, true, true }
                jackpot = true
            elseif reels[1].text == reels[2].text then
                prize = bet * 2
                message = "PAIR WIN! +" .. prize
                messageColor = colors.lime
                winningReels = { true, true, false }
            elseif reels[1].text == reels[3].text then
                prize = bet * 2
                message = "PAIR WIN! +" .. prize
                messageColor = colors.lime
                winningReels = { true, false, true }
            elseif reels[2].text == reels[3].text then
                prize = bet * 2
                message = "PAIR WIN! +" .. prize
                messageColor = colors.lime
                winningReels = { false, true, true }
            else
                message = "TRY AGAIN!"
                messageColor = colors.lightGray
            end

            if prize > 0 then
                if jackpot then
                    celebrationTitle = reels[1].text == "777" and "777 JACKPOT!" or "ROYAL JACKPOT!"
                    celebrationColor = colors.yellow
                end

                for flash = 1, jackpot and 8 or 4 do
                    local borders = {}
                    for reel = 1, 3 do
                        if winningReels[reel] then
                            borders[reel] = flash % 2 == 1 and colors.yellow or colors.white
                        end
                    end
                    drawScreen(borders)
                    speakerNote(jackpot and "bell" or "pling", 9 + flash, 1)
                    sleep(jackpot and 0.13 or 0.1)
                end

                local steps = math.min(12, math.max(4, prize))
                for step = 1, steps do
                    local counted = math.floor(prize * step / steps)
                    message = "PAYOUT  +" .. counted .. " / " .. prize
                    messageColor = step == steps and colors.lime or colors.yellow
                    drawScreen({ colors.yellow, colors.yellow, colors.yellow })
                    speakerNote("pling", 10 + (step % 8), 0.8)
                    sleep(jackpot and 0.09 or 0.06)
                end

                local paid, payProblem = wallet.add(prize)
                if not paid then
                    celebrationTitle = nil
                    message = payProblem or "PAYOUT FAILED"
                    messageColor = colors.red
                else
                    message = jackpot and ("JACKPOT PAID! +" .. prize) or ("WIN PAID! +" .. prize)
                    messageColor = colors.lime

                    if jackpot then
                        speakerNote("bell", 16, 1)
                        sleep(0.08)
                        speakerNote("bell", 20, 1)
                        sleep(0.08)
                        speakerNote("bell", 24, 1)
                    end
                end
            else
                speakerNote("bass", 5, 0.7)
            end

            spinning = false
            drawScreen()
        end,
        colorset.primary,
        colors.white
    )

    local backY = 19
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
                    celebrationTitle = nil
                    handlers.back()
                end
            end,
            colors.gray,
            colors.white
        )
    end

    local statusY = math.min(height - 2, 21)
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
    celebrationTitle = nil
    celebrationColor = nil
    message = "GOOD LUCK!"
    messageColor = colors.white
    drawScreen()
end

return slots
