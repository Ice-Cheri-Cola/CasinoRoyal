local wallet = {}

local hardware = require("core.hardware")

local currency = "minecraft:diamond"
local okConfig, loadedConfig = pcall(require, "config")
if okConfig and type(loadedConfig) == "table" and loadedConfig.currency then
    currency = loadedConfig.currency
end

local SAVE_PATH = "data/wallet.db"
local balance = 0

local directions = {
    "front", "back", "left", "right", "top", "bottom"
}

local function save()
    local directory = fs.getDir(SAVE_PATH)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end

    local handle = fs.open(SAVE_PATH, "w")
    if not handle then
        return false, "Could not save wallet balance"
    end

    handle.write(tostring(balance))
    handle.close()
    return true
end

function wallet.load()
    if not fs.exists(SAVE_PATH) then
        balance = 0
        return balance
    end

    local handle = fs.open(SAVE_PATH, "r")
    if not handle then
        balance = 0
        return balance
    end

    balance = math.max(0, math.floor(tonumber(handle.readAll()) or 0))
    handle.close()
    return balance
end

function wallet.getBalance()
    return balance
end

function wallet.canAfford(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    return balance >= amount
end

function wallet.spend(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    if amount <= 0 then
        return false, "INVALID AMOUNT"
    end

    if balance < amount then
        return false, "NOT ENOUGH CREDITS"
    end

    local oldBalance = balance
    balance = balance - amount

    local ok, problem = save()
    if not ok then
        balance = oldBalance
        return false, problem
    end

    return true, balance
end

function wallet.add(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    if amount <= 0 then
        return false, "INVALID AMOUNT"
    end

    local oldBalance = balance
    balance = balance + amount

    local ok, problem = save()
    if not ok then
        balance = oldBalance
        return false, problem
    end

    return true, balance
end

local function countCurrency(manager)
    if not manager or not manager.getItems then
        return 0
    end

    local ok, items = pcall(manager.getItems)
    if not ok or type(items) ~= "table" then
        return 0
    end

    local total = 0
    for _, item in pairs(items) do
        if item and item.name == currency then
            total = total + (tonumber(item.count) or 0)
        end
    end
    return total
end

local function removeToDirection(manager, direction, amount)
    local ok, moved = pcall(
        manager.removeItemFromPlayer,
        direction,
        {
            name = currency,
            count = amount
        }
    )

    if not ok then
        return 0
    end

    return math.max(0, math.floor(tonumber(moved) or 0))
end

function wallet.depositAll()
    local manager = hardware.getInventoryManager()
    if not manager then
        return false, 0, "INVENTORY MANAGER MISSING"
    end

    if not manager.removeItemFromPlayer then
        return false, 0, "MANAGER API NOT SUPPORTED"
    end

    local available = countCurrency(manager)
    if available <= 0 then
        return false, 0, "NO DIAMONDS FOUND"
    end

    local deposited = 0
    local remaining = available

    while remaining > 0 do
        local batch = math.min(64, remaining)
        local movedThisPass = 0

        for _, direction in ipairs(directions) do
            local moved = removeToDirection(manager, direction, batch)
            if moved > 0 then
                movedThisPass = moved
                break
            end
        end

        if movedThisPass <= 0 then
            break
        end

        deposited = deposited + movedThisPass
        remaining = remaining - movedThisPass
    end

    if deposited <= 0 then
        return false, 0, "CASINO VAULT FULL"
    end

    balance = balance + deposited
    save()

    if deposited < available then
        return true, deposited, "VAULT FULL"
    end

    return true, deposited, "DEPOSIT COMPLETE"
end

return wallet
