--================================================--
-- Casino Royal
-- Version: 4.3.0
-- File: admin.lua
-- Description: Bank card issuing terminal
--================================================--

local card = require("core.card")
local machine = require("core.machine")
local protocol = require("core.protocol")

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function header()
    clear()
    term.setTextColor(colors.yellow)
    print("CASINO ROYAL")
    term.setTextColor(colors.cyan)
    print("BANK CARD ISSUER")
    term.setTextColor(colors.white)
    print("Version " .. protocol.VERSION)
    print("")
end

local function prompt(label, default)
    write(label)
    if default and default ~= "" then
        write(" [" .. tostring(default) .. "]")
    end
    write(": ")

    local value = read()
    if value == "" then return default end
    return value
end

local function waitForDisk()
    while true do
        local driveName = card.getDriveName()
        if not driveName then
            print("No disk drive attached.")
            print("Attach a disk drive, then press Enter.")
            read()
        elseif not disk.isPresent(driveName) then
            print("Insert a blank floppy disk, then press Enter.")
            read()
        else
            return true
        end
    end
end

local function issueCard()
    header()
    print("Issue a programmable Casino Royal card")
    print("")

    waitForDisk()

    local username = prompt("Minecraft username")
    if not username or username == "" then
        print("Username is required.")
        sleep(2)
        return
    end

    local tier = prompt("Card tier", "Standard")
    local issuer = machine.getName() or os.getComputerLabel() or "Casino Admin"

    print("")
    print("Writing card...")

    local ok, result = card.write({
        username = username,
        account = username,
        tier = tier,
        issuedBy = issuer,
        active = true
    })

    if not ok then
        term.setTextColor(colors.red)
        print("FAILED: " .. tostring(result))
        term.setTextColor(colors.white)
        sleep(3)
        return
    end

    term.setTextColor(colors.lime)
    print("CARD ISSUED")
    term.setTextColor(colors.white)
    print("Owner: " .. tostring(result.username))
    print("Card ID: " .. tostring(result.id))
    print("Tier: " .. tostring(result.tier))
    print("")
    print("Remove the disk and give it to the player.")
    print("Press Enter to continue.")
    read()
end

local function inspectCard()
    header()
    print("Insert a Casino Royal card.")
    print("Press Enter when ready.")
    read()

    local data, problem = card.read()
    if not data then
        term.setTextColor(colors.red)
        print("FAILED: " .. tostring(problem))
        term.setTextColor(colors.white)
    else
        print("")
        print("Owner: " .. tostring(data.username))
        print("Account: " .. tostring(data.account))
        print("Card ID: " .. tostring(data.id))
        print("Tier: " .. tostring(data.tier))
        print("Active: " .. tostring(data.active ~= false))
        print("Issued by: " .. tostring(data.issuedBy or "Unknown"))
    end

    print("")
    print("Press Enter to continue.")
    read()
end

local function main()
    while true do
        header()
        print("1. Issue bank card")
        print("2. Inspect bank card")
        print("3. Reboot")
        print("")
        write("Select: ")

        local choice = read()
        if choice == "1" then
            issueCard()
        elseif choice == "2" then
            inspectCard()
        elseif choice == "3" then
            os.reboot()
        end
    end
end

local ok, problem = pcall(main)
if not ok then
    term.setTextColor(colors.red)
    print("Admin terminal crashed:")
    print(tostring(problem))
    term.setTextColor(colors.white)
end
