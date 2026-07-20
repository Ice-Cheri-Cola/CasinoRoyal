--================================================--
-- Casino Royal
-- Version: 4.3.0
-- File: core/card.lua
-- Description: Programmable bank card disk support
--================================================--

local card = {}

local CARD_FILE = "casino_royal_card.txt"
local CARD_VERSION = 1

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function findDriveName()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            return name
        end
    end

    return nil
end

local function getMountPath(driveName)
    if not driveName then return nil, "NO DISK DRIVE FOUND" end
    if not disk.isPresent(driveName) then return nil, "INSERT A FLOPPY DISK" end

    local mountPath = disk.getMountPath(driveName)
    if not mountPath then return nil, "DISK IS NOT MOUNTED" end

    return mountPath
end

function card.getDriveName()
    return findDriveName()
end

function card.isPresent()
    local driveName = findDriveName()
    return driveName ~= nil and disk.isPresent(driveName)
end

function card.createId(username)
    local safeName = trim(username):gsub("[^%w_]", "_"):lower()
    return string.format(
        "CR-%s-%d-%d",
        safeName,
        os.getComputerID(),
        os.epoch("utc")
    )
end

function card.write(data)
    if type(data) ~= "table" then return false, "INVALID CARD DATA" end

    local username = trim(data.username)
    if username == "" then return false, "USERNAME IS REQUIRED" end

    local driveName = findDriveName()
    local mountPath, problem = getMountPath(driveName)
    if not mountPath then return false, problem end

    local cardData = {
        format = "casino_royal_card",
        version = CARD_VERSION,
        id = trim(data.id) ~= "" and trim(data.id) or card.createId(username),
        username = username,
        account = trim(data.account) ~= "" and trim(data.account) or username,
        tier = trim(data.tier) ~= "" and trim(data.tier) or "Standard",
        active = data.active ~= false,
        issuedAt = tonumber(data.issuedAt) or os.epoch("utc"),
        issuedBy = trim(data.issuedBy) ~= "" and trim(data.issuedBy) or os.getComputerLabel()
    }

    local path = fs.combine(mountPath, CARD_FILE)
    local file = fs.open(path, "w")
    if not file then return false, "COULD NOT WRITE BANK CARD" end

    file.write(textutils.serialize(cardData))
    file.close()

    disk.setLabel(driveName, "Casino Royal - " .. username)

    return true, cardData
end

function card.read()
    local driveName = findDriveName()
    local mountPath, problem = getMountPath(driveName)
    if not mountPath then return nil, problem end

    local path = fs.combine(mountPath, CARD_FILE)
    if not fs.exists(path) then return nil, "NOT A CASINO ROYAL CARD" end

    local file = fs.open(path, "r")
    if not file then return nil, "COULD NOT READ BANK CARD" end

    local contents = file.readAll()
    file.close()

    local data = textutils.unserialize(contents)
    if type(data) ~= "table" or data.format ~= "casino_royal_card" then
        return nil, "INVALID BANK CARD"
    end

    if data.active == false then return nil, "BANK CARD IS DISABLED" end

    data.username = trim(data.username)
    if data.username == "" then return nil, "BANK CARD HAS NO OWNER" end

    return data
end

function card.disable()
    local data, problem = card.read()
    if not data then return false, problem end

    data.active = false
    return card.write(data)
end

function card.getFilename()
    return CARD_FILE
end

return card
