--================================================--
-- Casino Royal
-- Version: 0.5.2
-- File: update.lua
-- Description: Downloads the latest files from GitHub
--================================================--

local baseUrl =
    "https://raw.githubusercontent.com/"
    .. "Ice-Cheri-Cola/CasinoRoyal/main/"

local files = {
    "startup.lua",
    "casino.lua",
    "config.lua",

    "core/display.lua",
    "core/hardware.lua",
    "core/logger.lua",
    "core/theme.lua",
    "core/ui.lua",

    "assets/themes.lua",

    "games/menu.lua",
    "games/slots.lua"
}

--------------------------------------------------
-- Create a parent directory when needed
--------------------------------------------------

local function createParentDirectory(path)
    local directory = fs.getDir(path)

    if directory ~= ""
    and not fs.exists(directory)
    then
        fs.makeDir(directory)
    end
end

--------------------------------------------------
-- Download one file
--------------------------------------------------

local function downloadFile(path)
    createParentDirectory(path)

    local url = baseUrl .. path
    local temporaryPath = path .. ".download"

    if fs.exists(temporaryPath) then
        fs.delete(temporaryPath)
    end

    write("Updating " .. path .. "... ")

    local success, message =
        http.download(
            url,
            temporaryPath
        )

    if not success then
        print("FAILED")

        if message then
            print("  " .. tostring(message))
        end

        return false
    end

    if fs.exists(path) then
        fs.delete(path)
    end

    fs.move(
        temporaryPath,
        path
    )

    print("OK")
    return true
end

--------------------------------------------------
-- Main updater
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("==============================")
print("       CASINO ROYAL")
print("          UPDATER")
print("==============================")
print("")

local updated = 0
local failed = 0

for _, path in ipairs(files) do
    if downloadFile(path) then
        updated = updated + 1
    else
        failed = failed + 1
    end
end

print("")
print("==============================")
print("Update finished")
print("Updated: " .. updated)
print("Failed:  " .. failed)
print("==============================")

if failed == 0 then
    print("")
    print("Restarting Casino Royal...")
    sleep(1)

    shell.run("casino")
else
    print("")
    print("Some files could not be updated.")
    print("Check the messages above.")
end
