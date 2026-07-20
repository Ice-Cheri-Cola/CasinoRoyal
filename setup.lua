--================================================--
-- Casino Royal
-- Version: 5.0.0
-- File: setup.lua
-- Description: Interactive machine configuration wizard
--================================================--

local machine = require("core.machine")

local MACHINE_OPTIONS = {
    { type = "menu",   label = "Casino Menu", defaultName = "Casino Royal" },
    { type = "slots",  label = "Slots",       defaultName = "Royal Slots" },
    { type = "atm",    label = "ATM",         defaultName = "Royal ATM" },
    { type = "server", label = "Server",      defaultName = "Casino Server" },
    { type = "admin",  label = "Admin",       defaultName = "Admin Console" }
}

local REQUIREMENTS = {
    menu = {
        { label = "Monitor", types = { "monitor" } },
        { label = "Modem", types = { "modem" } },
        { label = "Player detector", types = { "playerDetector", "player_detector" } }
    },
    slots = {
        { label = "Monitor", types = { "monitor" } },
        { label = "Modem", types = { "modem" } },
        { label = "Player detector", types = { "playerDetector", "player_detector" } }
    },
    atm = {
        { label = "Monitor", types = { "monitor" } },
        { label = "Modem", types = { "modem" } },
        { label = "Player detector", types = { "playerDetector", "player_detector" } },
        { label = "Deposit chest", side = "front" },
        { label = "Vault chest", side = "back" }
    },
    server = {
        { label = "Modem", types = { "modem" } }
    },
    admin = {
        { label = "Monitor", types = { "monitor" } },
        { label = "Modem", types = { "modem" } }
    }
}

local function clearScreen()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function divider()
    print(string.rep("-", math.min(32, select(1, term.getSize()))))
end

local function header(title)
    clearScreen()
    term.setTextColor(colors.yellow)
    print("CASINO ROYAL")
    term.setTextColor(colors.white)
    print(title or "Machine Setup")
    divider()
end

local function pause(message)
    print("")
    term.setTextColor(colors.lightGray)
    print(message or "Press Enter to continue.")
    term.setTextColor(colors.white)
    read()
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function findPeripheralByType(types)
    for _, name in ipairs(peripheral.getNames()) do
        local peripheralType = peripheral.getType(name)
        if contains(types, peripheralType) then
            return name, peripheralType
        end
    end
    return nil
end

local function isInventory(name)
    if not name or not peripheral.isPresent(name) then
        return false
    end

    local wrapped = peripheral.wrap(name)
    return wrapped ~= nil
        and type(wrapped.list) == "function"
        and type(wrapped.pushItems) == "function"
end

local function checkRequirement(requirement)
    if requirement.side then
        if not peripheral.isPresent(requirement.side) then
            return false, requirement.side .. " is empty"
        end

        if not isInventory(requirement.side) then
            return false, requirement.side .. " is not an inventory"
        end

        return true, requirement.side
    end

    local name, peripheralType = findPeripheralByType(requirement.types)
    if name then
        return true, name .. " (" .. tostring(peripheralType) .. ")"
    end

    return false, "not detected"
end

local function chooseMachineType()
    while true do
        header("Select Machine Type")

        for index, option in ipairs(MACHINE_OPTIONS) do
            print(index .. ". " .. option.label)
        end

        print("")
        write("Choice: ")
        local choice = tonumber(read())

        if choice and MACHINE_OPTIONS[choice] then
            return MACHINE_OPTIONS[choice]
        end

        term.setTextColor(colors.red)
        print("Invalid selection.")
        term.setTextColor(colors.white)
        sleep(1)
    end
end

local function askMachineName(option)
    header("Machine Name")
    print("Type: " .. option.label)
    print("")
    print("Default: " .. option.defaultName)
    write("Name: ")

    local value = read()
    if value == nil or value == "" then
        return option.defaultName
    end

    return value
end

local function showHardwareCheck(machineType)
    header("Hardware Check")

    local requirements = REQUIREMENTS[machineType] or {}
    local allPresent = true

    if #requirements == 0 then
        print("No required peripherals.")
    end

    for _, requirement in ipairs(requirements) do
        local ok, detail = checkRequirement(requirement)

        if ok then
            term.setTextColor(colors.lime)
            write("[OK] ")
        else
            term.setTextColor(colors.red)
            write("[--] ")
            allPresent = false
        end

        term.setTextColor(colors.white)
        print(requirement.label .. ": " .. detail)
    end

    print("")
    if allPresent then
        term.setTextColor(colors.lime)
        print("Hardware check passed.")
    else
        term.setTextColor(colors.orange)
        print("Some hardware is missing.")
        print("You may save anyway and connect it before rebooting.")
    end
    term.setTextColor(colors.white)

    return allPresent
end

local function confirm(config, hardwareReady)
    header("Confirm Configuration")
    print("Computer ID: " .. os.getComputerID())
    print("Machine ID:  " .. config.id)
    print("Type:        " .. config.type)
    print("Name:        " .. config.name)
    print("Enabled:     yes")
    print("Hardware:    " .. (hardwareReady and "ready" or "incomplete"))
    print("")
    write("Save this configuration? (y/n): ")

    local answer = string.lower(read() or "")
    return answer == "y" or answer == "yes"
end

local function saveConfiguration(config)
    local ok, problem = machine.save(config)

    if not ok then
        header("Setup Failed")
        term.setTextColor(colors.red)
        print(tostring(problem or "Could not save configuration"))
        term.setTextColor(colors.white)
        return false
    end

    header("Setup Complete")
    term.setTextColor(colors.lime)
    print("Configuration saved.")
    term.setTextColor(colors.white)
    print("")
    print("Type: " .. config.type)
    print("Name: " .. config.name)
    print("ID:   " .. config.id)
    return true
end

local function main()
    while true do
        local option = chooseMachineType()
        local name = askMachineName(option)
        local hardwareReady = showHardwareCheck(option.type)
        pause()

        local config = {
            id = "casino_" .. option.type .. "_" .. tostring(os.getComputerID()),
            type = option.type,
            name = name,
            enabled = true
        }

        if confirm(config, hardwareReady) then
            if saveConfiguration(config) then
                print("")
                write("Reboot now? (y/n): ")
                local rebootAnswer = string.lower(read() or "")

                if rebootAnswer == "y" or rebootAnswer == "yes" then
                    os.reboot()
                end

                return
            end

            pause("Press Enter to try again.")
        else
            header("Setup Cancelled")
            write("Start over? (y/n): ")
            local retry = string.lower(read() or "")
            if retry ~= "y" and retry ~= "yes" then
                return
            end
        end
    end
end

local ok, problem = pcall(main)
if not ok then
    clearScreen()
    term.setTextColor(colors.red)
    print("Casino Royal setup crashed:")
    term.setTextColor(colors.white)
    print(tostring(problem))
end
