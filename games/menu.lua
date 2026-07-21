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

local function balanceText(width)
    local full = "BALANCE: " .. walletBalance .. " DIAMONDS"
    if #full <= width then
        return full
    end

    local medium = "BALANCE: " .. walletBalance
    if #medium <= width then
        return medium
    end

    return tostring(walletBalance) .. " DIA"
end

function menu.open()
    ui.clear()
    display.clear()
    display.border()

    local width, height = display.size()
    local colorset = theme.get()
    local contentWidth = math.max(1, width - 2)

    display.center(2, "CASINO ROYAL", colorset.primary)
    display.center(3, "ATM10 EDITION", colorset.accent)
    display.center(5, balanceText(contentWidth), colors.lime)

    local buttonWidth = contentWidth
    local x = 2

    if height <= 12 then
        -- Compact layout for a two-block-tall monitor at text scale 1.
        ui.button("deposit", "INSERT DIAMONDS", x, 7, buttonWidth, 1, handlers.deposit)
        ui.button("voucher", "INSERT VOUCHER", x, 9, buttonWidth, 1, handlers.voucher)
        ui.button("games", "CHOOSE GAME", x, 11, buttonWidth, 1, handlers.games)
        return
    end

    ui.button("deposit", "INSERT DIAMONDS", x, 7, buttonWidth, 2, handlers.deposit)
    ui.button("voucher", "INSERT VOUCHER", x, 10, buttonWidth, 2, handlers.voucher)
    ui.button("games", "CHOOSE GAME", x, 13, buttonWidth, 2, handlers.games)

    if height >= 18 then
        ui.button("cashout", "CASH OUT", x, 16, buttonWidth, 2, handlers.cashout)
    end
end

return menu
