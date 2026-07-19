--================================================--
-- Casino Royal
-- Version: 4.1.0
-- File: core/account_store.lua
-- Description: Central server-side player account storage
--================================================--

local accountStore = {}

--------------------------------------------------
-- Settings
--------------------------------------------------

local DATA_DIRECTORY =
    "data"

local PLAYER_DIRECTORY =
    DATA_DIRECTORY
    .. "/players"

local TRANSACTION_DIRECTORY =
    DATA_DIRECTORY
    .. "/transactions"

local STARTING_BALANCE =
    100

--------------------------------------------------
-- Utility functions
--------------------------------------------------

local function currentTime()
    return os.epoch("utc")
end

local function copyTable(source)
    if type(source) ~= "table" then
        return source
    end

    local result = {}

    for key, value
        in pairs(source)
    do
        if type(value) == "table" then
            result[key] =
                copyTable(value)
        else
            result[key] =
                value
        end
    end

    return result
end

local function safeUsername(username)
    return tostring(
        username
        or ""
    ):gsub(
        "[^%w_%-%._]",
        "_"
    )
end

local function isValidUsername(username)
    return type(username) == "string"
        and username ~= ""
        and safeUsername(username) ~= ""
end

local function normalizeAmount(amount)
    if type(amount) ~= "number" then
        return nil
    end

    if amount ~= amount then
        return nil
    end

    if amount == math.huge
    or amount == -math.huge
    then
        return nil
    end

    amount =
        math.floor(amount)

    if amount <= 0 then
        return nil
    end

    return amount
end

--------------------------------------------------
-- Directory management
--------------------------------------------------

