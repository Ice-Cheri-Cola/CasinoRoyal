--================================================--
-- Casino Royal
-- Version: 4.3.0
-- File: atm.lua
-- Description: Networked diamond ATM with bank cards
--================================================--

local player = require("core.player")
local bank = require("core.bank")
local machine = require("core.machine")
local protocol = require("core.protocol")
local card = require("core.card")

local monitor = peripheral.wrap("top")
local depositChest = peripheral.wrap("front")
local vaultChest = peripheral.wrap("back")

local DIAMOND = "minecraft:diamond"
local CREDITS_PER_DIAMOND = 10
local CARD_PREFIXES = {
    "Casino Royal Card: ",
    "Casino Card: ",
    "Bank Card: "
}

if not monitor then error("Monitor not found on top") end
if not depositChest then error("Deposit chest not found on front") end
if not vaultChest then error("Vault chest not found on back") end

player.setRange(2)
monitor.setTextScale(0.5)

local message = "Insert card or stand near ATM"
local busy = false
local activeCardId = nil

local function center(y, text, textColor, backgroundColor)
    local width = monitor.getSize()
    text = tostring(text or "")
    monitor.setBackgroundColor(backgroundColor or colors.black)
    monitor.setTextColor(textColor or colors.white)
    monitor.setCursorPos(math.max(1, math.floor((width - #text) / 2) + 1), y)
    monitor.write(text)
end

local function fillLine(y, backgroundColor)
    local width = monitor.getSize()
    monitor.setBackgroundColor(backgroundColor or colors.black)
    monitor.setCursorPos(1, y)
    monitor.write(string.rep(" ", width))
end

local function drawButton(y, label, backgroundColor)
    fillLine(y, backgroundColor)
    center(y, label, colors.white, backgroundColor)
end

local function countDiamonds(inventory)
    local total = 0
    for _, item in pairs(inventory.list()) do
        if item.name == DIAMOND then
            total = total + item.count
        end
    end
    return total
end

local function moveDiamonds(source, destinationName, amount)
    local remaining = amount
    local moved = 0

    for slot, item in pairs(source.list()) do
        if remaining <= 0 then break end
        if item.name == DIAMOND then
            local transferred = source.pushItems(
                destinationName,
                slot,
                math.min(item.count, remaining)
            ) or 0

            moved = moved + transferred
            remaining = remaining - transferred
        end
    end

    return moved
end

local function getItemDisplayName(slot, summary)
    if type(depositChest.getItemDetail) == "function" then
        local ok, detail = pcall(depositChest.getItemDetail, slot)
        if ok and type(detail) == "table" then
            return detail.displayName or detail.name
        end
    end

    return summary.displayName or summary.name
end

local function parseNamedCardUsername(displayName)
    if type(displayName) ~= "string" then return nil end

    for _, prefix in ipairs(CARD_PREFIXES) do
        if displayName:sub(1, #prefix):lower() == prefix:lower() then
            local username = displayName:sub(#prefix + 1):match("^%s*(.-)%s*$")
            if username ~= "" then return username end
        end
    end

    return nil
end

local function readNamedCard()
    for slot, item in pairs(depositChest.list()) do
        if item.name ~= DIAMOND then
            local username = parseNamedCardUsername(
                getItemDisplayName(slot, item)
            )

            if username then
                return {
                    username = username,
                    id = "named:" .. username,
                    kind = "named_item"
                }
            end
        end
    end

    return nil
end

local function readAnyBankCard()
    local diskCard = card.read()
    if diskCard then
        diskCard.kind = "disk"
        return diskCard
    end

    return readNamedCard()
end

local function setRuntimeStatus()
    machine.setPlayer(player.getName())
    machine.setStatus(busy and protocol.STATUS_BUSY or protocol.STATUS_IDLE)
end

local function draw()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    local _, height = monitor.getSize()
    local compact = height < 15

    center(1, "CASINO ROYAL", colors.yellow)
    center(2, "DIAMOND ATM", colors.cyan)

    local username = player.getName()

    if username then
        center(4, username, colors.white)
        center(5, "Balance: " .. tostring(bank.getBalance()), colors.lime)
        center(6, "1 diamond = 10 credits", colors.lightGray)

        if compact then
            drawButton(8, "DEPOSIT ALL", colors.green)
            drawButton(10, "WITHDRAW 1", colors.blue)
            center(12, message, busy and colors.yellow or colors.white)
        else
            center(7, "Login: " .. tostring(player.getLoginMethod() or "unknown"), colors.lightGray)
            drawButton(9, "DEPOSIT ALL", colors.green)
            drawButton(11, "WITHDRAW 1", colors.blue)
            drawButton(13, "LOG OUT", colors.red)
            center(15, message, busy and colors.yellow or colors.white)
        end
    else
        center(5, "INSERT BANK CARD", colors.orange)
        center(6, "Disk drive or named item", colors.lightGray)
        center(8, "OR STAND WITHIN 2 BLOCKS", colors.orange)
        center(math.min(height, 12), message, colors.white)
    end
end

local function loadAccount(username, method, cardId)
    local ok, result

    if method == "card" then
        ok, result = player.loginAs(username)
        activeCardId = cardId
    else
        player.logout()
        activeCardId = nil
        ok, result = player.login()
    end

    if not ok then
        message = result or "Login failed"
        return false
    end

    local loaded, problem = bank.loadPlayer()
    if not loaded then
        player.logout()
        activeCardId = nil
        message = problem or "Bank offline"
        return false
    end

    message = method == "card" and "Bank card accepted" or "Account loaded"
    setRuntimeStatus()
    return true
end

local function loginPlayer()
    local cardData = readAnyBankCard()

    if cardData then
        return loadAccount(cardData.username, "card", cardData.id)
    end

    return loadAccount(nil, "detector")
end

local function depositAll()
    if busy or not player.isLoggedIn() then return end

    busy = true
    setRuntimeStatus()
    message = "Processing deposit..."
    draw()

    local available = countDiamonds(depositChest)

    if available <= 0 then
        message = "Put diamonds in front chest"
        busy = false
        setRuntimeStatus()
        draw()
        return
    end

    local moved = moveDiamonds(depositChest, "back", available)

    if moved <= 0 then
        message = "Vault is full"
        busy = false
        setRuntimeStatus()
        draw()
        return
    end

    local credits = moved * CREDITS_PER_DIAMOND
    local paid, problem = bank.add(
        credits,
        "atm",
        "Diamond deposit"
    )

    if not paid then
        moveDiamonds(vaultChest, "front", moved)
        message = problem or "Deposit failed; diamonds returned"
    else
        message = "+" .. credits .. " credits for " .. moved .. " diamonds"
    end

    busy = false
    setRuntimeStatus()
    draw()
end

local function withdrawOne()
    if busy or not player.isLoggedIn() then return end

    busy = true
    setRuntimeStatus()
    message = "Processing withdrawal..."
    draw()

    local refreshed, refreshProblem = bank.refreshBalance()

    if not refreshed then
        message = refreshProblem or "Bank offline"
        busy = false
        setRuntimeStatus()
        draw()
        return
    end

    if bank.getBalance() < CREDITS_PER_DIAMOND then
        message = "Need 10 credits"
        busy = false
        setRuntimeStatus()
        draw()
        return
    end

    if countDiamonds(vaultChest) < 1 then
        message = "ATM vault is empty"
        busy = false
        setRuntimeStatus()
        draw()
        return
    end

    local spent, spendProblem = bank.spend(
        CREDITS_PER_DIAMOND,
        "atm",
        "Diamond withdrawal"
    )

    if not spent then
        message = spendProblem or "Withdrawal declined"
        busy = false
        setRuntimeStatus()
        draw()
        return
    end

    local moved = moveDiamonds(vaultChest, "front", 1)

    if moved ~= 1 then
        bank.add(
            CREDITS_PER_DIAMOND,
            "atm",
            "Failed withdrawal refund"
        )
        message = "Output full; credits refunded"
    else
        message = "Take 1 diamond from front chest"
    end

    busy = false
    setRuntimeStatus()
    draw()
end

local function logout(reason)
    player.logout()
    activeCardId = nil
    message = reason or "Logged out"
    setRuntimeStatus()
end

machine.start()
loginPlayer()
setRuntimeStatus()
draw()

local refreshTimer = os.startTimer(2)
local heartbeatTimer = os.startTimer(5)

while true do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "monitor_touch"
    and p1 == "top"
    and player.isLoggedIn()
    then
        local _, height = monitor.getSize()
        local compact = height < 15
        local y = p3

        if (compact and y == 8) or (not compact and y == 9) then
            depositAll()
        elseif (compact and y == 10) or (not compact and y == 11) then
            withdrawOne()
        elseif not compact and y == 13 then
            logout("Logged out")
            draw()
        end

    elseif event == "timer" and p1 == refreshTimer then
        if player.isLoggedIn() then
            if player.getLoginMethod() == "card" then
                local cardData = readAnyBankCard()
                if not cardData or cardData.id ~= activeCardId then
                    logout("Card removed - logged out")
                else
                    bank.refreshBalance()
                end
            elseif not player.isStillNearby() then
                logout("Player logged out")
            else
                bank.refreshBalance()
            end
        else
            loginPlayer()
        end

        setRuntimeStatus()
        draw()
        refreshTimer = os.startTimer(2)

    elseif event == "timer" and p1 == heartbeatTimer then
        setRuntimeStatus()
        machine.sendHeartbeat()
        heartbeatTimer = os.startTimer(5)
    end
end
