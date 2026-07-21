local credits = {}

local SAVE_PATH = "data/machine_credits.db"
local LOG_PATH = "data/machine_transactions.log"
local balance = 0

local function wholeNumber(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function ensureDirectory(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function saveBalance(value)
    ensureDirectory(SAVE_PATH)
    local handle = fs.open(SAVE_PATH, "w")
    if not handle then
        return false, "COULD NOT SAVE MACHINE CREDITS"
    end

    handle.write(tostring(wholeNumber(value)))
    handle.close()
    return true
end

local function logChange(kind, amount, resultingBalance, source)
    ensureDirectory(LOG_PATH)
    local handle = fs.open(LOG_PATH, "a")
    if not handle then return nil end

    local entry = {
        timestamp = os.epoch("utc"),
        kind = tostring(kind or "CHANGE"),
        amount = math.floor(tonumber(amount) or 0),
        balance = wholeNumber(resultingBalance),
        source = tostring(source or "MACHINE")
    }

    handle.writeLine(table.concat({
        tostring(entry.timestamp),
        entry.kind,
        tostring(entry.amount),
        tostring(entry.balance),
        entry.source
    }, "|"))
    handle.close()
    return entry
end

function credits.load()
    if not fs.exists(SAVE_PATH) then
        balance = 0
        return balance
    end

    local handle = fs.open(SAVE_PATH, "r")
    if not handle then
        balance = 0
        return balance
    end

    balance = wholeNumber(handle.readAll())
    handle.close()
    return balance
end

function credits.save()
    return saveBalance(balance)
end

function credits.get()
    return balance
end

function credits.canAfford(amount)
    amount = wholeNumber(amount)
    return balance >= amount
end

function credits.add(amount, source)
    amount = wholeNumber(amount)
    if amount <= 0 then
        return false, "INVALID AMOUNT"
    end

    local oldBalance = balance
    balance = balance + amount

    local saved, problem = saveBalance(balance)
    if not saved then
        balance = oldBalance
        return false, problem
    end

    return true, balance, logChange("ADD", amount, balance, source)
end

function credits.remove(amount, reason)
    amount = wholeNumber(amount)
    if amount <= 0 then
        return false, "INVALID AMOUNT"
    end
    if balance < amount then
        return false, "NOT ENOUGH CREDITS"
    end

    local oldBalance = balance
    balance = balance - amount

    local saved, problem = saveBalance(balance)
    if not saved then
        balance = oldBalance
        return false, problem
    end

    return true, balance, logChange("REMOVE", -amount, balance, reason)
end

function credits.set(amount, reason)
    amount = wholeNumber(amount)
    local oldBalance = balance
    balance = amount

    local saved, problem = saveBalance(balance)
    if not saved then
        balance = oldBalance
        return false, problem
    end

    return true, balance, logChange("SET", balance - oldBalance, balance, reason)
end

function credits.reset(reason)
    local oldBalance = balance
    balance = 0

    local saved, problem = saveBalance(balance)
    if not saved then
        balance = oldBalance
        return false, problem
    end

    return true, oldBalance, logChange("RESET", -oldBalance, 0, reason)
end

return credits
