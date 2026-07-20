--================================================--
-- Casino Royal
-- Version: 4.2.2
-- File: atm.lua
-- Description: Diamond deposit and withdrawal ATM
--================================================--

local player = require("core.player")
local bank = require("core.bank")
local machine = require("core.machine")
local protocol = require("core.protocol")

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

local message = "Insert bank card or stand near ATM"
local busy = false
local depositY = 8
local withdrawY = 10
local logoutY = nil
local statusY = 12

local function updateLayout()
    local _, height = monitor.getSize()
    statusY = height
    withdrawY = math.max(7, height - 2)
    depositY = math.max(5, withdrawY - 2)
    logoutY = nil

    if height >= 15 then
        logoutY = height - 2
        withdrawY = height - 4
        depositY = height - 6
    end
end

local function center(y, text, textColor, backgroundColor)
    local width, height = monitor.getSize()
    if y < 1 or y > height then return end

    text = tostring(text or "")
    if #text > width then text = text:sub(1, width) end

    monitor.setBackgroundColor(backgroundColor or colors.black)
    monitor.setTextColor(textColor or colors.white)
    monitor.setCursorPos(math.max(1, math.floor((width - #text) / 2) + 1), y)
    monitor.write(text)
end

local function fillLine(y, backgroundColor)
    local width, height = monitor.getSize()
    if y < 1 or y > height then return end

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
        if item.name == DIAMOND then total = total + item.count end
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

local function parseCardUsername(displayName)
    if type(displayName) ~= "string" then return nil end

    for _, prefix in ipairs(CARD_PREFIXES) do
        if displayName:sub(1, #prefix):lower() == prefix:lower() then
            local username = displayName:sub(#prefix + 1):match("^%s*(.-)%s*$")
            if username ~= "" then return username end
        end
    end

    return nil
end

local function readBankCard()
    for slot, item in pairs(depositChest.list()) do
        if item.name ~= DIAMOND then
            local username = parseCardUsername(getItemDisplayName(slot, item))
            if username then return username, slot end
        end
    end

    return nil
end

local function syncMachineState()
    machine.setPlayer(player.getName())
    machine.setStatus(busy and protocol.STATUS_BUSY or protocol.STATUS_IDLE)
end

local function draw()
    updateLayout()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    center(1, "CASINO ROYAL", colors.yellow)
    center(2, "DIAMOND ATM", colors.cyan)

    local username = player.getName()

    if username then
        center(4, username, colors.white)
        center(5, "Balance: " .. tostring(bank.getBalance()), colors.lime)
        center(6, "1 diamond = 10 credits", colors.lightGray)
        drawButton(depositY, "DEPOSIT ALL", colors.green)
        drawButton(withdrawY, "WITHDRAW 1", colors.blue)
        if logoutY then drawButton(logoutY, "LOG OUT", colors.red) end
    else
        center(5, "INSERT BANK CARD", colors.orange)
        center(6, "OR STAND WITHIN 2 BLOCKS", colors.lightGray)
    end

    fillLine(statusY, colors.black)
    center(statusY, message, busy and colors.yellow or colors.white)
end

local function loadAccount(username, method)
    local ok, result

    if method == "card" then
        ok, result = player.loginAs(username)
    else
        player.logout()
        ok, result = player.login()
    end

    if not ok then
        message = result or "Login failed"
        syncMachineState()
        return false
    end

    local loaded, problem = bank.loadPlayer()
    if not loaded then
        player.logout()
        message = problem or "Bank offline"
        syncMachineState()
        return false
    end

    message = method == "card" and "Bank card accepted" or "Account loaded"
    syncMachineState()
    return true
end

local function loginPlayer()
    local cardUsername = readBankCard()
    if cardUsername then return loadAccount(cardUsername, "card") end
    return loadAccount(nil, "detector")
end

local function depositAll()
    if busy or not player.isLoggedIn() then return end

    busy = true
    syncMachineState()
    message = "Processing deposit..."
    draw()

    local available = countDiamonds(depositChest)
    if available <= 0 then
        message = "Put diamonds in front chest"
        busy = false
        syncMachineState()
        draw()
        return
    end

    local moved = moveDiamonds(depositChest, "back", available)
    if moved <= 0 then
        message = "Vault is full"
        busy = false
        syncMachineState()
        draw()
        return
    end

    local credits = moved * CREDITS_PER_DIAMOND
    local paid, problem = bank.add(credits, "atm", "Diamond deposit")

    if not paid then
        moveDiamonds(vaultChest, "front", moved)
        message = problem or "Deposit failed; diamonds returned"
    else
        message = "+" .. credits .. " credits for " .. moved .. " diamonds"
    end

    busy = false
    syncMachineState()
    draw()
end

local function withdrawOne()
    if busy or not player.isLoggedIn() then return end

    busy = true
    syncMachineState()
    message = "Processing withdrawal..."
    draw()

    local refreshed, refreshProblem = bank.refreshBalance()
    if not refreshed then
        message = refreshProblem or "Bank offline"
        busy = false
        syncMachineState()
        draw()
        return
    end

    if bank.getBalance() < CREDITS_PER_DIAMOND then
        message = "Need 10 credits"
        busy = false
        syncMachineState()
        draw()
        return
    end

    if countDiamonds(vaultChest) < 1 then
        message = "ATM vault is empty"
        busy = false
        syncMachineState()
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
        syncMachineState()
        draw()
        return
    end

    local moved = moveDiamonds(vaultChest, "front", 1)
    if moved ~= 1 then
        bank.add(CREDITS_PER_DIAMOND, "atm", "Failed withdrawal refund")
        message = "Output full; credits refunded"
    else
        message = "Take 1 diamond from front chest"
    end

    busy = false
    syncMachineState()
    draw()
end

local started, startProblem = machine.start()
if not started then error(startProblem or "ATM could not start") end

loginPlayer()
syncMachineState()
draw()

local refreshTimer = os.startTimer(2)
local heartbeatTimer = os.startTimer(5)

while true do
    local event, p1, _, p3 = os.pullEvent()

    if event == "monitor_touch" and p1 == "top" and player.isLoggedIn() then
        local y = p3
        if y == depositY then
            depositAll()
        elseif y == withdrawY then
            withdrawOne()
        elseif logoutY and y == logoutY then
            player.logout()
            message = "Logged out"
            syncMachineState()
            draw()
        end

    elseif event == "timer" and p1 == refreshTimer then
        if player.isLoggedIn() then
            if player.getLoginMethod() == "card" then
                local cardUsername = readBankCard()
                if cardUsername ~= player.getName() then
                    player.logout()
                    message = "Card removed - logged out"
                else
                    bank.refreshBalance()
                end
            elseif not player.isStillNearby() then
                player.logout()
                message = "Player logged out"
            else
                bank.refreshBalance()
            end
        else
            loginPlayer()
        end

        syncMachineState()
        draw()
        refreshTimer = os.startTimer(2)

    elseif event == "timer" and p1 == heartbeatTimer then
        syncMachineState()
        local ok, problem = machine.sendHeartbeat()
        if not ok and not player.isLoggedIn() then
            message = problem or "Server registration failed"
            draw()
        end
        heartbeatTimer = os.startTimer(5)
    end
end
