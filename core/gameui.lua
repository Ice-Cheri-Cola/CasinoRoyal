--================================================--
-- Casino Royal
-- File: core/gameui.lua
-- Description: Shared UI helpers for casino games
--================================================--

local gameui = {}

local display = require("core.display")
local hardware = require("core.hardware")
local theme = require("core.theme")

local function monitor()
    return hardware.requireMonitor()
end

function gameui.header(title, subtitle)
    local colorset = theme.get()
    display.border()
    display.center(2, tostring(title or "CASINO GAME"), colorset.primary)

    if subtitle and subtitle ~= "" then
        display.center(3, tostring(subtitle), colorset.accent or colors.lightBlue)
    end
end

function gameui.labelValue(y, label, value, valueColor)
    local screen = monitor()
    local width = screen.getSize()
    local left = 3
    local rightText = tostring(value or "")
    local right = math.max(left + #tostring(label) + 2, width - #rightText - 2)

    screen.setBackgroundColor(theme.get().background)
    screen.setTextColor(colors.white)
    screen.setCursorPos(left, y)
    screen.write(tostring(label or ""))

    screen.setTextColor(valueColor or colors.yellow)
    screen.setCursorPos(right, y)
    screen.write(rightText)
end

local function drawReelBox(x, y, width, symbol, symbolColor)
    local screen = monitor()
    local background = theme.get().background

    screen.setBackgroundColor(background)
    screen.setTextColor(colors.lightGray)
    screen.setCursorPos(x, y)
    screen.write("+" .. string.rep("-", width - 2) .. "+")
    screen.setCursorPos(x, y + 1)
    screen.write("|" .. string.rep(" ", width - 2) .. "|")
    screen.setCursorPos(x, y + 2)
    screen.write("+" .. string.rep("-", width - 2) .. "+")

    local text = tostring(symbol or "---"):sub(1, width - 2)
    local textX = x + math.floor((width - #text) / 2)
    screen.setTextColor(symbolColor or colors.white)
    screen.setCursorPos(textX, y + 1)
    screen.write(text)
end

function gameui.reels(y, reels)
    local screen = monitor()
    local width = screen.getSize()
    local reelWidth = 7
    local gap = 2
    local totalWidth = reelWidth * 3 + gap * 2

    if totalWidth > width - 2 then
        reelWidth = 5
        gap = 1
        totalWidth = reelWidth * 3 + gap * 2
    end

    local startX = math.max(1, math.floor((width - totalWidth) / 2) + 1)

    for index = 1, 3 do
        local reel = reels[index] or {}
        drawReelBox(
            startX + (index - 1) * (reelWidth + gap),
            y,
            reelWidth,
            reel.text or reel[1] or "---",
            reel.color or reel[2] or colors.white
        )
    end
end

return gameui