local function ensureDirectory(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function ensureDirectories()
    ensureDirectory(
        DATA_DIRECTORY
    )

    ensureDirectory(
        PLAYER_DIRECTORY
    )

    ensureDirectory(
        TRANSACTION_DIRECTORY
    )
end

--------------------------------------------------
-- File paths
--------------------------------------------------

local function getAccountPath(username)
    return PLAYER_DIRECTORY
        .. "/"
        .. safeUsername(username)
        .. ".txt"
end

local function getTransactionPath(username)
    return TRANSACTION_DIRECTORY
        .. "/"
        .. safeUsername(username)
        .. ".log"
end

--------------------------------------------------
-- Default data
--------------------------------------------------

local function createDefaultStats()
    return {
        gamesPlayed = 0,
        slotsPlayed = 0,
        blackjackPlayed = 0,
        roulettePlayed = 0,
        totalBet = 0,
        totalWon = 0,
        totalLost = 0,
        biggestWin = 0
    }
end

local function createDefaultAccount(username)
    local now =
        currentTime()

    return {
        username =
            username,

        balance =
            STARTING_BALANCE,

        createdAt =
            now,

        updatedAt =
            now,

        lastMachineId =
            nil,

        stats =
            createDefaultStats()
    }
end

--------------------------------------------------
-- Account repair
--------------------------------------------------

local function repairStats(stats)
    if type(stats) ~= "table" then
        stats = {}
    end

    local defaults =
        createDefaultStats()

    for key, defaultValue
        in pairs(defaults)
    do
        if type(stats[key]) ~= "number" then
            stats[key] =
                defaultValue
        end
    end

    return stats
end

local function repairAccount(
    username,
    account
)
    if type(account) ~= "table" then
        account =
            createDefaultAccount(
                username
            )
    end

    account.username =
        username

    if type(account.balance) ~= "number"
    or account.balance < 0
    then
        account.balance =
            STARTING_BALANCE
    end

    account.balance =
        math.floor(
            account.balance
        )

    if type(account.createdAt) ~= "number" then
        account.createdAt =
            currentTime()
    end

    if type(account.updatedAt) ~= "number" then
        account.updatedAt =
            currentTime()
    end

    account.stats =
        repairStats(
            account.stats
        )

    return account
end

--------------------------------------------------
-- File operations
--------------------------------------------------

local function readSerialized(path)
    if not fs.exists(path) then
        return nil,
            "FILE DOES NOT EXIST"
    end

    local file =
        fs.open(
            path,
            "r"
        )

    if file == nil then
        return nil,
            "COULD NOT OPEN FILE"
    end

    local contents =
        file.readAll()

    file.close()

    local data =
        textutils.unserialize(
            contents
        )

    if type(data) ~= "table" then
        return nil,
            "FILE DATA IS INVALID"
    end

    return data
end

local function writeSerialized(
    path,
    data
)
    local temporaryPath =
        path
        .. ".tmp"

    if fs.exists(
        temporaryPath
    )
    then
        fs.delete(
            temporaryPath
        )
    end

    local file =
        fs.open(
            temporaryPath,
            "w"
        )

    if file == nil then
        return false,
            "COULD NOT OPEN TEMPORARY FILE"
    end

    file.write(
        textutils.serialize(
            data
        )
    )

    file.close()

    if fs.exists(path) then
        fs.delete(path)
    end

    fs.move(
        temporaryPath,
        path
    )

    return true
end

--------------------------------------------------
-- Transaction log
--------------------------------------------------

local function writeTransaction(
    username,
    transaction
)
    ensureDirectories()

    local path =
        getTransactionPath(
            username
        )

    local file =
        fs.open(
            path,
            "a"
        )

    if file == nil then
        return false,
            "COULD NOT OPEN TRANSACTION LOG"
    end

    file.writeLine(
        textutils.serialize(
            transaction,
            {
                compact = true
            }
        )
    )

    file.close()

    return true
end

local function createTransaction(
    account,
    transactionType,
    amount,
    details
)
    details =
        details
        or {}

    return {
        id =
            tostring(
                currentTime()
            )
            .. "-"
            .. tostring(
                math.random(
                    100000,
                    999999
                )
            ),

        timestamp =
            currentTime(),

        username =
            account.username,

        type =
            transactionType,

        amount =
            amount,

        balance =
            account.balance,

        machineId =
            details.machineId,

        machineType =
            details.machineType,

        game =
            details.game,

        note =
            details.note
    }
end

--------------------------------------------------
-- Public initialization
--------------------------------------------------

function accountStore.initialize()
    ensureDirectories()

    return true
end

--------------------------------------------------
-- Save account
--------------------------------------------------

function accountStore.save(account)
    if type(account) ~= "table" then
        return false,
            "INVALID ACCOUNT"
    end

    if not isValidUsername(
        account.username
    )
    then
        return false,
            "INVALID USERNAME"
    end

    ensureDirectories()

    account.updatedAt =
        currentTime()

    return writeSerialized(
        getAccountPath(
            account.username
        ),
        account
    )
end

--------------------------------------------------
-- Load or create account
--------------------------------------------------

function accountStore.load(username)
    if not isValidUsername(username) then
        return nil,
            "INVALID USERNAME"
    end

    ensureDirectories()

    local path =
        getAccountPath(username)

    if not fs.exists(path) then
        local account =
            createDefaultAccount(
                username
            )

        local saved, problem =
            accountStore.save(
                account
            )

        if not saved then
            return nil,
                problem
        end

        writeTransaction(
            username,
            createTransaction(
                account,
                "account_created",
                STARTING_BALANCE,
                {
                    note =
                        "New player account"
                }
            )
        )

        return copyTable(
            account
        )
    end

    local loaded, problem =
        readSerialized(path)

    if loaded == nil then
        return nil,
            problem
    end

    local account =
        repairAccount(
            username,
            loaded
        )

    local saved, saveProblem =
        accountStore.save(
            account
        )

    if not saved then
        return nil,
            saveProblem
    end

    return copyTable(
        account
    )
end

--------------------------------------------------
-- Check whether an account exists
--------------------------------------------------

function accountStore.exists(username)
    if not isValidUsername(username) then
        return false
    end

    return fs.exists(
        getAccountPath(username)
    )
end

--------------------------------------------------
-- Get balance
--------------------------------------------------

function accountStore.getBalance(username)
    local account, problem =
        accountStore.load(
            username
        )

    if account == nil then
        return nil,
            problem
    end

    return account.balance
end

--------------------------------------------------
-- Deposit credits
--------------------------------------------------

function accountStore.deposit(
    username,
    amount,
    details
)
    amount =
        normalizeAmount(amount)

    if amount == nil then
        return false,
            "INVALID AMOUNT"
    end

    local account, problem =
        accountStore.load(
            username
        )

    if account == nil then
        return false,
            problem
    end

    account.balance =
        account.balance
        + amount

    account.stats.totalWon =
        account.stats.totalWon
        + amount

    if amount
        > account.stats.biggestWin
    then
        account.stats.biggestWin =
            amount
    end

    if details
    and details.machineId
    then
        account.lastMachineId =
            details.machineId
    end

    local saved, saveProblem =
        accountStore.save(
            account
        )

    if not saved then
        return false,
            saveProblem
    end

    local transaction =
        createTransaction(
            account,
            "deposit",
            amount,
            details
        )

    writeTransaction(
        username,
        transaction
    )

    return true,
        account.balance,
        transaction
end

--------------------------------------------------
-- Withdraw credits
--------------------------------------------------

function accountStore.withdraw(
    username,
    amount,
    details
)
    amount =
        normalizeAmount(amount)

    if amount == nil then
        return false,
            "INVALID AMOUNT"
    end

    local account, problem =
        accountStore.load(
            username
        )

    if account == nil then
        return false,
            problem
    end

    if account.balance < amount then
        return false,
            "INSUFFICIENT FUNDS",
            account.balance
    end

    account.balance =
        account.balance
        - amount

    account.stats.totalLost =
        account.stats.totalLost
        + amount

    account.stats.totalBet =
        account.stats.totalBet
        + amount

    if details
    and details.machineId
    then
        account.lastMachineId =
            details.machineId
    end

    local saved, saveProblem =
        accountStore.save(
            account
        )

    if not saved then
        return false,
            saveProblem
    end

    local transaction =
        createTransaction(
            account,
            "withdraw",
            amount,
            details
        )

    writeTransaction(
        username,
        transaction
    )

    return true,
        account.balance,
        transaction
end

--------------------------------------------------
-- Record a played game
--------------------------------------------------

function accountStore.recordGame(
    username,
    gameName
)
    local account, problem =
        accountStore.load(
            username
        )

    if account == nil then
        return false,
            problem
    end

    account.stats.gamesPlayed =
        account.stats.gamesPlayed
        + 1

    if gameName == "slots" then
        account.stats.slotsPlayed =
            account.stats.slotsPlayed
            + 1

    elseif gameName == "blackjack" then
        account.stats.blackjackPlayed =
            account.stats.blackjackPlayed
            + 1

    elseif gameName == "roulette" then
        account.stats.roulettePlayed =
            account.stats.roulettePlayed
            + 1
    end

    return accountStore.save(
        account
    )
end

--------------------------------------------------
-- Get account information
--------------------------------------------------

function accountStore.getAccount(username)
    local account, problem =
        accountStore.load(
            username
        )

    if account == nil then
        return nil,
            problem
    end

    return copyTable(
        account
    )
end

--------------------------------------------------
-- Get account statistics
--------------------------------------------------

function accountStore.getStats(username)
    local account, problem =
        accountStore.load(
            username
        )

    if account == nil then
        return nil,
            problem
    end

    return copyTable(
        account.stats
    )
end

--------------------------------------------------
-- Reset account
--------------------------------------------------

function accountStore.reset(username)
    if not isValidUsername(username) then
        return false,
            "INVALID USERNAME"
    end

    local account =
        createDefaultAccount(
            username
        )

    local saved, problem =
        accountStore.save(
            account
        )

    if not saved then
        return false,
            problem
    end

    writeTransaction(
        username,
        createTransaction(
            account,
            "account_reset",
            STARTING_BALANCE,
            {
                note =
                    "Account reset"
            }
        )
    )

    return true,
        copyTable(account)
end

--------------------------------------------------
-- Return module
--------------------------------------------------

return accountStore
