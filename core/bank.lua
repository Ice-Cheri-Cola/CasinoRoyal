--================================================--
-- Casino Royal
-- Version: 4.1.0
-- File: core/bank.lua
-- Description: Central bank network client
--================================================--

local player =
    require("core.player")

local network =
    require("core.network")

local protocol =
    require("core.protocol")

local machine =
    require("core.machine")

local bank = {}

--------------------------------------------------
-- Settings
--------------------------------------------------

local RESPONSE_TIMEOUT =
    4

--------------------------------------------------
-- Cached account information
--------------------------------------------------

local loadedUsername =
    nil

local cachedAccount =
    nil

local cachedBalance =
    0

local cachedStats =
    nil

local lastError =
    nil

--------------------------------------------------
-- Time
--------------------------------------------------

local function currentTime()
    return os.epoch("utc")
end

--------------------------------------------------
-- Copy tables
--------------------------------------------------

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

--------------------------------------------------
-- Clear cached account
--------------------------------------------------

local function clearCache()
    loadedUsername =
        nil

    cachedAccount =
        nil

    cachedBalance =
        0

    cachedStats =
        nil

    lastError =
        nil
end

--------------------------------------------------
-- Validate active player
--------------------------------------------------

local function getActiveUsername()
    local username =
        player.getName()

    if type(username) ~= "string"
    or username == ""
    then
        return nil,
            "NO PLAYER LOGGED IN"
    end

    return username
end

--------------------------------------------------
-- Create request data
--------------------------------------------------

local function createRequestData(
    username,
    extra
)
    local data = {
        username =
            username,

        machineId =
            machine.getId(),

        machineType =
            machine.getType()
    }

    if type(extra) == "table" then
        for key, value
            in pairs(extra)
        do
            data[key] =
                value
        end
    end

    return data
end

--------------------------------------------------
-- Wait for a server response
--------------------------------------------------

local function waitForReply(
    serverId,
    expectedType
)
    local deadline =
        currentTime()
        + (
            RESPONSE_TIMEOUT
            * 1000
        )

    while currentTime() < deadline do
        local remaining =
            (
                deadline
                - currentTime()
            ) / 1000

        local senderId, message =
            network.receive(
                math.max(
                    0.1,
                    remaining
                )
            )

        if senderId ~= nil
        and message ~= nil
        and senderId == serverId
        and message.type == expectedType
        then
            return message.data
                or {}
        end
    end

    return nil,
        "SERVER RESPONSE TIMEOUT"
end

--------------------------------------------------
-- Send request to central server
--------------------------------------------------

local function request(
    requestType,
    replyType,
    data
)
    local serverId, findProblem =
        network.findServer()

    if serverId == nil then
        lastError =
            findProblem
            or "CASINO SERVER NOT FOUND"

        return nil,
            lastError
    end

    local sent, sendProblem =
        network.send(
            serverId,
            requestType,
            data
        )

    if not sent then
        lastError =
            sendProblem
            or "BANK REQUEST COULD NOT BE SENT"

        return nil,
            lastError
    end

    local reply, replyProblem =
        waitForReply(
            serverId,
            replyType
        )

    if reply == nil then
        lastError =
            replyProblem
            or "BANK RESPONSE NOT RECEIVED"

        return nil,
            lastError
    end

    if reply.success ~= true then
        lastError =
            reply.error
            or reply.message
            or "BANK REQUEST FAILED"

        return nil,
            lastError,
            reply
    end

    lastError =
        nil

    return reply
end

--------------------------------------------------
-- Update cache from account
--------------------------------------------------

local function cacheAccount(account)
    if type(account) ~= "table" then
        return false
    end

    cachedAccount =
        copyTable(account)

    loadedUsername =
        account.username
        or loadedUsername

    if type(account.balance) == "number" then
        cachedBalance =
            account.balance
    end

    if type(account.stats) == "table" then
        cachedStats =
            copyTable(
                account.stats
            )
    end

    return true
end

--------------------------------------------------
-- Update cached balance
--------------------------------------------------

local function cacheBalance(balance)
    if type(balance) ~= "number" then
        return false
    end

    cachedBalance =
        balance

    if type(cachedAccount) == "table" then
        cachedAccount.balance =
            balance
    end

    return true
end

--------------------------------------------------
-- Ensure correct player is loaded
--------------------------------------------------

local function ensureLoaded()
    local username, problem =
        getActiveUsername()

    if username == nil then
        lastError =
            problem

        return false,
            problem
    end

    if loadedUsername ~= username
    or cachedAccount == nil
    then
        return bank.loadPlayer()
    end

    return true
end

--------------------------------------------------
-- Load active player's central account
--------------------------------------------------

function bank.loadPlayer()
    local username, problem =
        getActiveUsername()

    if username == nil then
        clearCache()

        return false,
            problem
    end

    local reply, requestProblem =
        request(
            protocol.ACCOUNT,
            protocol.ACCOUNT_REPLY,
            createRequestData(
                username
            )
        )

    if reply == nil then
        clearCache()

        lastError =
            requestProblem

        return false,
            requestProblem
    end

    if not cacheAccount(
        reply.account
    )
    then
        clearCache()

        lastError =
            "SERVER RETURNED INVALID ACCOUNT"

        return false,
            lastError
    end

    loadedUsername =
        username

    return true,
        copyTable(cachedAccount)
