--================================================--
-- Casino Royal
-- Version: 3.2.0
-- File: update.lua
-- Description: Downloads all Casino Royal files
--================================================--

local baseUrl =
    "https://raw.githubusercontent.com/"
    .. "Ice-Cheri-Cola/CasinoRoyal/main/"

local files = {
    "startup.lua",
    "casino.lua",
    "setup.lua",
    "server.lua",
    "config.lua",

    "core/bank.lua",
    "core/display.lua",
    "core/hardware.lua",
    "core/logger.lua",
    "core/machine.lua",
    "core/network.lua",
    "core/player.lua",
    "core/theme.lua",
    "core/ui.lua",

    "assets/themes.lua",

    "games/menu.lua",
    "games/slots.lua",

    -- The updater replaces itself last.
    "update.lua"
}

local function createParentDirectory(path)
    local directory = fs.getDir(path)

    if directory ~= ""
    and not fs.exists(directory)
    then
        fs.makeDir(directory)
    end
end

local function downloadFile(path)
    createParentDirectory(path)

    local url = baseUrl .. path
    local temporaryPath =
        path .. ".download"

    if fs.exists(temporaryPath) then
        fs.delete(temporaryPath)
    end

    write(
        "Updating "
        .. path
        .. "... "
    )

    local response, errorMessage =
        http.get(url)

    if not response then
        print("FAILED")
        print(
            "  "
            .. tostring(
                errorMessage
                or "Unknown HTTP error"
            )
        )

        return false
    end

    local content =
        response.readAll()

    response.close()

    if content == nil
    or content == ""
    then
        print("FAILED")
        print("  Download was empty")
        return false
    end

    local file =
        fs.open(
            temporaryPath,
            "w"
        )

    if not file then
        print("FAILED")
        print(
            "  Could not open temporary file"
        )

        return false
    end

    file.write(content)
    file.close()

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

term.setBackgroundColor(
    colors.black
)

term.setTextColor(
    colors.white
)

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
    print(
        "Machine configuration preserved."
    )

    print(
        "Rebooting in 2 seconds..."
    )

    sleep(2)
    os.reboot()
else
    print("")
    print(
        "Some files could not be updated."
    )

    print(
        "The computer will not reboot."
    )
end
