--================================================--
-- Casino Royal
-- Version: 4.2.1
-- File: update.lua
-- Description: Downloads all Casino Royal files
--================================================--

local BASE_URL =
    "https://raw.githubusercontent.com/"
    .. "Ice-Cheri-Cola/CasinoRoyal/main/"

local FILES = {
    "startup.lua",
    "casino.lua",
    "setup.lua",
    "server.lua",
    "atm.lua",
    "config.lua",

    "core/account_store.lua",
    "core/bank.lua",
    "core/display.lua",
    "core/hardware.lua",
    "core/logger.lua",
    "core/machine.lua",
    "core/network.lua",
    "core/player.lua",
    "core/protocol.lua",
    "core/theme.lua",
    "core/ui.lua",

    "assets/themes.lua",

    "games/menu.lua",
    "games/slots.lua",

    "update.lua"
}

local function createParentDirectory(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function removeTemporaryFile(path)
    if fs.exists(path) then
        fs.delete(path)
    end
end

local function downloadFile(path)
    createParentDirectory(path)

    local url = BASE_URL .. path
    local temporaryPath = path .. ".download"

    removeTemporaryFile(temporaryPath)

    write("Updating " .. path .. "... ")

    local response, errorMessage = http.get(url)
    if not response then
        print("FAILED")
        print("  " .. tostring(errorMessage or "Unknown HTTP error"))
        return false
    end

    local content = response.readAll()
    response.close()

    if content == nil or content == "" then
        print("FAILED")
        print("  Download was empty")
        return false
    end

    local file = fs.open(temporaryPath, "w")
    if not file then
        print("FAILED")
        print("  Could not open temporary file")
        return false
    end

    file.write(content)
    file.close()

    if fs.exists(path) then
        fs.delete(path)
    end

    fs.move(temporaryPath, path)
    print("OK")
    return true
end

local function drawHeader()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)

    print("==============================")
    print("       CASINO ROYAL")
    print("          UPDATER")
    print("       VERSION 4.2.1")
    print("==============================")
    print("")
end

local function drawResults(updated, failed)
    print("")
    print("==============================")
    print("Update finished")
    print("Updated: " .. updated)
    print("Failed:  " .. failed)
    print("==============================")
end

local function main()
    drawHeader()

    local updated = 0
    local failed = 0

    for _, path in ipairs(FILES) do
        if downloadFile(path) then
            updated = updated + 1
        else
            failed = failed + 1
        end
    end

    drawResults(updated, failed)

    if failed == 0 then
        print("")
        print("Machine configuration preserved.")
        print("Player data and logs preserved.")
        print("Rebooting in 2 seconds...")
        sleep(2)
        os.reboot()
    end

    print("")
    print("Some files could not be updated.")
    print("The computer will not reboot.")
end

local ok, problem = pcall(main)

if not ok then
    term.setTextColor(colors.red)
    print("")
    print("Updater crashed:")
    print(tostring(problem))
    term.setTextColor(colors.white)
end
