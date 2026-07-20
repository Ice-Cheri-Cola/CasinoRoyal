--================================================--
-- Casino Royal
-- Version: 4.2.0
-- File: core/player.lua
-- Description: Player Detector and bank card login system
--================================================--

local player = {}
local hardware = require("core.hardware")

local currentPlayer = nil
local detectionRange = 2
local loginMethod = nil

local function getDetector()
    return hardware.getPlayerDetector()
end

function player.getNearbyPlayers()
    local detector = getDetector()
    if not detector then return {} end

    local ok, nearby = pcall(
        detector.getPlayersInRange,
        detectionRange
    )

    if not ok or type(nearby) ~= "table" then
        return {}
    end

    return nearby
end

function player.login()
    local nearby = player.getNearbyPlayers()

    if #nearby == 0 then
        return false, "NO PLAYER DETECTED"
    end

    if #nearby > 1 then
        return false, "ONLY ONE PLAYER MAY LOGIN"
    end

    currentPlayer = nearby[1]
    loginMethod = "detector"

    return true, currentPlayer
end

-- Used by trusted terminals after reading a Casino Royal bank card.
function player.loginAs(username)
    if type(username) ~= "string" then
        return false, "INVALID CARD USERNAME"
    end

    username = username:match("^%s*(.-)%s*$")
    if username == "" then
        return false, "INVALID CARD USERNAME"
    end

    currentPlayer = username
    loginMethod = "card"

    return true, currentPlayer
end

function player.logout()
    currentPlayer = nil
    loginMethod = nil
end

function player.getName()
    return currentPlayer
end

function player.getLoginMethod()
    return loginMethod
end

function player.isLoggedIn()
    return currentPlayer ~= nil
end

function player.isStillNearby()
    if currentPlayer == nil then return false end

    -- Card sessions do not depend on the player detector. The ATM handles
    -- their shorter timeout and explicit logout separately.
    if loginMethod == "card" then
        return true
    end

    local detector = getDetector()
    if not detector then return false end

    local ok, result = pcall(
        detector.isPlayerInRange,
        detectionRange,
        currentPlayer
    )

    return ok and result == true
end

function player.setRange(range)
    if type(range) ~= "number" or range < 1 then
        return false
    end

    detectionRange = math.floor(range)
    return true
end

function player.getRange()
    return detectionRange
end

return player
