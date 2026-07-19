--================================================--
-- Casino Royal
-- Version: 3.0.0
-- File: setup.lua
-- Description: Machine configuration setup wizard
--================================================--

local machine =
    require("core.machine")

--------------------------------------------------
-- Display helpers
--------------------------------------------------

local function clearScreen()
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

local function pause()
    print()
    print(
        "Press any key to continue."
    )

    os.pullEvent("key")
end

--------------------------------------------------
-- Ask for text input
--------------------------------------------------

local function askText(
    prompt,
    defaultValue
)
    term.setTextColor(
        colors.yellow
    )

    write(prompt)

    term.setTextColor(
        colors.white
    )

    if defaultValue
    and defaultValue ~= ""
    then
        write(
            " ["
            .. tostring(defaultValue)
            .. "]"
        )
    end

    write(": ")

    local result =
        read()

    if result == nil
    or result == ""
    then
        return defaultValue
    end

    return result
end

--------------------------------------------------
-- Machine type menu
--------------------------------------------------

local typeLabels = {
    menu = "Main Casino Menu",
    slots = "Slots",
    blackjack = "Blackjack",
    roulette = "Roulette",
    higher_lower = "Higher or Lower",
    video_poker = "Video Poker",
    craps = "Craps",
    atm = "ATM",
    admin = "Admin Terminal",
    server = "Casino Server"
}

local function chooseMachineType(
    currentType
)
    local machineTypes =
        machine.getTypes()

    while true do
        clearScreen()

        centerText(
            1,
            "CASINO ROYAL",
            colors.yellow
        )

        centerText(
            2,
            "MACHINE TYPE",
            colors.lightGray
        )

        print()

        for index, machineType
            in ipairs(machineTypes)
        do
            local marker = " "

            if machineType
                == currentType
            then
                marker = "*"
            end

            print(
                marker
                .. " "
                .. index
                .. ". "
                .. typeLabels[machineType]
            )
        end

        print()
        write(
            "Choose machine type: "
        )

        local choice =
            tonumber(read())

        if choice
        and machineTypes[choice]
        then
            return machineTypes[choice]
        end
    end
end

--------------------------------------------------
-- Create suggested machine name
--------------------------------------------------

local function suggestedName(
    machineType
)
    local computerId =
        os.getComputerID()

    local names = {
        menu =
            "MENU-"
            .. computerId,

        slots =
            "SLOTS-"
            .. computerId,

        blackjack =
            "BLACKJACK-"
            .. computerId,

        roulette =
            "ROULETTE-"
            .. computerId,

        higher_lower =
            "HIGHERLOWER-"
            .. computerId,

        video_poker =
            "VIDEOPOKER-"
            .. computerId,

        craps =
            "CRAPS-"
            .. computerId,

        atm =
            "ATM-"
            .. computerId,

        admin =
            "ADMIN-"
            .. computerId,

        server =
            "SERVER-"
            .. computerId
    }

    return names[machineType]
        or "CASINO-"
        .. computerId
end

--------------------------------------------------
-- Confirmation screen
--------------------------------------------------

local function confirmConfig(config)
    while true do
        clearScreen()

        centerText(
            1,
            "CASINO ROYAL",
            colors.yellow
        )

        centerText(
            2,
            "CONFIRM SETUP",
            colors.lightGray
        )

        print()
        print(
            "Computer ID: "
            .. os.getComputerID()
        )

        print(
            "Machine ID:  "
            .. config.id
        )

        print(
            "Name:        "
            .. config.name
        )

        print(
            "Type:        "
            .. config.type
        )

        print(
            "Enabled:     "
            .. tostring(
                config.enabled
            )
        )

        print()
        print("1. Save configuration")
        print("2. Edit configuration")
        print("3. Cancel")

        print()
        write("Choose: ")

        local choice =
            read()

        if choice == "1" then
            return true
        elseif choice == "2" then
            return false
        elseif choice == "3" then
            return nil
        end
    end
end

--------------------------------------------------
-- Setup wizard
--------------------------------------------------

local function runSetup()
    local existingConfig =
        machine.load()

    if existingConfig == nil then
        existingConfig =
            machine.getDefault()
    end

    while true do
        local selectedType =
            chooseMachineType(
                existingConfig.type
            )

        clearScreen()

        centerText(
            1,
            "CASINO ROYAL",
            colors.yellow
        )

        centerText(
            2,
            "MACHINE DETAILS",
            colors.lightGray
        )

        print()

        local defaultName =
            suggestedName(
                selectedType
            )

        if existingConfig.type
            == selectedType
        and existingConfig.name
            ~= "Casino Terminal"
        then
            defaultName =
                existingConfig.name
        end

        local machineName =
            askText(
                "Machine name",
                defaultName
            )

        local defaultId =
            string.lower(
                machineName
            )

        defaultId =
            string.gsub(
                defaultId,
                "%s+",
                "_"
            )

        defaultId =
            string.gsub(
                defaultId,
                "[^%w_%-]",
                ""
            )

        local machineId =
            askText(
                "Machine ID",
                defaultId
            )

        local config = {
            id =
                machineId,

            type =
                selectedType,

            name =
                machineName,

            enabled =
                true
        }

        local confirmation =
            confirmConfig(config)

        if confirmation == true then
            local success, problem =
                machine.save(config)

            clearScreen()

            if success then
                centerText(
                    2,
                    "SETUP COMPLETE",
                    colors.lime
                )

                print()
                print(
                    "Machine configured as:"
                )

                print()
                print(
                    config.name
                )

                print(
                    "("
                    .. config.type
                    .. ")"
                )

                print()
                print(
                    "Configuration saved to:"
                )

                print(
                    machine.getPath()
                )

                pause()
                return
            else
                centerText(
                    2,
                    "SETUP FAILED",
                    colors.red
                )

                print()
                print(
                    problem
                    or "Unknown error"
                )

                pause()
            end

        elseif confirmation == nil then
            clearScreen()

            print(
                "Setup cancelled."
            )

            return
        else
            existingConfig =
                config
        end
    end
end

--------------------------------------------------
-- Safe execution
--------------------------------------------------

local success, problem =
    pcall(runSetup)

if not success then
    clearScreen()

    term.setTextColor(
        colors.red
    )

    print(
        "Casino Royal setup failed:"
    )

    term.setTextColor(
        colors.white
    )

    print(problem)
end
