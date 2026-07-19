--================================================--
-- Casino Royal
-- Version: 3.0.0
-- File: startup.lua
-- Description: Automatic machine role launcher
--================================================--

local machine = require("core.machine")
local logger = require("core.logger")

--------------------------------------------------
-- Terminal helpers
--------------------------------------------------

local function clearTerminal()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function centerText(y, text, color)
    local width, _ = term.getSize()

    text = tostring(text or "")

    local x =
        math.floor((width - #text) / 2) + 1

    term.setCursorPos(math.max(1, x), y)

    if color then
        term.setTextColor(color)
    end

    term.write(text)

    term.setTextColor(colors.white)
end

--------------------------------------------------
-- Boot Screen
--------------------------------------------------

local function showBoot(config)
    clearTerminal()

    centerText(2, "CASINO ROYAL", colors.yellow)
    centerText(4, config.name, colors.cyan)
    centerText(6, "TYPE: "..string.upper(config.type), colors.lightGray)
    centerText(8, "STARTING...", colors.lime)

    sleep(1)
end

--------------------------------------------------
-- Error Screen
--------------------------------------------------

local function showError(message)
    clearTerminal()

    centerText(2, "CASINO ROYAL", colors.yellow)
    centerText(4, "STARTUP ERROR", colors.red)

    term.setCursorPos(1, 7)

    print(tostring(message or "Unknown startup error"))
    print("")
    print("Run 'setup' to configure this machine.")
end

--------------------------------------------------
-- File exists?
--------------------------------------------------

local function exists(path)
    return fs.exists(path) and not fs.isDir(path)
end

--------------------------------------------------
-- Launch program
--------------------------------------------------

local function launch(config)

    local programs = {
        menu = "casino.lua",
        slots = "games/slots.lua",
        blackjack = "blackjack.lua",
        roulette = "roulette.lua",
        higher_lower = "higher_lower.lua",
        video_poker = "video_poker.lua",
        craps = "craps.lua",
        atm = "atm.lua",
        admin = "admin.lua",
        server = "server.lua"
    }

    local program = programs[config.type]

    if not program then
        return false,
            "Unknown machine type: "..tostring(config.type)
    end

    if not exists(program) then
        return false,
            "Program not found: "..program
    end

    logger.info(
        "Launching "..config.type
    )

    local ok =
        shell.run(program)

    if not ok then
        return false,
            "Program stopped or failed: "..program
    end

    return true
end

--------------------------------------------------
-- Main
--------------------------------------------------

local function main()

    logger.info(
        "Casino Royal Boot"
    )

    local config, err =
        machine.load()

    if not config then
        showError(err)
        return
    end

    if config.enabled == false then
        clearTerminal()

        centerText(3,
            "MACHINE DISABLED",
            colors.red)

        return
    end

    showBoot(config)

    local ok, problem =
        launch(config)

    if not ok then
        logger.error(problem)
        showError(problem)
    end
end

--------------------------------------------------
-- Safe Start
--------------------------------------------------

local ok, err =
    pcall(main)

if not ok then
    logger.error(err)
    showError(err)
end
