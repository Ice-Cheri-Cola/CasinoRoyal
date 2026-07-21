local menu = {}

local display = require("core.display")
local ui = require("core.ui")
local theme = require("core.theme")

local handlers = {}
local walletBalance = 0
local activePlayer = nil

function menu.setHandlers(newHandlers)
    handlers = newHandlers or {}
end

function menu.setBalance(amount)
    walletBalance = math.max(0, math.floor(tonumber(amount) or 0))
end

function menu.setPlayer(profile)
    activePlayer = profile
end

local function balanceText(width)
    local full = "BALANCE  " .. walletBalance .. " DIAMONDS"
    if #full <= width then return full end
    local compact = "BALANCE  " .. walletBalance
    if #compact <= width then return compact end
    return tostring(walletBalance) .. " DIA"
end

local function playerText(width)
    if not activePlayer then return "NO MEMBER DETECTED" end
    local name = tostring(activePlayer.displayName or activePlayer.username or "MEMBER")
    local rank = tostring(activePlayer.rank or "MEMBER")
    local full = name .. "  |  " .. rank
    if #full <= width then return full end
    if #name <= width then return name end
    return name:sub(1, math.max(1, width))
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
    display.center(4, playerText(width - 2), activePlayer and colors.white or colors.orange)
    display.center(5, balanceText(width - 2), colors.lime)

    if height <= 12 then
        ui.button("deposit", "DEPOSIT", x, 7, contentWidth, 1, handlers.deposit)
        ui.button("membership", "MEMBER", x, 9, contentWidth, 1, handlers.membership)
        ui.button("games", "PLAY", x, 11, contentWidth, 1, handlers.games)
        return
    end

    ui.button("deposit", "DEPOSIT", x, 7, contentWidth, 2, handlers.deposit)
    ui.button("membership", "MEMBERSHIP", x, 10, contentWidth, 2, handlers.membership)
    ui.button("games", "PLAY", x, 13, contentWidth, 2, handlers.games)

    if height >= 18 then
        ui.button("cashout", "CASH OUT", x, 16, contentWidth, 2, handlers.cashout)
    end
end

return menu