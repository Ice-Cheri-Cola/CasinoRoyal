--================================================--
-- Casino Royal
-- File: games/slots.lua
-- Description: Royal Slots static interface
--================================================--

local slots = {}

local display = require("core.display")
local gameui = require("core.gameui")
local ui = require("core.ui")
local theme = require("core.theme")

local balance = 0
local bet = 10
local handlers = {}

local reels = {
    { text = "CHR", color = colors.red },
    { text = "BAR", color = colors.white },
    { text = "777", color = colors.cyan }
}

function slots.setBalance(amount)
    balance = math.max(0, math.floor(tonumber(amount) or 0))
end

function slots.setHandlers(newHandlers)
    handlers = newHandlers or {}
end

function slots.open()
    ui.clear()
    display.clear()

    local width, height = display.size()
    local colorset = theme.get()

    gameui.header("ROYAL SLOTS", "LUCK FAVORS THE BOLD")
    gameui.labelValue(5, "CREDITS", balance, colors.yellow)
    gameui.labelValue(7, "BET", bet, colors.yellow)
    gameui.reels(9, reels)

    local smallButtonWidth = math.max(5, math.floor((width - 10) / 2))
    local leftX = 3
    local rightX = width - smallButtonWidth - 2
    local controlsY = math.min(height - 7, 14)

    ui.button("bet_down", "- BET", leftX, controlsY, smallButtonWidth, 2, handlers.betDown)
    ui.button("bet_up", "BET +", rightX, controlsY, smallButtonWidth, 2, handlers.betUp)

    local spinY = controlsY + 3
    ui.button(
        "spin",
        "SPIN",
        3,
        spinY,
        width - 4,
        2,
        handlers.spin,
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
            handlers.back,
            colors.gray,
            colors.white
        )
    end
end

return slots
