--================================================--
-- Casino Royal
-- Version: 4.0.0
-- File: server.lua
-- Description: Central casino network server
--================================================--

local network =
    require("core.network")

local protocol =
    require("core.protocol")

local machine =
    require("core.machine")

local logger =
    require("core.logger")

--------------------------------------------------
-- Server state
--------------------------------------------------

local machines = {}

local HEARTBEAT_TIMEOUT =
    15000

local DISPLAY_LIMIT =
    8

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

local function centerText(
    y,
    text,
    color
)
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

local function getCurrentTime()
    return os.epoch("utc")
end

local function isMachineOnline(info)
    if type(info) ~= "table" then
        return false
    end

    if type(info.lastSeen) ~= "number" then
        return false
    end

    return getCurrentTime()
        - info.lastSeen
        <= HEARTBEAT_TIMEOUT
end

local function getMachineStatus(info)
    if not isMachineOnline(info) then
        return protocol.STATUS_OFFLINE
    end

    return tostring(
        info.status
        or protocol.STATUS_IDLE
    )
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

local function getSortedMachines()
    local list = {}

    for _, info
        in pairs(machines)
    do
        table.insert(
            list,
            info
        )
    end

    table.sort(
        list,
        function(first, second)
            return tostring(first.name)
                < tostring(second.name)
        end
    )

    return list
end

--------------------------------------------------
-- Server display
--------------------------------------------------

local function getStatusColor(status)
    if status == protocol.STATUS_OFFLINE then
        return colors.red
    end

    if status == protocol.STATUS_BUSY then
        return colors.orange
    end

    return colors.lime
end

local function drawMachineLine(info)
    local width =
        term.getSize()

    local status =
        getMachineStatus(info)

    local statusText =
        string.upper(status)

    local machineText =
        tostring(info.name)
        .. " ["
        .. tostring(info.type)
        .. "]"

    local availableWidth =
        width
        - #statusText
        - 1

    if #machineText > availableWidth then
        machineText =
            string.sub(
                machineText,
                1,
                math.max(
                    1,
                    availableWidth
                )
            )
    end

    term.setTextColor(
        colors.white
    )

    term.write(machineText)

    local cursorX, cursorY =
        term.getCursorPos()

    local statusX =
        width
        - #statusText
        + 1

    if cursorX < statusX then
        term.setCursorPos(
            statusX,
            cursorY
        )
    else
        term.write(" ")
    end

    term.setTextColor(
        getStatusColor(status)
    )

    term.write(statusText)

    term.setTextColor(
        colors.white
    )

    print()
end

local function drawServerScreen(config)
    clearScreen()

    centerText(
        1,
        "CASINO ROYAL SERVER",
        colors.yellow
    )

    centerText(
        2,
        tostring(config.name),
        colors.cyan
    )

    local total, online =
        countMachines()

    term.setCursorPos(1, 4)

    print(
        "Version:     "
        .. protocol.VERSION
    )

    print(
        "Computer ID: "
        .. os.getComputerID()
    )

    print(
        "Machine ID:  "
        .. tostring(config.id)
    )

    term.write("Network:     ")

    term.setTextColor(
        colors.lime
    )

    print("ONLINE")

    term.setTextColor(
        colors.white
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

    local machineList =
        getSortedMachines()

    if #machineList == 0 then
        term.setTextColor(
            colors.lightGray
        )

        print("Waiting for machines...")

        term.setTextColor(
            colors.white
        )

        return
    end

    local displayed = 0

    for _, info
        in ipairs(machineList)
    do
        drawMachineLine(info)

        displayed =
            displayed + 1

        if displayed >= DISPLAY_LIMIT then
            break
        end
    end

    if #machineList > DISPLAY_LIMIT then
        term.setTextColor(
            colors.lightGray
        )

        print(
            "+"
            .. (
                #machineList
                - DISPLAY_LIMIT
            )
            .. " more"
        )

        term.setTextColor(
            colors.white
        )
    end
end

--------------------------------------------------
-- Machine registration
--------------------------------------------------

local function createMachineId(
    senderId,
    data
)
    if data.id ~= nil
    and tostring(data.id) ~= ""
    then
        return tostring(data.id)
    end

    return "computer_"
        .. tostring(senderId)
end

local function updateMachine(
    senderId,
    data
)
    data =
        data or {}

    local machineId =
        createMachineId(
            senderId,
            data
        )

    local existing =
        machines[machineId]

    local isNewMachine =
        existing == nil

    if isNewMachine then
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
                    or protocol.STATUS_IDLE
                ),

            player =
                data.player,

            version =
                tostring(
                    data.version
                    or "unknown"
                ),

            registeredAt =
                getCurrentTime(),

            lastSeen =
                getCurrentTime()
        }

        machines[machineId] =
            existing

        logger.info(
            "Machine registered: "
            .. existing.name
            .. " ["
            .. existing.type
            .. "]"
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
                or protocol.STATUS_IDLE
            )

        existing.player =
            data.player

        existing.version =
            tostring(
                data.version
                or existing.version
                or "unknown"
            )

        existing.lastSeen =
            getCurrentTime()
    end

    return existing, isNewMachine
