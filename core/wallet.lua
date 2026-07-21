local wallet = {}

local hardware = require("core.hardware")

local currency = "minecraft:diamond"
local okConfig, loadedConfig = pcall(require, "config")
if okConfig and type(loadedConfig) == "table" and loadedConfig.currency then
    currency = loadedConfig.currency
end

local SAVE_PATH = "data/wallet.db"
local LOG_PATH = "data/transactions.log"
local COUNTER_PATH = "data/transaction_counter.db"
local balance = 0

local directions = {
    "front", "back", "left", "right", "top", "bottom"
}

local function ensureDataDirectory(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function save()
    ensureDataDirectory(SAVE_PATH)

    local handle = fs.open(SAVE_PATH, "w")
    if not handle then
        return false, "Could not save wallet balance"
    end

    handle.write(tostring(balance))
    handle.close()
    return true
end

local function readCounter()
    if not fs.exists(COUNTER_PATH) then return 0 end
    local handle = fs.open(COUNTER_PATH, "r")
    if not handle then return 0 end
    local value = math.max(0, math.floor(tonumber(handle.readAll()) or 0))
    handle.close()
    return value
end

local function nextTransactionId()
    ensureDataDirectory(COUNTER_PATH)
    local number = readCounter() + 1
    local handle = fs.open(COUNTER_PATH, "w")
    if handle then
        handle.write(tostring(number))
        handle.close()
    end
    return "CR-" .. string.format("%06d", number)
end

local function logTransaction(kind, amount, resultingBalance)
    ensureDataDirectory(LOG_PATH)
    local handle = fs.open(LOG_PATH, "a")
    if not handle then return nil end

    local entry = {
        id = nextTransactionId(),
        timestamp = os.epoch("utc"),
        kind = tostring(kind or "TRANSACTION"),
        amount = math.floor(tonumber(amount) or 0),
        balance = math.floor(tonumber(resultingBalance) or balance)
    }

    handle.writeLine(table.concat({
        entry.id,
        tostring(entry.timestamp),
        entry.kind,
        tostring(entry.amount),
        tostring(entry.balance)
    }, "|"))
    handle.close()
    return entry
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

function wallet.spend(amount, kind)
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

    local transaction = logTransaction(kind or "SPEND", -amount, balance)
    return true, balance, transaction
end

function wallet.add(amount, kind)
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

    local transaction = logTransaction(kind or "CREDIT", amount, balance)
    return true, balance, transaction
end

function wallet.getRecentTransactions(limit)
    limit = math.max(1, math.floor(tonumber(limit) or 10))
    if not fs.exists(LOG_PATH) then return {} end

    local handle = fs.open(LOG_PATH, "r")
    if not handle then return {} end

    local entries = {}
    while true do
        local line = handle.readLine()
        if not line then break end

        local id, stamp, kind, amount, entryBalance =
            line:match("([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)")

        -- Backward compatibility with receipts created before transaction IDs.
        if not id then
            stamp, kind, amount, entryBalance =
                line:match("([^|]*)|([^|]*)|([^|]*)|([^|]*)")
            id = "LEGACY"
        end

        if stamp then
            entries[#entries + 1] = {
                id = id,
                timestamp = tonumber(stamp) or 0,
                kind = kind,
                amount = tonumber(amount) or 0,
                balance = tonumber(entryBalance) or 0
            }
        end
    end
    handle.close()

    local recent = {}
    for index = #entries, math.max(1, #entries - limit + 1), -1 do
        recent[#recent + 1] = entries[index]
    end
    return recent
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

    local oldBalance = balance
    balance = balance + deposited
    local saved, problem = save()
    if not saved then
        balance = oldBalance
        return false, 0, problem
    end

    local transaction = logTransaction("DEPOSIT", deposited, balance)

    if deposited < available then
        return true, deposited, "VAULT FULL", transaction
    end

    return true, deposited, "DEPOSIT COMPLETE", transaction
end

return wallet