end

--------------------------------------------------
-- Refresh current balance
--------------------------------------------------

function bank.refreshBalance()
    local username, problem =
        getActiveUsername()

    if username == nil then
        lastError =
            problem

        return false,
            problem
    end

    local reply, requestProblem =
        request(
            protocol.BALANCE,
            protocol.BALANCE_REPLY,
            createRequestData(
                username
            )
        )

    if reply == nil then
        return false,
            requestProblem
    end

    if not cacheBalance(
        reply.balance
    )
    then
        lastError =
            "SERVER RETURNED INVALID BALANCE"

        return false,
            lastError
    end

    loadedUsername =
        username

    return true,
        cachedBalance
end

--------------------------------------------------
-- Get loaded username
--------------------------------------------------

function bank.getUsername()
    if not ensureLoaded() then
        return nil
    end

    return loadedUsername
end

--------------------------------------------------
-- Get cached balance
--------------------------------------------------

function bank.getBalance()
    if not ensureLoaded() then
        return 0
    end

    return cachedBalance
end

--------------------------------------------------
-- Check affordability
--------------------------------------------------

function bank.canAfford(amount)
    if not ensureLoaded() then
        return false
    end

    if type(amount) ~= "number"
    or amount < 0
    then
        return false
    end

    return cachedBalance
        >= amount
end

--------------------------------------------------
-- Deposit credits
--------------------------------------------------

function bank.add(
    amount,
    gameName,
    note
)
    if not ensureLoaded() then
        return false,
            lastError
    end

    if type(amount) ~= "number"
    or amount <= 0
    then
        return false,
            "INVALID AMOUNT"
    end

    local reply, problem =
        request(
            protocol.DEPOSIT,
            protocol.DEPOSIT_REPLY,
            createRequestData(
                loadedUsername,
                {
                    amount =
                        amount,

                    game =
                        gameName,

                    note =
                        note
                        or "Game payout"
                }
            )
        )

    if reply == nil then
        return false,
            problem
    end

    if not cacheBalance(
        reply.balance
    )
    then
        lastError =
            "SERVER RETURNED INVALID BALANCE"

        return false,
            lastError
    end

    return true,
        cachedBalance
end

--------------------------------------------------
-- Withdraw credits
--------------------------------------------------

function bank.spend(
    amount,
    gameName,
    note
)
    if not ensureLoaded() then
        return false,
            lastError
    end

    if type(amount) ~= "number"
    or amount <= 0
    then
        return false,
            "INVALID AMOUNT"
    end

    local reply, problem, errorReply =
        request(
            protocol.WITHDRAW,
            protocol.WITHDRAW_REPLY,
            createRequestData(
                loadedUsername,
                {
                    amount =
                        amount,

                    game =
                        gameName,

                    note =
                        note
                        or "Game wager"
                }
            )
        )

    if reply == nil then
        if type(errorReply) == "table"
        and type(errorReply.balance)
            == "number"
        then
            cacheBalance(
                errorReply.balance
            )
        end

        return false,
            problem
    end

    if not cacheBalance(
        reply.balance
    )
    then
        lastError =
            "SERVER RETURNED INVALID BALANCE"

        return false,
            lastError
    end

    return true,
        cachedBalance
end

--------------------------------------------------
-- Record a played game
--------------------------------------------------

function bank.recordGame(gameName)
    if not ensureLoaded() then
        return false,
            lastError
    end

    if type(gameName) ~= "string"
    or gameName == ""
    then
        return false,
            "INVALID GAME"
    end

    local reply, problem =
        request(
            protocol.RECORD_GAME,
            protocol.RECORD_GAME_REPLY,
            createRequestData(
                loadedUsername,
                {
                    game =
                        gameName
                }
            )
        )

    if reply == nil then
        return false,
            problem
    end

    if type(cachedStats) == "table" then
        cachedStats.gamesPlayed =
            (
                cachedStats.gamesPlayed
                or 0
            ) + 1

        if gameName == "slots" then
            cachedStats.slotsPlayed =
                (
                    cachedStats.slotsPlayed
                    or 0
                ) + 1

        elseif gameName == "blackjack" then
            cachedStats.blackjackPlayed =
                (
                    cachedStats.blackjackPlayed
                    or 0
                ) + 1

        elseif gameName == "roulette" then
            cachedStats.roulettePlayed =
                (
                    cachedStats.roulettePlayed
                    or 0
                ) + 1
        end
    end

    return true
end

--------------------------------------------------
-- Get account information
--------------------------------------------------

function bank.getAccount()
    if not ensureLoaded() then
        return nil
    end

    return copyTable(
        cachedAccount
    )
end

--------------------------------------------------
-- Get statistics
--------------------------------------------------

function bank.getStats()
    if not ensureLoaded() then
        return nil
    end

    return copyTable(
        cachedStats
    )
end

--------------------------------------------------
-- Last network error
--------------------------------------------------

function bank.getLastError()
    return lastError
end

--------------------------------------------------
-- Reset is server-controlled
--------------------------------------------------

function bank.reset()
    return false,
        "CENTRAL ACCOUNT RESET NOT AVAILABLE"
end

--------------------------------------------------
-- Unload account
--------------------------------------------------

function bank.unload()
    clearCache()

    return true
end

--------------------------------------------------
-- Return module
--------------------------------------------------

return bank
