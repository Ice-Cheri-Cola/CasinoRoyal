--================================================--
-- Casino Royal
-- Version: 1.0.0
-- File: core/bank.lua
-- Description: Shared Royal Credits system
--================================================--

local bank = {}

local saveFolder = "data"
local saveFile = "data/balance.txt"
local startingBalance = 100

local balance = startingBalance

--------------------------------------------------
-- Save balance
--------------------------------------------------

local function save()
    if not fs.exists(saveFolder) then
        fs.makeDir(saveFolder)
    end

    local file = fs.open(
        saveFile,
        "w"
    )

    if file == nil then
        error("Could not save Royal Credits")
    end

    file.write(
        tostring(balance)
    )

    file.close()
end

--------------------------------------------------
-- Load balance
--------------------------------------------------

local function load()
    if not fs.exists(saveFile) then
        balance = startingBalance
        save()
        return
    end

    local file = fs.open(
        saveFile,
        "r"
    )

    if file == nil then
        balance = startingBalance
        return
    end

    local savedBalance =
        tonumber(file.readAll())

    file.close()

    if savedBalance == nil then
        balance = startingBalance
        save()
    else
        balance = savedBalance
    end
end

--------------------------------------------------
-- Get balance
--------------------------------------------------

function bank.getBalance()
    return balance
end

--------------------------------------------------
-- Check affordability
--------------------------------------------------

function bank.canAfford(amount)
    return balance >= amount
end

--------------------------------------------------
-- Add credits
--------------------------------------------------

function bank.add(amount)
    if amount <= 0 then
        return false
    end

    balance = balance + amount
    save()

    return true
end

--------------------------------------------------
-- Spend credits
--------------------------------------------------

function bank.spend(amount)
    if amount <= 0 then
        return false
    end

    if balance < amount then
        return false
    end

    balance = balance - amount
    save()

    return true
end

--------------------------------------------------
-- Reset credits
--------------------------------------------------

function bank.reset()
    balance = startingBalance
    save()
end

--------------------------------------------------
-- Start bank
--------------------------------------------------

load()

return bank
