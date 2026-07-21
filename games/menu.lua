local menu = {}

local display = require("core.display")
local ui = require("core.ui")
local theme = require("core.theme")

local handlers = {}
local walletBalance = 0

function menu.setHandlers(newHandlers)
    handlers = newHandlers or {}
end

function menu.setBalance(amount)
    walletBalance = math.max(0, math.floor(tonumber(amount) or 0))
end

function menu.open()
    ui.clear()
    display.clear()
    display.border()

    local width, height = display.size()
    local colorset = theme.get()

    display.center(2, "CASINO ROYAL", colorset.primary)
    display.center(3, "ATM10 EDITION", colorset.accent)
    display.center(5, "WALLET: " .. walletBalance .. " DIAMONDS", colors.lime)

    local buttonWidth = math.min(14, width - 4)
    local x = math.floor((width - buttonWidth) / 2) + 1

    ui.button("deposit", "INSERT DIAMONDS", x, 7, buttonWidth, 2, handlers.deposit)
    ui.button("voucher", "INSERT VOUCHER", x, 10, buttonWidth, 2, handlers.voucher)
    ui.button("games", "CHOOSE GAME", x, 13, buttonWidth, 2, handlers.games)

    if height >= 18 then
        ui.button("cashout", "CASH OUT", x, 16, buttonWidth, 2, handlers.cashout)
    end
end

return menu
