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
    local full = "BALANCE  " .. walletBalance .. " DIAMONDS"
    if #full <= width then return full end

    local compact = "BALANCE  " .. walletBalance
    if #compact <= width then return compact end

    return tostring(walletBalance) .. " DIA"
end

function menu.open()
    ui.clear()
    display.clear()
    display.border()

    local width, height = display.size()
    local colorset = theme.get()
    local contentWidth = math.max(1, width - 4)
    local x = 3

    display.center(2, "CASINO ROYAL", colorset.primary)
    display.center(3, "ATM10 EDITION", colorset.accent)
    display.center(5, balanceText(width - 2), colors.lime)

    -- Short labels keep the interface readable on narrow monitors.
    if height <= 12 then
        ui.button("deposit", "DEPOSIT", x, 7, contentWidth, 1, handlers.deposit)
        ui.button("voucher", "VOUCHER", x, 9, contentWidth, 1, handlers.voucher)
        ui.button("games", "PLAY", x, 11, contentWidth, 1, handlers.games)
        return
    end

    ui.button("deposit", "DEPOSIT", x, 7, contentWidth, 2, handlers.deposit)
    ui.button("voucher", "VOUCHER", x, 10, contentWidth, 2, handlers.voucher)
    ui.button("games", "PLAY", x, 13, contentWidth, 2, handlers.games)

    if height >= 18 then
        ui.button("cashout", "CASH OUT", x, 16, contentWidth, 2, handlers.cashout)
    end
end

return menu