--================================================--
-- Casino Royal
-- Version: 2.1.0
-- File: casino.lua
-- Description: Player login and application controller
--================================================--

local logger =
    require("core.logger")

local menu =
    require("games.menu")

local display =
    require("core.display")

local ui =
    require("core.ui")

local player =
    require("core.player")

local bank =
    require("core.bank")

--------------------------------------------------
-- Settings
--------------------------------------------------

local monitorSide = "top"
local checkDelay = 0.5

local casinoOpen = false
local lastStatus = nil

--------------------------------------------------
-- Show waiting screen
--------------------------------------------------

local function showWaiting(message)
    ui.clearButton()
    display.clear()
    display.border()

    display.center(
        2,
        "CASINO ROYAL"
    )

    display.center(
        5,
        "WAITING FOR PLAYER"
    )

    display.center(
        7,
        message
        or "APPROACH THE CASINO"
    )

    display.center(
        9,
        "RANGE: "
        .. player.getRange()
        .. " BLOCKS"
    )
end

--------------------------------------------------
-- Show login message
--------------------------------------------------

local function showWelcome(username)
    ui.clearButton()
    display.clear()
    display.border()

    display.center(
        2,
        "CASINO ROYAL"
    )

    display.center(
        5,
        "WELCOME"
    )

    display.center(
        7,
        username
    )

    display.center(
        9,
        "LOADING ACCOUNT..."
    )
end

--------------------------------------------------
-- Show logout message
--------------------------------------------------

local function showLogout(username)
    ui.clearButton()
    display.clear()
    display.border()

    display.center(
        4,
        "PLAYER LEFT"
    )

    display.center(
        6,
        username
    )

    display.center(
        8,
        "SAVING ACCOUNT..."
    )
end

--------------------------------------------------
-- Attempt player login
--------------------------------------------------

local function attemptLogin()
    local success, result =
        player.login()

    if not success then
        if result ~= lastStatus then
            showWaiting(result)
            lastStatus = result
        end

        return
    end

    local username = result

    showWelcome(username)

    local loaded, loadResult =
        bank.loadPlayer()

    if not loaded then
        player.logout()

        showWaiting(
            loadResult
            or "ACCOUNT LOAD FAILED"
        )

        lastStatus =
            loadResult

        return
    end

    logger.info(
        "Player logged in: "
        .. username
    )

    sleep(1)

    casinoOpen = true
    lastStatus = nil

    menu.open()
end

--------------------------------------------------
-- Log out active player
--------------------------------------------------

local function logoutPlayer()
    local username =
        player.getName()
        or "UNKNOWN"

    showLogout(username)

    bank.unload()
    player.logout()

    casinoOpen = false

    logger.info(
        "Player logged out: "
        .. username
    )

    sleep(1)

    showWaiting(
        "APPROACH THE CASINO"
    )

    lastStatus = nil
end

--------------------------------------------------
-- Initialize casino
--------------------------------------------------

logger.info(
    "Casino Application Starting"
)

display.init()

showWaiting(
    "APPROACH THE CASINO"
)

--------------------------------------------------
-- Touchscreen loop
--------------------------------------------------

local function touchscreenLoop()
    while true do
        local event, side, x, y =
            os.pullEvent("monitor_touch")

        if casinoOpen
        and side == monitorSide
        then
            ui.handleTouch(
                x,
                y
            )
        end
    end
end

--------------------------------------------------
-- Player detection loop
--------------------------------------------------

local function playerDetectionLoop()
    while true do
        if player.isLoggedIn() then
            if not player.isStillNearby() then
                logoutPlayer()
            end
        else
            attemptLogin()
        end

        sleep(checkDelay)
    end
end

--------------------------------------------------
-- Run casino systems simultaneously
--------------------------------------------------

local function runCasino()
    parallel.waitForAll(
        touchscreenLoop,
        playerDetectionLoop
    )
end

--------------------------------------------------
-- Safe shutdown
--------------------------------------------------

local success, problem =
    pcall(runCasino)

bank.unload()
player.logout()
display.clear()

if not success then
    error(
        problem,
        0
    )
end
