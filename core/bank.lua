--================================================--
-- Casino Royal
-- Version: 2.0.0
-- File: core/bank.lua
-- Description: Per-player Royal Credits accounts
--================================================--

local player =
    require("core.player")

local bank = {}

local saveRoot =
    "data/players"

local accountFileName =
    "account.txt"

local startingBalance =
    100

local currentAccount =
    nil

local loadedUsername =
    nil

--------------------------------------------------
-- Default account
--------------------------------------------------

local function createDefaultAccount()
    return {
        balance =
            startingBalance,

        stats = {
            gamesPlayed = 0,
            slotsPlayed = 0,
            blackjackPlayed = 0,
            totalWon = 0,
            totalLost = 0,
            biggestWin = 0
        }
    }
end

--------------------------------------------------
-- Safe username for file path
--------------------------------------------------

local function safeUsername(username)
    return tostring(username):gsub(
        "[^%w_%-%._]",
        "_"
    )
end

--------------------------------------------------
-- Account folder
--------------------------------------------------

local function getAccountFolder(
    username
)
    return saveRoot
        .. "/"
        .. safeUsername(username)
end

--------------------------------------------------
-- Account file
--------------------------------------------------

local function getAccountFile(
    username
)
    return getAccountFolder(username)
        .. "/"
        .. accountFileName
end

--------------------------------------------------
-- Ensure folders exist
--------------------------------------------------

local function ensureFolders(
    username
)
    if not fs.exists("data") then
        fs.makeDir("data")
    end

    if not fs.exists(saveRoot) then
        fs.makeDir(saveRoot)
    end

    local folder =
        getAccountFolder(username)

    if not fs.exists(folder) then
        fs.makeDir(folder)
    end
end

--------------------------------------------------
-- Save current account
--------------------------------------------------

local function save()
    if loadedUsername == nil
    or currentAccount == nil
    then
        return false
    end

    ensureFolders(
        loadedUsername
    )

    local file =
        fs.open(
            getAccountFile(
                loadedUsername
            ),
            "w"
        )

    if file == nil then
        return false
    end

    file.write(
        textutils.serialize(
            currentAccount
        )
    )

    file.close()

    return true
end

--------------------------------------------------
-- Repair older or incomplete account data
--------------------------------------------------

local function repairAccount(
    account
)
    if type(account) ~= "table" then
        account =
            createDefaultAccount()
    end

    if type(account.balance)
        ~= "number"
    then
        account.balance =
            startingBalance
    end

    if type(account.stats)
        ~= "table"
    then
        account.stats = {}
    end

    local defaults =
        createDefaultAccount().stats

    for key, value
        in pairs(defaults)
    do
        if type(
            account.stats[key]
        ) ~= "number"
        then
            account.stats[key] =
                value
        end
    end

    return account
end

--------------------------------------------------
-- Load account for logged-in player
--------------------------------------------------

function bank.loadPlayer()
    local username =
        player.getName()

    if username == nil then
        currentAccount = nil
        loadedUsername = nil

        return false,
            "NO PLAYER LOGGED IN"
    end

    ensureFolders(username)

    local accountFile =
        getAccountFile(username)

    if not fs.exists(accountFile) then
        currentAccount =
            createDefaultAccount()

        loadedUsername =
            username

        save()

        return true,
            currentAccount
    end

    local file =
        fs.open(
            accountFile,
            "r"
        )

    if file == nil then
        return false,
            "COULD NOT OPEN ACCOUNT"
    end

    local contents =
        file.readAll()

    file.close()

    local loaded =
        textutils.unserialize(
            contents
        )

    currentAccount =
        repairAccount(loaded)

    loadedUsername =
        username

    save()

    return true,
        currentAccount
end

--------------------------------------------------
-- Ensure correct account is loaded
--------------------------------------------------

local function ensureLoaded()
    local username =
        player.getName()

    if username == nil then
        return false
    end

    if loadedUsername ~= username
    or currentAccount == nil
    then
        local success =
            bank.loadPlayer()

        return success
    end

    return true
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
-- Get balance
--------------------------------------------------

function bank.getBalance()
    if not ensureLoaded() then
        return 0
    end

    return currentAccount.balance
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

    return currentAccount.balance
        >= amount
end

--------------------------------------------------
-- Add credits
--------------------------------------------------

function bank.add(amount)
    if not ensureLoaded() then
        return false
    end

    if type(amount) ~= "number"
    or amount <= 0
    then
        return false
    end

    currentAccount.balance =
        currentAccount.balance
        + amount

    currentAccount.stats.totalWon =
        currentAccount.stats.totalWon
        + amount

    if amount
        > currentAccount.stats.biggestWin
    then
        currentAccount.stats.biggestWin =
            amount
    end

    return save()
end

--------------------------------------------------
-- Spend credits
--------------------------------------------------

function bank.spend(amount)
    if not ensureLoaded() then
        return false
    end

    if type(amount) ~= "number"
    or amount <= 0
    then
        return false
    end

    if currentAccount.balance
        < amount
    then
        return false
    end

    currentAccount.balance =
        currentAccount.balance
        - amount

    currentAccount.stats.totalLost =
        currentAccount.stats.totalLost
        + amount

    return save()
end

--------------------------------------------------
-- Record a game
--------------------------------------------------

function bank.recordGame(
    gameName
)
    if not ensureLoaded() then
        return false
    end

    currentAccount.stats.gamesPlayed =
        currentAccount.stats.gamesPlayed
        + 1

    if gameName == "slots" then
        currentAccount.stats.slotsPlayed =
            currentAccount.stats.slotsPlayed
            + 1

    elseif gameName == "blackjack" then
        currentAccount.stats.blackjackPlayed =
            currentAccount.stats.blackjackPlayed
            + 1
    end

    return save()
end

--------------------------------------------------
-- Get statistics
--------------------------------------------------

function bank.getStats()
    if not ensureLoaded() then
        return nil
    end

    return currentAccount.stats
end

--------------------------------------------------
-- Reset current player's account
--------------------------------------------------

function bank.reset()
    if not ensureLoaded() then
        return false
    end

    currentAccount =
        createDefaultAccount()

    return save()
end

--------------------------------------------------
-- Save and unload account
--------------------------------------------------

function bank.unload()
    save()

    currentAccount = nil
    loadedUsername = nil
end

return bank
