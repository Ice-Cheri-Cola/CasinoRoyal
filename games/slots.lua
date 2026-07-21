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

local active = false
local attractMode = false
local animationTimer = nil
local animationFrame = 1
local lastActivity = 0
local idleDelay = 20000

local marqueeTitles = {
    "< ROYAL SLOTS >",
    "* ROYAL SLOTS *",
    "+ ROYAL SLOTS +",
    "= ROYAL SLOTS ="
}

local marqueeColors = {
    colors.purple,
    colors.magenta,
    colors.cyan,
    colors.yellow
}

local spinColors = {
    colors.purple,
    colors.magenta,
    colors.purple,
    colors.blue
}

local attractMessages = {
    "TOUCH TO PLAY",
    "CASINO ROYAL",
    "LUCK FAVORS THE BOLD",
    "ROYAL SLOTS AWAITS"
}

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

local function now()
    return os.epoch("utc")
end

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

local function noteActivity()
    lastActivity = now()
end

local function scheduleAnimation()
    if active then
        animationTimer = os.startTimer(0.55)
    end
end

local function drawStatus(y)
    local width = display.size()
    local text = tostring(message or "")
    if #text > width - 4 then
        text = text:sub(1, width - 4)
    end
    display.center(y, text, messageColor)
end

local function drawAnimatedHeader()
    local titleIndex = ((animationFrame - 1) % #marqueeTitles) + 1
    local colorIndex = ((animationFrame - 1) % #marqueeColors) + 1

    gameui.header(marqueeTitles[titleIndex], "LUCK FAVORS THE BOLD")
    display.center(2, marqueeTitles[titleIndex], marqueeColors[colorIndex])
end

local function drawAttractMode()
    ui.clear()
    display.clear()

    local _, height = display.size()
    local titleIndex = ((animationFrame - 1) % #marqueeTitles) + 1
    local colorIndex = ((animationFrame - 1) % #marqueeColors) + 1
    local messageIndex = (math.floor((animationFrame - 1) / 2) % #attractMessages) + 1

    gameui.header(marqueeTitles[titleIndex], "LIVING CASINO")
    display.center(2, marqueeTitles[titleIndex], marqueeColors[colorIndex])
    display.center(5, attractMessages[messageIndex], colors.white)
    gameui.reels(8, reels, {
        marqueeColors[colorIndex],
        marqueeColors[(colorIndex % #marqueeColors) + 1],
        marqueeColors[((colorIndex + 1) % #marqueeColors) + 1]
    })
    display.center(15, "TOUCH ANYWHERE", colors.yellow)
    display.center(16, "TO BEGIN", colors.yellow)
    display.center(height - 2, "CASINO ROYAL", colors.lightGray)
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
        drawAnimatedHeader()
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
        noteActivity()
        betIndex = math.max(1, betIndex - 1)
        message = "BET: " .. currentBet()
        messageColor = colors.white
        drawScreen()
    end)

    ui.button("bet_up", "+", rightX, controlsY, betButtonWidth, 1, function()
        if spinning then return end
        noteActivity()
        betIndex = math.min(#betOptions, betIndex + 1)
        message = "BET: " .. currentBet()
        messageColor = colors.white
        drawScreen()
    end)

    local spinY = 16
    local pulseIndex = ((animationFrame - 1) % #spinColors) + 1
    local spinBackground = spinning and colors.gray or spinColors[pulseIndex]

    ui.button(
        "spin",
        spinning and "SPINNING" or "SPIN",
        4,
        spinY,
        width - 6,
        2,
        function()
            if spinning then return end

            noteActivity()
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
            noteActivity()
            drawScreen()
        end,
        spinBackground,
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
                    active = false
                    attractMode = false
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
    -- Kept for compatibility. The slot screen reads the wallet directly.
end

function slots.setHandlers(newHandlers)
    handlers = newHandlers or {}
end

function slots.handleEvent(event, p1)
    if not active then return false end

    if event == "monitor_touch" then
        noteActivity()
        if attractMode then
            attractMode = false
            speakerNote("pling", 14, 0.8)
            drawScreen()
            return true
        end
        return false
    end

    if event == "timer" and p1 == animationTimer then
        animationFrame = animationFrame % 1000 + 1

        if not spinning then
            if not attractMode and now() - lastActivity >= idleDelay then
                attractMode = true
                celebrationTitle = nil
                message = "GOOD LUCK!"
                messageColor = colors.white
            end

            if attractMode then
                reels[1] = nextSymbol(reels[1])
                if animationFrame % 2 == 0 then reels[2] = nextSymbol(reels[2]) end
                if animationFrame % 3 == 0 then reels[3] = nextSymbol(reels[3]) end
                if animationFrame % 12 == 0 then speakerNote("bell", 12, 0.35) end
                drawAttractMode()
            else
                drawScreen()
            end
        end

        scheduleAnimation()
        return true
    end

    return false
end

function slots.open()
    active = true
    attractMode = false
    spinning = false
    animationFrame = 1
    celebrationTitle = nil
    celebrationColor = nil
    message = "GOOD LUCK!"
    messageColor = colors.white
    noteActivity()
    drawScreen()
    scheduleAnimation()
end

return slots