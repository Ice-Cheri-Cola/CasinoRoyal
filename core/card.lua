--================================================--
-- Casino Royal
-- Version: 4.3.1
-- File: core/card.lua
-- Description: Programmable bank card disk support
--================================================--

local card = {}

local CARD_FILE = "casino_royal_card.txt"
local CARD_VERSION = 1

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function findDrive()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            local drive = peripheral.wrap(name)
            if drive then
                return name, drive
            end
        end
    end

    return nil, nil
end

local function callDrive(drive, methodName, ...)
    if not drive or type(drive[methodName]) ~= "function" then
        return false, nil
    end

    local ok, result = pcall(drive[methodName], ...)
    if not ok then
        return false, nil
    end

    return true, result
end

local function getMountPath()
    local driveName, drive = findDrive()
    if not drive then
        return nil, "NO DISK DRIVE FOUND"
    end

    local presentOk, present = callDrive(drive, "isDiskPresent")
    if not presentOk or present ~= true then
        return nil, "INSERT A FLOPPY DISK"
    end

    local mountOk, mountPath = callDrive(drive, "getMountPath")
    if not mountOk or not mountPath then
        return nil, "DISK IS NOT MOUNTED"
    end

    return mountPath, nil, driveName, drive
end

function card.getDriveName()
    local name = findDrive()
    return name
end

function card.isPresent()
    local _, drive = findDrive()
    if not drive then return false end

    local ok, present = callDrive(drive, "isDiskPresent")
    return ok and present == true
end

function card.getStatus()
    local name, drive = findDrive()
    if not drive then
        return false, "NO DISK DRIVE FOUND"
    end

    local ok, present = callDrive(drive, "isDiskPresent")
    if not ok or present ~= true then
        return false, "INSERT A FLOPPY DISK"
    end

    return true, name
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
    if type(data) ~= "table" then
        return false, "INVALID CARD DATA"
    end

    local username = trim(data.username)
    if username == "" then
        return false, "USERNAME IS REQUIRED"
    end

    local mountPath, problem, _, drive = getMountPath()
    if not mountPath then
        return false, problem
    end

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
    if not file then
        return false, "COULD NOT WRITE BANK CARD"
    end

    file.write(textutils.serialize(cardData))
    file.close()

    callDrive(drive, "setDiskLabel", "Casino Royal - " .. username)

    return true, cardData
end

function card.read()
    local mountPath, problem = getMountPath()
    if not mountPath then
        return nil, problem
    end

    local path = fs.combine(mountPath, CARD_FILE)
    if not fs.exists(path) then
        return nil, "NOT A CASINO ROYAL CARD"
    end

    local file = fs.open(path, "r")
    if not file then
        return nil, "COULD NOT READ BANK CARD"
    end

    local contents = file.readAll()
    file.close()

    local data = textutils.unserialize(contents)
    if type(data) ~= "table" or data.format ~= "casino_royal_card" then
        return nil, "INVALID BANK CARD"
    end

    if data.active == false then
        return nil, "BANK CARD IS DISABLED"
    end

    data.username = trim(data.username)
    if data.username == "" then
        return nil, "BANK CARD HAS NO OWNER"
    end

    return data
end

function card.disable()
    local data, problem = card.read()
    if not data then
        return false, problem
    end

    data.active = false
    return card.write(data)
end

function card.getFilename()
    return CARD_FILE
end

return card