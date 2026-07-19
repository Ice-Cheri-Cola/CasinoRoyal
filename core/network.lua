--================================================--
-- Casino Royal
-- Version: 4.0.0
-- File: core/network.lua
-- Description: Casino network communication system
--================================================--

--------------------------------------------------
-- Requires
--------------------------------------------------

local protocol =
    require("core.protocol")

--------------------------------------------------
-- Module
--------------------------------------------------

local network = {}

--------------------------------------------------
-- State
--------------------------------------------------

local openedModems = {}

--------------------------------------------------
-- Private: Create network message
--------------------------------------------------

local function createMessage(
    messageType,
    data
)
    return {
        version =
            protocol.VERSION,

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
-- Private: Validate received message
--------------------------------------------------

local function isValidMessage(message)
    return type(message) == "table"
        and type(message.type) == "string"
        and message.senderId ~= nil
end

--------------------------------------------------
-- Private: Ensure network is open
--------------------------------------------------

local function ensureOpen()
    if network.isOpen() then
        return true
    end

    return network.open()
end

--------------------------------------------------
-- Open all attached modems
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
        if peripheral.getType(name) == "modem"
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
-- Host central casino server
--------------------------------------------------

function network.hostServer()
    local success, problem =
        ensureOpen()

    if not success then
        return false,
            problem
    end

    local existing =
        rednet.lookup(
            protocol.REDNET_PROTOCOL,
            protocol.SERVER_HOSTNAME
        )

    if existing
    and existing ~= os.getComputerID()
    then
        return false,
            "ANOTHER CASINO SERVER IS ONLINE"
    end

    rednet.host(
        protocol.REDNET_PROTOCOL,
        protocol.SERVER_HOSTNAME
    )

    return true
end

--------------------------------------------------
-- Stop hosting central server
--------------------------------------------------

function network.unhostServer()
    pcall(
        rednet.unhost,
        protocol.REDNET_PROTOCOL,
        protocol.SERVER_HOSTNAME
    )
end

--------------------------------------------------
-- Find central casino server
--------------------------------------------------

function network.findServer()
    local success, problem =
        ensureOpen()

    if not success then
        return nil,
            problem
    end

    local serverId =
        rednet.lookup(
            protocol.REDNET_PROTOCOL,
            protocol.SERVER_HOSTNAME
        )

    if serverId == nil then
        return nil,
            "CASINO SERVER NOT FOUND"
    end

    return serverId
end

--------------------------------------------------
-- Send message to computer
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

    if type(messageType) ~= "string" then
        return false,
            "INVALID MESSAGE TYPE"
    end

    local success, problem =
        ensureOpen()

    if not success then
        return false,
            problem
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
            protocol.REDNET_PROTOCOL
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
-- Broadcast casino message
--------------------------------------------------

function network.broadcast(
    messageType,
    data
)
    if type(messageType) ~= "string" then
        return false,
            "INVALID MESSAGE TYPE"
    end

    local success, problem =
        ensureOpen()

    if not success then
        return false,
            problem
    end

    rednet.broadcast(
        createMessage(
            messageType,
            data
        ),
        protocol.REDNET_PROTOCOL
    )

    return true
end

--------------------------------------------------
-- Receive casino message
--------------------------------------------------

function network.receive(timeout)
    local success, problem =
        ensureOpen()

    if not success then
        return nil,
            nil,
            problem
    end

    local senderId, message =
        rednet.receive(
            protocol.REDNET_PROTOCOL,
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
-- Reply to received message
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
-- Create message without sending
--------------------------------------------------

function network.createMessage(
    messageType,
    data
)
    return createMessage(
        messageType,
        data
    )
end

--------------------------------------------------
-- Validate network message
--------------------------------------------------

function network.isValidMessage(message)
    return isValidMessage(message)
end

--------------------------------------------------
-- Get Rednet protocol name
--------------------------------------------------

function network.getProtocol()
    return protocol.REDNET_PROTOCOL
end

--------------------------------------------------
-- Get server hostname
--------------------------------------------------

function network.getServerHostname()
    return protocol.SERVER_HOSTNAME
end

--------------------------------------------------
-- Get protocol version
--------------------------------------------------

function network.getVersion()
    return protocol.VERSION
end

--------------------------------------------------
-- Return module
--------------------------------------------------

return network
