--================================================--
-- Casino Royal
-- Version: 4.1.0
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

local accountStore =
    require("core.account_store")

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
        tostring(
            text
            or ""
        )

    local x =
        math.floor(
            (width - #text) / 2
        ) + 1

    term.setCursorPos(
        math.max(1, x),
        y
    )

    if color then
        term.setTextColor(
            color
        )
    end

    term.write(text)

    term.setTextColor(
        colors.white
    )
end

--------------------------------------------------
-- Time
--------------------------------------------------

local function getCurrentTime()
    return os.epoch("utc")
end

--------------------------------------------------
-- Machine status
--------------------------------------------------

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
        total =
            total + 1

        if isMachineOnline(info) then
            online =
                online + 1
        end
    end

    return total,
        online
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
    if status
        == protocol.STATUS_OFFLINE
    then
        return colors.red
    end

    if status
        == protocol.STATUS_BUSY
    then
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

    term.write(
        machineText
    )

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

    term.write(
        statusText
    )

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

    term.write(
        "Network:     "
    )

    term.setTextColor(
        colors.lime
    )

    print("ONLINE")

    term.setTextColor(
        colors.white
    )

    term.write(
        "Bank:        "
    )

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

        print(
            "Waiting for machines..."
        )

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

        if displayed
            >= DISPLAY_LIMIT
        then
            break
        end
    end

    if #machineList
        > DISPLAY_LIMIT
    then
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
        return tostring(
            data.id
        )
    end

    return "computer_"
        .. tostring(senderId)
end

local function updateMachine(
    senderId,
    data
)
    data =
        data
        or {}

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

    return existing,
        isNewMachine
end

local function findMachineByComputerId(
    senderId
)
    for _, info
        in pairs(machines)
    do
        if info.computerId
            == senderId
        then
            return info
        end
    end

    return nil
end

--------------------------------------------------
-- Reply helpers
--------------------------------------------------

local function replySuccess(
    senderId,
    messageType,
    data
)
    data =
        data
        or {}

    data.success =
        true

    data.result =
        protocol.SUCCESS

    data.serverId =
        os.getComputerID()

    data.version =
        protocol.VERSION

    data.serverTime =
        getCurrentTime()

    network.reply(
        senderId,
        messageType,
        data
    )
end

local function replyError(
    senderId,
    messageType,
    problem,
    data
)
    data =
        data
        or {}

    data.success =
        false

    data.result =
        protocol.ERROR

    data.error =
        tostring(
            problem
            or "UNKNOWN ERROR"
        )

    data.serverId =
        os.getComputerID()

    data.version =
        protocol.VERSION

    data.serverTime =
        getCurrentTime()

    network.reply(
        senderId,
        messageType,
        data
    )
end

--------------------------------------------------
-- Machine message handlers
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

    replySuccess(
        senderId,
        protocol.REGISTER_ACK,
        {
            machineId =
                info.id
        }
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

    replySuccess(
        senderId,
        protocol.HEARTBEAT_ACK
    )
end

local function handlePing(senderId)
    replySuccess(
        senderId,
        protocol.PONG
    )
end

--------------------------------------------------
-- Banking helpers
--------------------------------------------------

local function getRequestUsername(data)
    if type(data) ~= "table" then
        return nil
    end

    if type(data.username) ~= "string"
    or data.username == ""
    then
        return nil
    end

    return data.username
end

local function createTransactionDetails(
    senderId,
    data
)
    local machineInfo =
        findMachineByComputerId(
            senderId
        )

    return {
        machineId =
            data.machineId
            or (
                machineInfo
                and machineInfo.id
            ),

        machineType =
            data.machineType
            or (
                machineInfo
                and machineInfo.type
            ),

        game =
            data.game,

        note =
            data.note
    }
end

--------------------------------------------------
-- Balance handler
--------------------------------------------------

local function handleBalance(
    senderId,
    data
)
    local username =
        getRequestUsername(data)

    if username == nil then
        replyError(
            senderId,
            protocol.BALANCE_REPLY,
            "INVALID USERNAME"
        )

        return
    end

    local balance, problem =
        accountStore.getBalance(
            username
        )

    if balance == nil then
        replyError(
            senderId,
            protocol.BALANCE_REPLY,
            problem
        )

        return
    end

    replySuccess(
        senderId,
        protocol.BALANCE_REPLY,
        {
            username =
                username,

            balance =
                balance
        }
    )
end

--------------------------------------------------
-- Deposit handler
--------------------------------------------------

local function handleDeposit(
    senderId,
    data
)
    local username =
        getRequestUsername(data)

    if username == nil then
        replyError(
            senderId,
            protocol.DEPOSIT_REPLY,
            "INVALID USERNAME"
        )

        return
    end

    local success,
        balance,
        transaction =
            accountStore.deposit(
                username,
                data.amount,
                createTransactionDetails(
                    senderId,
                    data
                )
            )

    if not success then
        replyError(
            senderId,
            protocol.DEPOSIT_REPLY,
            balance
        )

        return
    end

    logger.info(
        "Deposit: "
        .. username
        .. " +"
        .. tostring(data.amount)
        .. " = "
        .. tostring(balance)
    )

    replySuccess(
        senderId,
        protocol.DEPOSIT_REPLY,
        {
            username =
                username,

            amount =
                data.amount,

            balance =
                balance,

            transaction =
                transaction
        }
    )
end

--------------------------------------------------
-- Withdrawal handler
--------------------------------------------------

local function handleWithdraw(
    senderId,
    data
)
    local username =
        getRequestUsername(data)

    if username == nil then
        replyError(
            senderId,
            protocol.WITHDRAW_REPLY,
            "INVALID USERNAME"
        )

        return
    end

    local success,
        result,
        extra =
            accountStore.withdraw(
                username,
                data.amount,
                createTransactionDetails(
                    senderId,
                    data
                )
            )

    if not success then
        replyError(
            senderId,
            protocol.WITHDRAW_REPLY,
            result,
            {
                username =
                    username,

                balance =
                    extra
            }
        )

        return
    end

    local balance =
        result

    local transaction =
        extra

    logger.info(
        "Withdrawal: "
        .. username
        .. " -"
        .. tostring(data.amount)
        .. " = "
        .. tostring(balance)
    )

    replySuccess(
        senderId,
        protocol.WITHDRAW_REPLY,
        {
            username =
                username,

            amount =
                data.amount,

            balance =
                balance,

            transaction =
                transaction
        }
    )
end

--------------------------------------------------
-- Account handler
--------------------------------------------------

local function handleAccount(
    senderId,
    data
)
    local username =
        getRequestUsername(data)

    if username == nil then
        replyError(
            senderId,
            protocol.ACCOUNT_REPLY,
            "INVALID USERNAME"
        )

        return
    end

    local account, problem =
        accountStore.getAccount(
            username
        )

    if account == nil then
        replyError(
            senderId,
            protocol.ACCOUNT_REPLY,
            problem
        )

        return
    end

    replySuccess(
        senderId,
        protocol.ACCOUNT_REPLY,
        {
            account =
                account
        }
    )
end

--------------------------------------------------
-- Game-stat handler
--------------------------------------------------

local function handleRecordGame(
    senderId,
    data
)
    local username =
        getRequestUsername(data)

    if username == nil then
        replyError(
            senderId,
            protocol.RECORD_GAME_REPLY,
            "INVALID USERNAME"
        )

        return
    end

    if type(data.game) ~= "string"
    or data.game == ""
    then
        replyError(
            senderId,
            protocol.RECORD_GAME_REPLY,
            "INVALID GAME"
        )

        return
    end

    local success, problem =
        accountStore.recordGame(
            username,
            data.game
        )

    if not success then
        replyError(
            senderId,
            protocol.RECORD_GAME_REPLY,
            problem
        )

        return
    end

    replySuccess(
        senderId,
        protocol.RECORD_GAME_REPLY,
        {
            username =
                username,

            game =
                data.game
        }
    )
end

--------------------------------------------------
-- Main message handler
--------------------------------------------------

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
        handlePing(
            senderId
        )

        return
    end

    if message.type
        == protocol.BALANCE
    then
        handleBalance(
            senderId,
            data
        )

        return
    end

    if message.type
        == protocol.DEPOSIT
    then
        handleDeposit(
            senderId,
            data
        )

        return
    end

    if message.type
        == protocol.WITHDRAW
    then
        handleWithdraw(
            senderId,
            data
        )

        return
    end

    if message.type
        == protocol.ACCOUNT
    then
        handleAccount(
            senderId,
            data
        )

        return
    end

    if message.type
        == protocol.RECORD_GAME
    then
        handleRecordGame(
            senderId,
            data
        )

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
-- Network receiver
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
-- Display refresh
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

    local initialized,
        initializeProblem =
            accountStore.initialize()

    if not initialized then
        error(
            initializeProblem
            or "Could not initialize account storage"
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

    logger.info(
        "Central bank online"
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
