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
    "games/menu.lua",
    "assets/themes.lua"
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

local function download(path)
    ensureDirectory(path)

    local response, problem = http.get(BASE .. path)
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

    return true
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
    write("  " .. path .. " ... ")
    local ok, problem = download(path)

    if ok then
        term.setTextColor(colors.lime)
        print("OK")
        installed = installed + 1
    else
        term.setTextColor(colors.red)
        print("FAILED")
        failures[#failures + 1] = path .. ": " .. tostring(problem)
    end

    term.setTextColor(colors.white)
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

-- Reboot instead of immediately launching casino.lua. This clears Lua's
-- module cache so updated core files are loaded rather than stale versions.
os.reboot()
