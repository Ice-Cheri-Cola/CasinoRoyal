--================================================--
-- Casino Royal
-- Version: 3.1.0
-- File: core/network.lua
-- Description: Casino network communication system
--================================================--

local network = {}

--------------------------------------------------
-- Network settings
--------------------------------------------------

local protocol =
    "casino_royal"

local serverHostname =
    "casino_royal_server"

local openedModems = {}

--------------------------------------------------
-- Build a network message
--------------------------------------------------

local function createMessage(
    messageType,
    data
)
    return {
        version = "3.1.0",

        type =
            tostring(
                messageType
                or "unknown"
            ),

        data =
            data
            or {},

        senderId =
            os.getComputerID(),

        senderLabel =
            os.getComputerLabel(),

        timestamp =
            os.epoch("utc")
    }
end

--------------------------------------------------
-- Validate received message
--------------------------------------------------

local function isValidMessage(message)
    return type(message) == "table"
        and type(message.type) == "string"
        and message.senderId ~= nil
end

--------------------------------------------------
-- Find and open attached modems
--------------------------------------------------

function network.open()
    openedModems = {}

    local names =
        peripheral.getNames()

    for _, name
        in ipairs(names)
    do
        local peripheralType =
            peripheral.getType(name)

        if peripheralType == "modem" then
            if not rednet.isOpen(name) then
                rednet.open(name)
            end

            table.insert(
                openedModems,
                name
            )
        end
    end

    if #openedModems == 0 then
        return false,
            "NO MODEM FOUND"
    end

    return true,
        #openedModems
end

--------------------------------------------------
-- Close network modems
--------------------------------------------------

function network.close()
    for _, name
        in ipairs(openedModems)
    do
        if rednet.isOpen(name) then
            rednet.close(name)
        end
    end

    openedModems = {}
end

--------------------------------------------------
-- Check whether networking is open
--------------------------------------------------

function network.isOpen()
    for _, name
        in ipairs(peripheral.getNames())
    do
        if peripheral.getType(name)
            == "modem"
        and rednet.isOpen(name)
        then
            return true
        end
    end

    return false
end

--------------------------------------------------
-- Get opened modem names
--------------------------------------------------

function network.getModems()
    local result = {}

    for index, name
        in ipairs(openedModems)
    do
        result[index] = name
    end

    return result
end

--------------------------------------------------
-- Host the central casino server
--------------------------------------------------

function network.hostServer()
    if not network.isOpen() then
        local success, problem =
            network.open()

        if not success then
            return false,
                problem
        end
    end

    local existing =
        rednet.lookup(
            protocol,
            serverHostname
        )

    if existing
    and existing
        ~= os.getComputerID()
    then
        return false,
            "ANOTHER CASINO SERVER IS ONLINE"
    end

    rednet.host(
        protocol,
        serverHostname
    )

    return true
end

--------------------------------------------------
-- Stop hosting the server
--------------------------------------------------

function network.unhostServer()
    pcall(
        rednet.unhost,
        protocol,
        serverHostname
    )
end

--------------------------------------------------
-- Find the central casino server
--------------------------------------------------

function network.findServer()
    if not network.isOpen() then
        local success, problem =
            network.open()

        if not success then
            return nil,
                problem
        end
    end

    local serverId =
        rednet.lookup(
            protocol,
            serverHostname
        )

    if serverId == nil then
        return nil,
            "CASINO SERVER NOT FOUND"
    end

    return serverId
end

--------------------------------------------------
-- Send message to a computer
--------------------------------------------------

function network.send(
    computerId,
    messageType,
    data
)
    if type(computerId) ~= "number" then
        return false,
            "INVALID COMPUTER ID"
    end

    if not network.isOpen() then
        local success, problem =
            network.open()

        if not success then
            return false,
                problem
        end
    end

    local message =
        createMessage(
            messageType,
            data
        )

    local sent =
        rednet.send(
            computerId,
            message,
            protocol
        )

    if not sent then
        return false,
            "MESSAGE COULD NOT BE SENT"
    end

    return true
end

--------------------------------------------------
-- Send message to casino server
--------------------------------------------------

function network.sendToServer(
    messageType,
    data
)
    local serverId, problem =
        network.findServer()

    if serverId == nil then
        return false,
            problem
    end

    return network.send(
        serverId,
        messageType,
        data
    )
end

--------------------------------------------------
-- Broadcast a casino message
--------------------------------------------------

function network.broadcast(
    messageType,
    data
)
    if not network.isOpen() then
        local success, problem =
            network.open()

        if not success then
            return false,
                problem
        end
    end

    rednet.broadcast(
        createMessage(
            messageType,
            data
        ),
        protocol
    )

    return true
end

--------------------------------------------------
-- Receive a casino message
--------------------------------------------------

function network.receive(timeout)
    if not network.isOpen() then
        local success, problem =
            network.open()

        if not success then
            return nil,
                nil,
                problem
        end
    end

    local senderId, message =
        rednet.receive(
            protocol,
            timeout
        )

    if senderId == nil then
        return nil,
            nil,
            "TIMEOUT"
    end

    if not isValidMessage(message) then
        return nil,
            nil,
            "INVALID NETWORK MESSAGE"
    end

    return senderId,
        message
end

--------------------------------------------------
-- Reply to a received message
--------------------------------------------------

function network.reply(
    recipientId,
    messageType,
    data
)
    return network.send(
        recipientId,
        messageType,
        data
    )
end

--------------------------------------------------
-- Get network protocol
--------------------------------------------------

function network.getProtocol()
    return protocol
end

--------------------------------------------------
-- Get server hostname
--------------------------------------------------

function network.getServerHostname()
    return serverHostname
end

return network
