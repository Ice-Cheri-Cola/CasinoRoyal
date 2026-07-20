


--================================================--
-- Casino Royal
-- Version: 4.2.0
-- File: atm.lua
-- Description: Diamond deposit and withdrawal ATM
--================================================--

local player = require("core.player")
local bank = require("core.bank")

local monitor = peripheral.wrap("top")
local depositChest = peripheral.wrap("front")
local vaultChest = peripheral.wrap("back")

local DIAMOND = "minecraft:diamond"
local CREDITS_PER_DIAMOND = 10

if not monitor then error("Monitor not found on top") end
if not depositChest then error("Deposit chest not found on front") end
if not vaultChest then error("Vault chest not found on back") end

monitor.setTextScale(0.5)

local message = "Stand near the ATM"
local busy = false

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

local function draw()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    center(1, "CASINO ROYAL", colors.yellow)
    center(2, "DIAMOND ATM", colors.cyan)

    local username = player.getName()

    if username then
        center(4, username, colors.white)
        center(5, "Balance: " .. tostring(bank.getBalance()), colors.lime)
        center(6, "1 diamond = 10 credits", colors.lightGray)
        drawButton(8, "DEPOSIT ALL DIAMONDS", colors.green)
        drawButton(10, "WITHDRAW 1 DIAMOND", colors.blue)
    else
        center(5, "ONE PLAYER AT A TIME", colors.orange)
        center(7, "Stand within 5 blocks", colors.lightGray)
    end

    fillLine(12, colors.black)
    center(12, message, busy and colors.yellow or colors.white)
end

local function loginPlayer()
    player.logout()

    local ok, username = player.login()

    if not ok then
        message = username or "No player detected"
        return false
    end

    local loaded, problem = bank.loadPlayer()

    if not loaded then
        player.logout()
        message = problem or "Bank offline"
        return false
    end

    message = "Account loaded"
    return true
end

local function depositAll()
    if busy or not player.isLoggedIn() then return end

    busy = true
    message = "Processing deposit..."
    draw()

    local available = countDiamonds(depositChest)

    if available <= 0 then
        message = "Put diamonds in front chest"
        busy = false
        draw()
        return
    end

    local moved = moveDiamonds(depositChest, "back", available)

    if moved <= 0 then
        message = "Vault is full"
        busy = false
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
    draw()
end

local function withdrawOne()
    if busy or not player.isLoggedIn() then return end

    busy = true
    message = "Processing withdrawal..."
    draw()

    local refreshed, refreshProblem = bank.refreshBalance()

    if not refreshed then
        message = refreshProblem or "Bank offline"
        busy = false
        draw()
        return
    end

    if bank.getBalance() < CREDITS_PER_DIAMOND then
        message = "Need 10 credits"
        busy = false
        draw()
        return
    end

    if countDiamonds(vaultChest) < 1 then
        message = "ATM vault is empty"
        busy = false
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

        message = "Output chest full; credits refunded"
    else
        message = "Take 1 diamond from front chest"
    end

    busy = false
    draw()
end

loginPlayer()
draw()

local refreshTimer = os.startTimer(2)

while true do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "monitor_touch"
    and p1 == "top"
    and player.isLoggedIn()
    then
        local y = p3

        if y == 8 then
            depositAll()
        elseif y == 10 then
            withdrawOne()
        end

    elseif event == "timer"
    and p1 == refreshTimer
    then
        if player.isLoggedIn() then
            if not player.isStillNearby() then
                player.logout()
                message = "Player logged out"
            else
                bank.refreshBalance()
            end
        else
            loginPlayer()
        end

        draw()
        refreshTimer = os.startTimer(2)
    end
end
