--================================================--
-- Casino Royal
-- Version: 2.0.0
-- File: core/player.lua
-- Description: Player Detector login system
--================================================--

local player = {}

local detector = nil
local currentPlayer = nil
local detectionRange = 5

--------------------------------------------------
-- Find Player Detector
--------------------------------------------------

local function findDetector()
    if detector ~= nil then
        return detector
    end

    detector =
        peripheral.find(
            "player_detector"
        )

    if detector == nil then
        error(
            "Player Detector not found. "
            .. "Check the wired network."
        )
    end

    return detector
end

--------------------------------------------------
-- Get nearby players
--------------------------------------------------

function player.getNearbyPlayers()
    local device = findDetector()

    local nearby =
        device.getPlayersInRange(
            detectionRange
        )

    if nearby == nil then
        return {}
    end

    return nearby
end

--------------------------------------------------
-- Attempt login
--------------------------------------------------

function player.login()
    local nearby =
        player.getNearbyPlayers()

    if #nearby == 0 then
        return false,
            "NO PLAYER DETECTED"
    end

    if #nearby > 1 then
        return false,
            "ONLY ONE PLAYER MAY LOGIN"
    end

    currentPlayer = nearby[1]

    return true,
        currentPlayer
end

--------------------------------------------------
-- Logout
--------------------------------------------------

function player.logout()
    currentPlayer = nil
end

--------------------------------------------------
-- Get active username
--------------------------------------------------

function player.getName()
    return currentPlayer
end

--------------------------------------------------
-- Check login
--------------------------------------------------

function player.isLoggedIn()
    return currentPlayer ~= nil
end

--------------------------------------------------
-- Check whether active player remains nearby
--------------------------------------------------

function player.isStillNearby()
    if currentPlayer == nil then
        return false
    end

    local device =
        findDetector()

    return device.isPlayerInRange(
        detectionRange,
        currentPlayer
    )
end

--------------------------------------------------
-- Set detection distance
--------------------------------------------------

function player.setRange(range)
    if type(range) ~= "number"
    or range < 1
    then
        return false
    end

    detectionRange =
        math.floor(range)

    return true
end

--------------------------------------------------
-- Get detection distance
--------------------------------------------------

function player.getRange()
    return detectionRange
end

return player
