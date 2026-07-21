-- Casino Royal rebuild-v1 installer/updater

local BASE = "https://raw.githubusercontent.com/Ice-Cheri-Cola/CasinoRoyal/rebuild-v1/"

local files = {
    "casino.lua",
    "startup.lua",
    "version.lua",
    "core/hardware.lua",
    "core/display.lua",
    "core/ui.lua",
    "core/theme.lua",
    "core/wallet.lua",
    "games/menu.lua",
    "assets/themes.lua"
}

local preserveIfPresent = {
    "config.lua"
}

local function heading(text)
    term.setTextColor(colors.yellow)
    print(text)
    term.setTextColor(colors.white)
end

local function ensureDirectory(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function cacheBustedUrl(path)
    return BASE .. path .. "?cb=" .. tostring(os.epoch("utc"))
end

local function download(path, overwrite)
    ensureDirectory(path)

    if overwrite == false and fs.exists(path) and not fs.isDir(path) then
        return true, "PRESERVED"
    end

    -- A folder named config.lua cannot be loaded with require("config").
    if fs.exists(path) and fs.isDir(path) then
        fs.delete(path)
    end

    local response, problem = http.get(cacheBustedUrl(path))
    if not response then
        return false, problem or "HTTP request failed"
    end

    local content = response.readAll()
    response.close()

    if not content or content == "" then
        return false, "Downloaded file was empty"
    end

    local temporary = path .. ".download"
    if fs.exists(temporary) then
        fs.delete(temporary)
    end

    local handle = fs.open(temporary, "w")
    if not handle then
        return false, "Could not open temporary file"
    end

    handle.write(content)
    handle.close()

    if fs.exists(path) then
        fs.delete(path)
    end
    fs.move(temporary, path)

    return true, "OK"
end

local function installPath(path, overwrite)
    write("  " .. path .. " ... ")
    local ok, status = download(path, overwrite)

    if ok then
        if status == "PRESERVED" then
            term.setTextColor(colors.lightGray)
            print("PRESERVED")
        else
            term.setTextColor(colors.lime)
            print("OK")
        end
    else
        term.setTextColor(colors.red)
        print("FAILED")
    end

    term.setTextColor(colors.white)
    return ok, status
end

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)

heading("================================")
heading("     CASINO ROYAL INSTALLER")
heading("================================")
print("")
print("Branch: rebuild-v1")
print("Updating program files...")
print("")

local installed = 0
local failures = {}

for _, path in ipairs(files) do
    local ok, problem = installPath(path, true)
    if ok then
        installed = installed + 1
    else
        failures[#failures + 1] = path .. ": " .. tostring(problem)
    end
end

for _, path in ipairs(preserveIfPresent) do
    local existed = fs.exists(path) and not fs.isDir(path)
    local ok, problem = installPath(path, false)
    if ok and not existed then
        installed = installed + 1
    elseif not ok then
        failures[#failures + 1] = path .. ": " .. tostring(problem)
    end
end

print("")

if #failures > 0 then
    term.setTextColor(colors.red)
    print("Installation incomplete.")
    term.setTextColor(colors.white)
    for _, problem in ipairs(failures) do
        print("- " .. problem)
    end
    print("")
    print("Check that HTTP is enabled, then run the installer again.")
    return
end

term.setTextColor(colors.lime)
print("Installed " .. installed .. " files successfully!")
term.setTextColor(colors.white)
print("")
print("Existing config and saved data were preserved.")
print("Rebooting to load the updated files...")
sleep(2)

os.reboot()
