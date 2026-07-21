--================================================--
-- Casino Royal
-- Version: 5.0.0-bootstrap
-- File: install.lua
-- Description: Clean, verified Casino Royal installer
--================================================--

local BASE_URL =
    "https://raw.githubusercontent.com/"
    .. "Ice-Cheri-Cola/CasinoRoyal/main/"

local STAGING_DIR = ".casino_install"
local BACKUP_DIR = ".casino_backup"

local FILES = {
    "startup.lua",
    "casino.lua",
    "setup.lua",
    "server.lua",
    "atm.lua",
    "admin.lua",
    "config.lua",

    "core/account_store.lua",
    "core/bank.lua",
    "core/card.lua",
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

    "update.lua",
    "install.lua"
}

local OLD_PATHS = {
    "startup.lua",
    "casino.lua",
    "setup.lua",
    "server.lua",
    "atm.lua",
    "admin.lua",
    "update.lua",
    "update_new.lua",
    "core",
    "assets",
    "games",
    "terminals"
}

local function clearScreen()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function ensureParent(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function remove(path)
    if fs.exists(path) then
        fs.delete(path)
    end
end

local function copyIfPresent(source, destination)
    if not fs.exists(source) then
        return false
    end

    ensureParent(destination)
    remove(destination)
    fs.copy(source, destination)
    return true
end

local function download(path)
    local target = fs.combine(STAGING_DIR, path)
    ensureParent(target)
    remove(target)

    write("Downloading " .. path .. "... ")

    local response, problem = http.get(BASE_URL .. path)
    if not response then
        print("FAILED")
        print("  " .. tostring(problem or "Unknown HTTP error"))
        return false
    end

    local content = response.readAll()
    response.close()

    if not content or content == "" then
        print("FAILED")
        print("  Empty download")
        return false
    end

    local handle = fs.open(target, "w")
    if not handle then
        print("FAILED")
        print("  Could not create staging file")
        return false
    end

    handle.write(content)
    handle.close()

    print("OK")
    return true
end

local function backupLocalData()
    remove(BACKUP_DIR)
    fs.makeDir(BACKUP_DIR)

    copyIfPresent("config.lua", fs.combine(BACKUP_DIR, "config.lua"))
    copyIfPresent("casino.log", fs.combine(BACKUP_DIR, "casino.log"))

    if fs.exists("data") then
        fs.copy("data", fs.combine(BACKUP_DIR, "data"))
    end
end

local function removeOldPrograms()
    for _, path in ipairs(OLD_PATHS) do
        remove(path)
    end
end

local function installStagedFiles()
    for _, path in ipairs(FILES) do
        local source = fs.combine(STAGING_DIR, path)

        if path == "config.lua"
        and fs.exists(fs.combine(BACKUP_DIR, "config.lua"))
        then
            -- Preserve this computer's role, ID, and settings.
        else
            ensureParent(path)
            remove(path)
            fs.move(source, path)
        end
    end
end

local function restoreLocalData()
    local configBackup = fs.combine(BACKUP_DIR, "config.lua")
    if fs.exists(configBackup) then
        remove("config.lua")
        fs.copy(configBackup, "config.lua")
    end

    local logBackup = fs.combine(BACKUP_DIR, "casino.log")
    if fs.exists(logBackup) then
        remove("casino.log")
        fs.copy(logBackup, "casino.log")
    end

    local dataBackup = fs.combine(BACKUP_DIR, "data")
    if fs.exists(dataBackup) then
        remove("data")
        fs.copy(dataBackup, "data")
    end
end

local function verifyInstallation()
    local required = {
        "startup.lua",
        "atm.lua",
        "server.lua",
        "core/network.lua",
        "core/protocol.lua",
        "core/player.lua"
    }

    for _, path in ipairs(required) do
        if not fs.exists(path) then
            return false, path
        end
    end

    return true
end

local function main()
    clearScreen()

    print("==============================")
    print("       CASINO ROYAL")
    print("       CLEAN INSTALLER")
    print("==============================")
    print("")
    print("Existing config and data will")
    print("be preserved automatically.")
    print("")

    remove(STAGING_DIR)
    fs.makeDir(STAGING_DIR)

    local failed = 0

    for _, path in ipairs(FILES) do
        if not download(path) then
            failed = failed + 1
        end
    end

    if failed > 0 then
        print("")
        print("Installation cancelled.")
        print(tostring(failed) .. " file(s) failed to download.")
        print("No existing programs were removed.")
        return
    end

    print("")
    print("All files downloaded.")
    print("Backing up local settings...")

    backupLocalData()
    removeOldPrograms()
    installStagedFiles()
    restoreLocalData()
    remove(STAGING_DIR)

    local ok, missing = verifyInstallation()
    if not ok then
        error("Installation incomplete; missing " .. tostring(missing))
    end

    print("")
    print("Installation complete!")
    print("Configuration preserved.")
    print("Rebooting in 3 seconds...")
    sleep(3)
    os.reboot()
end

local ok, problem = pcall(main)
if not ok then
    term.setTextColor(colors.red)
    print("")
    print("Installer stopped:")
    print(tostring(problem))
    term.setTextColor(colors.white)
end
