--================================================--
-- Casino Royal
-- File: core/vouchers.lua
-- Description: Creates, verifies, redeems, and cancels casino vouchers
--================================================--

local machine = require("core.machine")

local vouchers = {}

local DATA_DIRECTORY = "data"
local DATABASE_PATH = DATA_DIRECTORY .. "/vouchers.db"
local COUNTER_PATH = DATA_DIRECTORY .. "/voucher_counter.db"

local database = {}
local loaded = false

local function wholeNumber(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function ensureDirectory()
    if not fs.exists(DATA_DIRECTORY) then
        fs.makeDir(DATA_DIRECTORY)
    end
end

local function copyTable(source)
    if type(source) ~= "table" then return source end

    local result = {}
    for key, value in pairs(source) do
        result[key] = type(value) == "table" and copyTable(value) or value
    end
    return result
end

local function saveDatabase()
    ensureDirectory()

    local handle = fs.open(DATABASE_PATH, "w")
    if not handle then
        return false, "COULD NOT SAVE VOUCHERS"
    end

    handle.write(textutils.serialize(database))
    handle.close()
    return true
end

local function loadCounter()
    if not fs.exists(COUNTER_PATH) then return 0 end

    local handle = fs.open(COUNTER_PATH, "r")
    if not handle then return 0 end

    local value = wholeNumber(handle.readAll())
    handle.close()
    return value
end

local function saveCounter(value)
    ensureDirectory()

    local handle = fs.open(COUNTER_PATH, "w")
    if not handle then
        return false, "COULD NOT SAVE VOUCHER COUNTER"
    end

    handle.write(tostring(wholeNumber(value)))
    handle.close()
    return true
end

local function nextVoucherId()
    local counter = loadCounter() + 1
    local saved, problem = saveCounter(counter)
    if not saved then return nil, problem end

    return string.format("CRV-%08d", counter)
end

local function ensureLoaded()
    if loaded then return true end
    vouchers.load()
    return true
end

function vouchers.load()
    ensureDirectory()

    if not fs.exists(DATABASE_PATH) then
        database = {}
        loaded = true
        return database
    end

    local handle = fs.open(DATABASE_PATH, "r")
    if not handle then
        database = {}
        loaded = true
        return database
    end

    local contents = handle.readAll()
    handle.close()

    local decoded = textutils.unserialize(contents)
    database = type(decoded) == "table" and decoded or {}
    loaded = true
    return database
end

function vouchers.create(amount, issuedFor, note)
    ensureLoaded()

    amount = wholeNumber(amount)
    if amount <= 0 then
        return false, "INVALID VOUCHER VALUE"
    end

    local id, idProblem = nextVoucherId()
    if not id then return false, idProblem end

    local voucher = {
        id = id,
        value = amount,
        status = "ACTIVE",
        issuedAt = os.epoch("utc"),
        issuedBy = machine.getId() or ("casino_" .. tostring(os.getComputerID())),
        machineType = machine.getType() or "unknown",
        issuedFor = issuedFor and tostring(issuedFor) or nil,
        note = note and tostring(note) or nil,
        redeemedAt = nil,
        redeemedBy = nil,
        cancelledAt = nil,
        cancelledBy = nil,
        cancelReason = nil
    }

    database[id] = voucher

    local saved, problem = saveDatabase()
    if not saved then
        database[id] = nil
        return false, problem
    end

    return true, copyTable(voucher)
end

function vouchers.get(id)
    ensureLoaded()

    id = tostring(id or "")
    local voucher = database[id]
    if not voucher then return nil, "VOUCHER NOT FOUND" end

    return copyTable(voucher)
end

function vouchers.verify(id)
    local voucher, problem = vouchers.get(id)
    if not voucher then return false, problem end

    if voucher.status ~= "ACTIVE" then
        return false, "VOUCHER IS " .. tostring(voucher.status), voucher
    end

    if wholeNumber(voucher.value) <= 0 then
        return false, "VOUCHER HAS NO VALUE", voucher
    end

    return true, voucher
end

function vouchers.redeem(id, redeemedBy)
    ensureLoaded()

    local valid, voucherOrProblem, invalidVoucher = vouchers.verify(id)
    if not valid then
        return false, voucherOrProblem, invalidVoucher
    end

    local voucher = database[tostring(id)]
    voucher.status = "REDEEMED"
    voucher.redeemedAt = os.epoch("utc")
    voucher.redeemedBy = redeemedBy and tostring(redeemedBy)
        or machine.getId()
        or ("casino_" .. tostring(os.getComputerID()))

    local saved, problem = saveDatabase()
    if not saved then
        voucher.status = "ACTIVE"
        voucher.redeemedAt = nil
        voucher.redeemedBy = nil
        return false, problem
    end

    return true, copyTable(voucher)
end

function vouchers.cancel(id, reason, cancelledBy)
    ensureLoaded()

    local voucher = database[tostring(id or "")]
    if not voucher then return false, "VOUCHER NOT FOUND" end

    if voucher.status ~= "ACTIVE" then
        return false, "VOUCHER IS " .. tostring(voucher.status), copyTable(voucher)
    end

    voucher.status = "CANCELLED"
    voucher.cancelledAt = os.epoch("utc")
    voucher.cancelledBy = cancelledBy and tostring(cancelledBy)
        or machine.getId()
        or ("casino_" .. tostring(os.getComputerID()))
    voucher.cancelReason = tostring(reason or "CANCELLED")

    local saved, problem = saveDatabase()
    if not saved then
        voucher.status = "ACTIVE"
        voucher.cancelledAt = nil
        voucher.cancelledBy = nil
        voucher.cancelReason = nil
        return false, problem
    end

    return true, copyTable(voucher)
end

function vouchers.list(status)
    ensureLoaded()

    local results = {}
    for _, voucher in pairs(database) do
        if status == nil or voucher.status == status then
            results[#results + 1] = copyTable(voucher)
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.issuedAt) or 0) > (tonumber(b.issuedAt) or 0)
    end)

    return results
end

function vouchers.getOutstandingValue()
    ensureLoaded()

    local total = 0
    for _, voucher in pairs(database) do
        if voucher.status == "ACTIVE" then
            total = total + wholeNumber(voucher.value)
        end
    end
    return total
end

return vouchers
