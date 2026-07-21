local wallet = {}

local hardware = require("core.hardware")

local currency = "minecraft:diamond"
local okConfig, loadedConfig = pcall(require, "config")
if okConfig and type(loadedConfig) == "table" and loadedConfig.currency then
    currency = loadedConfig.currency
end

local BANK_PATH = "data/wallet.db"
local MACHINE_PATH = "data/machine_credits.db"
local LOG_PATH = "data/transactions.log"
local MACHINE_LOG_PATH = "data/machine_transactions.log"
local COUNTER_PATH = "data/transaction_counter.db"

local bankBalance = 0
local machineBalance = 0

local directions = { "front", "back", "left", "right", "top", "bottom" }

local function ensureDirectory(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function readNumber(path)
    if not fs.exists(path) then return 0 end
    local handle = fs.open(path, "r")
    if not handle then return 0 end
    local value = math.max(0, math.floor(tonumber(handle.readAll()) or 0))
    handle.close()
    return value
end

local function writeNumber(path, value)
    ensureDirectory(path)
    local handle = fs.open(path, "w")
    if not handle then return false, "COULD NOT SAVE BALANCE" end
    handle.write(tostring(math.max(0, math.floor(tonumber(value) or 0))))
    handle.close()
    return true
end

local function callerSource(level)
    if not debug or not debug.getinfo then return "" end
    local info = debug.getinfo(level or 3, "S")
    return info and tostring(info.source or "") or ""
end

local function isCasinoCaller()
    for level = 3, 7 do
        local source = callerSource(level)
        if source:find("games/slots.lua", 1, true) then return true end
        if source:find("games/blackjack.lua", 1, true) then return true end
        if source:find("games/roulette.lua", 1, true) then return true end
    end
    return false
end

local function refreshOptionalCasinoCard()
    local ok, auth = pcall(require, "core.auth")
    if ok and auth and auth.login then
        -- A missing or removed card is valid guest play. login() clears any
        -- previous member session when the card is no longer present.
        pcall(auth.login)
    end
end

local function activeBalance()
    if isCasinoCaller() then
        refreshOptionalCasinoCard()
        return machineBalance, "machine"
    end
    return bankBalance, "bank"
end

local function setActiveBalance(value, kind)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if kind == "machine" then
        machineBalance = value
        return writeNumber(MACHINE_PATH, machineBalance)
    end
    bankBalance = value
    return writeNumber(BANK_PATH, bankBalance)
end

local function readCounter()
    return readNumber(COUNTER_PATH)
end

local function nextTransactionId()
    local number = readCounter() + 1
    writeNumber(COUNTER_PATH, number)
    return "CR-" .. string.format("%06d", number)
end

local function logTransaction(path, kind, amount, resultingBalance, includeId)
    ensureDirectory(path)
    local handle = fs.open(path, "a")
    if not handle then return nil end

    local entry = {
        id = includeId and nextTransactionId() or "MACHINE",
        timestamp = os.epoch("utc"),
        kind = tostring(kind or "TRANSACTION"),
        amount = math.floor(tonumber(amount) or 0),
        balance = math.floor(tonumber(resultingBalance) or 0)
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
    bankBalance = readNumber(BANK_PATH)
    machineBalance = readNumber(MACHINE_PATH)
    return bankBalance
end

function wallet.getBalance()
    local value = activeBalance()
    return value
end

function wallet.getBankBalance()
    return bankBalance
end

function wallet.getMachineBalance()
    refreshOptionalCasinoCard()
    return machineBalance
end

function wallet.canAfford(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local value = activeBalance()
    return value >= amount
end

function wallet.spend(amount, kind)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, "INVALID AMOUNT" end

    local oldBalance, balanceKind = activeBalance()
    if oldBalance < amount then return false, "NOT ENOUGH CREDITS" end

    local newBalance = oldBalance - amount
    local saved, problem = setActiveBalance(newBalance, balanceKind)
    if not saved then return false, problem end

    local path = balanceKind == "machine" and MACHINE_LOG_PATH or LOG_PATH
    local transaction = logTransaction(path, kind or "SPEND", -amount, newBalance, balanceKind == "bank")
    return true, newBalance, transaction
end

function wallet.add(amount, kind)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, "INVALID AMOUNT" end

    local oldBalance, balanceKind = activeBalance()
    local newBalance = oldBalance + amount
    local saved, problem = setActiveBalance(newBalance, balanceKind)
    if not saved then return false, problem end

    local path = balanceKind == "machine" and MACHINE_LOG_PATH or LOG_PATH
    local transaction = logTransaction(path, kind or "CREDIT", amount, newBalance, balanceKind == "bank")
    return true, newBalance, transaction
end

function wallet.addMachineCredits(amount, kind)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, "INVALID AMOUNT" end
    local newBalance = machineBalance + amount
    local saved, problem = setActiveBalance(newBalance, "machine")
    if not saved then return false, problem end
    return true, newBalance, logTransaction(MACHINE_LOG_PATH, kind or "LOAD", amount, newBalance, false)
end

function wallet.clearMachineCredits()
    local old = machineBalance
    local saved, problem = setActiveBalance(0, "machine")
    if not saved then return false, problem end
    logTransaction(MACHINE_LOG_PATH, "CLEAR", -old, 0, false)
    return true, old
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
        local id, stamp, kind, amount, entryBalance = line:match("([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)")
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
    if not manager or not manager.getItems then return 0 end
    local ok, items = pcall(manager.getItems)
    if not ok or type(items) ~= "table" then return 0 end

    local total = 0
    for _, item in pairs(items) do
        if item and item.name == currency then
            total = total + (tonumber(item.count) or 0)
        end
    end
    return total
end

local function removeToDirection(manager, direction, amount)
    local ok, moved = pcall(manager.removeItemFromPlayer, direction, {
        name = currency,
        count = amount
    })
    if not ok then return 0 end
    return math.max(0, math.floor(tonumber(moved) or 0))
end

function wallet.depositAll()
    local manager = hardware.getInventoryManager()
    if not manager then return false, 0, "INVENTORY MANAGER MISSING" end
    if not manager.removeItemFromPlayer then return false, 0, "MANAGER API NOT SUPPORTED" end

    local available = countCurrency(manager)
    if available <= 0 then return false, 0, "NO DIAMONDS FOUND" end

    local deposited = 0
    local remaining = available
    while remaining > 0 do
        local batch = math.min(64, remaining)
        local movedThisPass = 0
        for _, direction in ipairs(directions) do
            local moved = removeToDirection(manager, direction, batch)
            if moved > 0 then movedThisPass = moved break end
        end
        if movedThisPass <= 0 then break end
        deposited = deposited + movedThisPass
        remaining = remaining - movedThisPass
    end

    if deposited <= 0 then return false, 0, "CASINO VAULT FULL" end

    local oldBalance = bankBalance
    bankBalance = bankBalance + deposited
    local saved, problem = writeNumber(BANK_PATH, bankBalance)
    if not saved then
        bankBalance = oldBalance
        return false, 0, problem
    end

    local transaction = logTransaction(LOG_PATH, "DEPOSIT", deposited, bankBalance, true)
    if deposited < available then return true, deposited, "VAULT FULL", transaction end
    return true, deposited, "DEPOSIT COMPLETE", transaction
end

return wallet