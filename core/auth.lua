local auth = {}

local players = require("core.players")

local CARD_ITEM = "mffs:id_card"
local preferredReader = "front"
local currentProfile = nil
local currentCardHash = nil

local function isInventory(name)
    local wrapped = peripheral.wrap(name)
    return wrapped ~= nil and type(wrapped.list) == "function"
end

local function getReader()
    if preferredReader and peripheral.isPresent(preferredReader) and isInventory(preferredReader) then
        return peripheral.wrap(preferredReader), preferredReader
    end

    for _, name in ipairs(peripheral.getNames()) do
        if isInventory(name) then
            return peripheral.wrap(name), name
        end
    end

    return nil, nil
end

local function findCard()
    local reader, readerName = getReader()
    if not reader then
        return nil, "CARD READER NOT FOUND"
    end

    local ok, items = pcall(reader.list)
    if not ok or type(items) ~= "table" then
        return nil, "CARD READER UNAVAILABLE"
    end

    local found = nil
    for slot, item in pairs(items) do
        if item.name == CARD_ITEM then
            if found then
                return nil, "INSERT ONLY ONE ID CARD"
            end
            if type(item.nbt) ~= "string" or item.nbt == "" then
                return nil, "ID CARD IS NOT ASSIGNED"
            end
            found = {
                hash = item.nbt,
                slot = slot,
                reader = readerName
            }
        end
    end

    if not found then
        return nil, "INSERT MFFS ID CARD"
    end

    return found
end

function auth.setReader(name)
    if type(name) ~= "string" or name == "" then return false end
    preferredReader = name
    return true
end

function auth.getReaderName()
    return preferredReader
end

function auth.readCard()
    return findCard()
end

function auth.registerCurrentCard(profile)
    profile = profile or players.getActive()
    if not profile then
        return false, "BANK MEMORY CARD REQUIRED"
    end

    local card, problem = findCard()
    if not card then return false, problem end

    local existing = players.getByCard(card.hash)
    if existing and existing.id ~= profile.id then
        return false, "CARD BELONGS TO ANOTHER MEMBER"
    end

    local ok, status = players.bindCard(profile, card.hash)
    if not ok then return false, status end

    currentProfile = profile
    currentCardHash = card.hash
    return true, "CASINO ID REGISTERED"
end

function auth.login()
    local card, problem = findCard()
    if not card then
        currentProfile = nil
        currentCardHash = nil
        return false, nil, problem
    end

    local profile = players.getByCard(card.hash)
    if not profile then
        currentProfile = nil
        currentCardHash = nil
        return false, nil, "UNREGISTERED CASINO ID"
    end

    currentProfile = profile
    currentCardHash = card.hash
    return true, profile, "ACCESS GRANTED"
end

function auth.logout()
    currentProfile = nil
    currentCardHash = nil
end

function auth.current()
    return currentProfile
end

function auth.cardHash()
    return currentCardHash
end

function auth.isLoggedIn()
    return currentProfile ~= nil
end

function auth.validateSession()
    if not currentCardHash then return false end
    local card = findCard()
    if not card or card.hash ~= currentCardHash then
        auth.logout()
        return false
    end
    return true
end

return auth