end

--------------------------------------------------
-- Message replies
--------------------------------------------------

local function replyRegister(
    senderId,
    info
)
    network.reply(
        senderId,
        protocol.REGISTER_ACK,
        {
            success = true,

            result =
                protocol.SUCCESS,

            serverId =
                os.getComputerID(),

            machineId =
                info.id,

            version =
                protocol.VERSION,

            serverTime =
                getCurrentTime()
        }
    )
end

local function replyHeartbeat(senderId)
    network.reply(
        senderId,
        protocol.HEARTBEAT_ACK,
        {
            success = true,

            result =
                protocol.SUCCESS,

            serverId =
                os.getComputerID(),

            version =
                protocol.VERSION,

            serverTime =
                getCurrentTime()
        }
    )
end

local function replyPing(senderId)
    network.reply(
        senderId,
        protocol.PONG,
        {
            success = true,

            serverId =
                os.getComputerID(),

            version =
                protocol.VERSION,

            serverTime =
                getCurrentTime()
        }
    )
end

--------------------------------------------------
-- Message handling
--------------------------------------------------

local function handleRegister(
    senderId,
    data
)
    local info =
        updateMachine(
            senderId,
            data
        )

    replyRegister(
        senderId,
        info
    )
end

local function handleHeartbeat(
    senderId,
    data
)
    updateMachine(
        senderId,
        data
    )

    replyHeartbeat(senderId)
end

local function handleMessage(
    senderId,
    message
)
    if not network.isValidMessage(
        message
    )
    then
        logger.warning(
            "Invalid message from computer "
            .. tostring(senderId)
        )

        return
    end

    local data =
        message.data
        or {}

    if message.type
        == protocol.REGISTER
    then
        handleRegister(
            senderId,
            data
        )

        return
    end

    if message.type
        == protocol.HEARTBEAT
    then
        handleHeartbeat(
            senderId,
            data
        )

        return
    end

    if message.type
        == protocol.PING
    then
        replyPing(senderId)

        return
    end

    logger.warning(
        "Unknown message type: "
        .. tostring(message.type)
        .. " from computer "
        .. tostring(senderId)
    )
end

--------------------------------------------------
-- Network receiver loop
--------------------------------------------------

local function receiverLoop()
    while true do
        local senderId, message =
            network.receive(1)

        if senderId ~= nil
        and message ~= nil
        then
            local success, problem =
                pcall(
                    handleMessage,
                    senderId,
                    message
                )

            if not success then
                logger.error(
                    "Message handling failed: "
                    .. tostring(problem)
                )
            end
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
        error(
            openProblem
            or "Could not open casino network"
        )
    end

    local hosted, hostProblem =
        network.hostServer()

    if not hosted then
        error(
            hostProblem
            or "Could not host casino server"
        )
    end

    logger.info(
        "Casino server online - Version "
        .. protocol.VERSION
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
network.close()

if not success then
    clearScreen()

    centerText(
        2,
        "CASINO SERVER ERROR",
        colors.red
    )

    term.setCursorPos(1, 5)

    print(
        tostring(problem)
    )

    logger.error(
        tostring(problem)
    )
end
