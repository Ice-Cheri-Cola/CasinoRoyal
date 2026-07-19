--================================================--
-- Casino Royal
-- Version: 3.0.0
-- File: startup.lua
-- Description: Automatic machine role launcher
--================================================--

local machine =
    require("core.machine")

local logger =
    require("core.logger")

--------------------------------------------------
-- Terminal helpers
--------------------------------------------------

local function clearTerminal()
    term.setBackgroundColor(
        colors.black
    )

    term.setTextColor(
        colors.white
    )

    term.clear()
    term.setCursorPos(1, 1)
end

local function centerText(y, text, color)
    local width =
        term.getSize()

    text =
        tostring(text or "")

    local x =
        math.floor(
            (width - #text) / 2
        ) + 1

    term.setCursorPos(
        math.max(1, x),
        y
    )

    if color then
        term.setTextColor(color)
    end

    term.write(text)

    term.setTextColor(
        colors.white
    )
end

--------------------------------------------------
-- Boot screen
--------------------------------------------------

local function showBoot(config)
    clearTerminal()

    centerText(
        2,
        "CASINO ROYAL",
        colors.yellow
    )

    centerText(
        4,
        config.name,
        colors.cyan
    )

    centerText(
        6,
        "TYPE: "
        .. string.upper(config.type),
        colors.lightGray
    )

    centerText(
        8,
        "STARTING...",
        colors.lime
    )

    sleep(1)
end

--------------------------------------------------
-- Error screen
--------------------------------------------------

local function showError(message)
    clearTerminal()

    centerText(
        2,
        "CASINO ROYAL",
        colors.yellow
    )

    centerText(
        4,
        "STARTUP ERROR",
        colors.red
    )

    term.setCursorPos(1, 7)

    print(
        tostring(
            message
            or "Unknown startup error"
        )
    )

    print()
    print(
        "Run 'setup' to change this machine."
    )
end

--------------------------------------------------
-- Find runnable program
--------------------------------------------------

local function programExists(path)
    return fs.exists(path)
        and not fs.isDir(path)
end

--------------------------------------------------
-- Run assigned program
--------------------------------------------------

local function launch(config)
    local programs = {
        menu = "casino.lua",
        slots = "terminals/slots.lua",
        blackjack = "terminals/blackjack.lua",
        roulette = "terminals/roulette.lua",
        higher_lower = "terminals/higher_lower.lua",
        video_poker = "terminals/video_poker.lua",
        craps = "terminals/craps.lua",
        atm = "terminals/atm.lua",
        admin = "admin.lua",
        server = "server.lua"
    }

    local program =
        programs[config.type]

    if program == nil then
        return false,
            "Unknown machine type: "
            .. tostring(config.type)
    end

    if not programExists(program) then
        return false,
            "Program not built yet: "
            .. program
    end

    logger.info(
        "Launching "
        .. config.name
        .. " as "
        .. config.type
    )

    local success =
        shell.run(program)

    if not success then
        return false,
            "Program stopped or failed: "
            .. program
    end

    return true
end

--------------------------------------------------
-- Startup sequence
--------------------------------------------------

local function start()
    logger.info(
        "Casino Royal booting"
    )

    local config, problem =
        machine.load()

    if config == nil then
        showError(
            problem
            or "Could not load machine configuration"
        )

        return
    end

    if config.enabled == false then
        clearTerminal()

        centerText(
            2,
            "CASINO ROYAL",
            colors.yellow
        )

        centerText(
            5,
            config.name,
            colors.cyan
        )

        centerText(
            7,
            "MACHINE DISABLED",
            colors.red
        )

        return
    end

    showBoot(config)

    local success, launchProblem =
        launch(config)

    if not success then
        logger.error(
            launchProblem
        )

        showError(
            launchProblem
        )
    end
end

--------------------------------------------------
-- Safe execution
--------------------------------------------------

local success, problem =
    pcall(start)

if not success then
    logger.error(
        tostring(problem)
    )

    showError(problem)
end
