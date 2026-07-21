local players = {}

local hardware = require("core.hardware")

local DATA_PATH = "data/players.db"
local database = { nextId = 1, profiles = {} }
local activeKey = nil

local RANKS = {
    { minimum = 250000, name = "HIGH ROLLER" },
    { minimum = 100000, name = "DIAMOND" },
    { minimum = 50000, name = "PLATINUM" },
    { minimum = 10000, name = "GOLD" },
    { minimum = 2500, name = "SILVER" },
    { minimum = 500, name = "BRONZE" },
    { minimum = 0, name = "MEMBER" }
}

local function ensureDirectory(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then fs.makeDir(directory) end
end

local function calculateRank(profile)
    local stats = type(profile.stats) == "table" and profile.stats or {}
    local deposited = math.max(0, math.floor(tonumber(stats.deposits) or 0))
    for _, rank in ipairs(RANKS) do
        if deposited >= rank.minimum then return rank.name end
    end
    return "MEMBER"
end

local function normalizeProfile(profile)
    profile = type(profile) == "table" and profile or {}
    profile.stats = type(profile.stats) == "table" and profile.stats or {}
    profile.stats.deposits = math.max(0, math.floor(tonumber(profile.stats.deposits) or 0))
    profile.stats.withdrawals = math.max(0, math.floor(tonumber(profile.stats.withdrawals) or 0))
    profile.stats.gamesPlayed = math.max(0, math.floor(tonumber(profile.stats.gamesPlayed) or 0))
    profile.stats.achievements = math.max(0, math.floor(tonumber(profile.stats.achievements) or 0))
    profile.visits = math.max(0, math.floor(tonumber(profile.visits) or 0))
    profile.rank = calculateRank(profile)
    return profile
end

local function normalizeDatabase(value)
    if type(value) ~= "table" then value = { nextId = 1, profiles = {} } end
    value.nextId = math.max(1, math.floor(tonumber(value.nextId) or 1))
    value.profiles = type(value.profiles) == "table" and value.profiles or {}
    for key, profile in pairs(value.profiles) do value.profiles[key] = normalizeProfile(profile) end
    return value
end

local function save()
    ensureDirectory(DATA_PATH)
    local handle = fs.open(DATA_PATH, "w")
    if not handle then return false, "COULD NOT SAVE PLAYER DATA" end
    handle.write(textutils.serialize(database))
    handle.close()
    return true
end

local function detectOwner()
    local manager = hardware.getInventoryManager()
    if not manager or not manager.getOwner then return nil, nil, "INVENTORY MANAGER OWNER UNAVAILABLE" end
    local ok, first, second = pcall(manager.getOwner)
    if not ok or first == nil then return nil, nil, "MEMORY CARD OWNER OFFLINE" end
    if type(second) == "string" and second ~= "" then return tostring(first), second end
    local username = tostring(first)
    return "name:" .. username:lower(), username
end

local function makeMemberId(number)
    return string.format("CR-M%05d", number)
end

local function createProfile(key, username, uuid)
    local now = os.epoch("utc")
    local profile = normalizeProfile({
        id = makeMemberId(database.nextId), uuid = uuid, username = username,
        displayName = username, joinedAt = now, lastSeenAt = now, visits = 1,
        stats = { deposits = 0, withdrawals = 0, gamesPlayed = 0, achievements = 0 }
    })
    database.nextId = database.nextId + 1
    database.profiles[key] = profile
    return profile
end

function players.load()
    if not fs.exists(DATA_PATH) then database = normalizeDatabase(nil) return database end
    local handle = fs.open(DATA_PATH, "r")
    if not handle then database = normalizeDatabase(nil) return database end
    local raw = handle.readAll()
    handle.close()
    local ok, decoded = pcall(textutils.unserialize, raw)
    database = normalizeDatabase(ok and decoded or nil)
    return database
end

function players.activateCurrent()
    local uuid, username, problem = detectOwner()
    if not username then activeKey = nil return false, nil, problem end
    local key = tostring(uuid or ("name:" .. username:lower()))
    local profile = database.profiles[key]
    if not profile then
        profile = createProfile(key, username, uuid)
    else
        profile = normalizeProfile(profile)
        profile.username = username
        profile.displayName = profile.displayName or username
        profile.lastSeenAt = os.epoch("utc")
        profile.visits = profile.visits + 1
    end
    activeKey = key
    local saved, saveProblem = save()
    if not saved then return false, profile, saveProblem end
    return true, profile, "PLAYER ACTIVE"
end

function players.getActive()
    if not activeKey then return nil end
    return database.profiles[activeKey]
end

function players.getById(memberId)
    for _, profile in pairs(database.profiles) do
        if profile.id == memberId then return profile end
    end
    return nil
end

function players.record(statName, amount)
    local profile = players.getActive()
    if not profile then return false, "NO ACTIVE PLAYER" end
    profile.stats = type(profile.stats) == "table" and profile.stats or {}
    amount = math.floor(tonumber(amount) or 1)
    profile.stats[statName] = math.max(0, math.floor(tonumber(profile.stats[statName]) or 0) + amount)
    profile.rank = calculateRank(profile)
    profile.lastSeenAt = os.epoch("utc")
    local ok, problem = save()
    if not ok then return false, problem end
    return true, profile.stats[statName], profile.rank
end

function players.getRankForDeposits(amount)
    return calculateRank({ stats = { deposits = amount } })
end

function players.all()
    return database.profiles
end

return players