--================================================--
-- Casino Royal
-- Version: 3.1.0
-- File: server.lua
-- Description: Central casino network server
--================================================--

local network =
    require("core.network")

local machine =
    require("core.machine")

local logger =
    require("core.logger")

--------------------------------------------------
-- Server state
--------------------------------------------------

local machines = {}

local heartbeatTimeout =
    15000

--------------------------------------------------
-- Terminal helpers
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

--------------------------------------------------
-- Machine status
--------------------------------------------------

local function isMachineOnline(info)
    local now =
        os.epoch("utc")

    return now - info.lastSeen
        <= heartbeatTimeout
end

local function countMachines()
    local total = 0
    local online = 0

    for _, info
        in pairs(machines)
    do
        total = total + 1

        if isMachineOnline(info) then
            online = online + 1
        end
    end

    return total, online
end

--------------------------------------------------
-- Server display
--------------------------------------------------

local function drawServerScreen(config)
    clearScreen()

    centerText(
        1,
        "CASINO ROYAL SERVER",
        colors.yellow
    )

    centerText(
        2,
        config.name,
        colors.cyan
    )

    local total, online =
        countMachines()

    term.setCursorPos(1, 4)

    print(
        "Computer ID: "
        .. os.getComputerID()
    )

    print(
        "Machine ID:  "
        .. config.id
    )

    print(
        "Network:     ONLINE"
    )

    print(
        "Machines:    "
        .. online
        .. "/"
        .. total
        .. " online"
    )

    print()
    print("Registered machines:")
    print("--------------------")

    local displayed = 0

    for _, info
        in pairs(machines)
    do
        displayed = displayed + 1

        local status =
            isMachineOnline(info)
            and "ONLINE"
            or "OFFLINE"

        print(
            info.name
            .. " ["
            .. info.type
            .. "] "
            .. status
        )

        if displayed >= 8 then
            break
        end
    end

    if displayed == 0 then
        print("Waiting for machines...")
    end
end

--------------------------------------------------
-- Register or update machine
--------------------------------------------------

local function updateMachine(
    senderId,
    data
)
    local machineId =
        tostring(
            data.id
            or "computer_"
            .. senderId
        )

    local existing =
        machines[machineId]

    if existing == nil then
        existing = {
            computerId =
                senderId,

            id =
                machineId,

            name =
                tostring(
                    data.name
                    or machineId
                ),

            type =
                tostring(
                    data.type
                    or "unknown"
                ),

            status =
                tostring(
                    data.status
                    or "idle"
                ),

            player =
                data.player,

            lastSeen =
                os.epoch("utc")
        }

        machines[machineId] =
            existing

        logger.info(
            "Machine registered: "
            .. existing.name
        )
    else
        existing.computerId =
            senderId

        existing.name =
            tostring(
                data.name
                or existing.name
            )

        existing.type =
            tostring(
                data.type
                or existing.type
            )

        existing.status =
            tostring(
                data.status
                or existing.status
            )

        existing.player =
            data.player

        existing.lastSeen =
            os.epoch("utc")
    end

    return existing
end

--------------------------------------------------
-- Message handling
--------------------------------------------------

local function handleMessage(
    senderId,
    message
)
    local data =
        message.data
        or {}

    if message.type == "register" then
        local info =
            updateMachine(
                senderId,
                data
            )

        network.reply(
            senderId,
            "register_ack",
            {
                success = true,
                serverId =
                    os.getComputerID(),

                machineId =
                    info.id
            }
        )

    elseif message.type == "heartbeat" then
        updateMachine(
            senderId,
            data
        )

        network.reply(
            senderId,
            "heartbeat_ack",
            {
                success = true,
                serverTime =
                    os.epoch("utc")
            }
        )

    elseif message.type == "ping" then
        network.reply(
            senderId,
            "pong",
            {
                serverId =
                    os.getComputerID(),

                serverTime =
                    os.epoch("utc")
            }
        )
    end
end

--------------------------------------------------
-- Network receiver loop
--------------------------------------------------

local function receiverLoop()
    while true do
        local senderId, message =
            network.receive(1)

        if senderId
        and message
        then
            handleMessage(
                senderId,
                message
            )
        end
    end
end

--------------------------------------------------
-- Display refresh loop
--------------------------------------------------

local function displayLoop(config)
    while true do
        drawServerScreen(config)
        sleep(1)
    end
end

--------------------------------------------------
-- Main server startup
--------------------------------------------------

local function runServer()
    local config, problem =
        machine.load()

    if config == nil then
        error(
            problem
            or "Machine configuration missing"
        )
    end

    if config.type ~= "server" then
        error(
            "This computer is configured as "
            .. tostring(config.type)
            .. ", not server"
        )
    end

    local opened, openProblem =
        network.open()

    if not opened then
        error(openProblem)
    end

    local hosted, hostProblem =
        network.hostServer()

    if not hosted then
        error(hostProblem)
    end

    logger.info(
        "Casino server online"
    )

    parallel.waitForAll(
        function()
            receiverLoop()
        end,

        function()
            displayLoop(config)
        end
    )
end

--------------------------------------------------
-- Safe execution
--------------------------------------------------

local success, problem =
    pcall(runServer)

network.unhostServer()

if not success then
    clearScreen()

    centerText(
        2,
        "CASINO SERVER ERROR",
        colors.red
    )

    term.setCursorPos(1, 5)
    print(tostring(problem))

    logger.error(
        tostring(problem)
    )
end
