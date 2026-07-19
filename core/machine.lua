--================================================--
-- Casino Royal
-- Version: 4.0.0
-- File: core/machine.lua
-- Description: Machine configuration and runtime manager
--================================================--

local network =
    require("core.network")

local protocol =
    require("core.protocol")

local logger =
    require("core.logger")

local machine = {}

--------------------------------------------------
-- Configuration paths
--------------------------------------------------

local CONFIG_DIRECTORY =
    "config"

local CONFIG_PATH =
    CONFIG_DIRECTORY
    .. "/machine.txt"

--------------------------------------------------
-- Timing
--------------------------------------------------

local HEARTBEAT_INTERVAL =
    5

local RESPONSE_TIMEOUT =
    3

local REGISTER_RETRY_INTERVAL =
    5

--------------------------------------------------
-- Default configuration
--------------------------------------------------

local defaultConfig = {
    id = nil,
    type = "menu",
    name = "Casino Terminal",
    enabled = true
}

local validTypes = {
    menu = true,
    slots = true,
    blackjack = true,
    roulette = true,
    higher_lower = true,
    video_poker = true,
    craps = true,
    atm = true,
    admin = true,
    server = true
}

--------------------------------------------------
-- Runtime state
--------------------------------------------------

local state = {
    config = nil,

    running = false,

    registered = false,

    serverId = nil,

    status =
        protocol.STATUS_IDLE,

    player = nil,

    lastHeartbeat = nil,

    lastRegistration = nil,

    lastError = nil
}

--------------------------------------------------
-- Utility functions
--------------------------------------------------

local function copyTable(source)
    local result = {}

    for key, value
        in pairs(source)
    do
        result[key] = value
    end

    return result
end

local function currentTime()
    return os.epoch("utc")
end

local function ensureDirectory()
    if not fs.exists(
        CONFIG_DIRECTORY
    )
    then
        fs.makeDir(
            CONFIG_DIRECTORY
        )
    end
end

local function createDefaultId()
    return "casino_"
        .. tostring(
            os.getComputerID()
        )
end

local function normalizeText(
    value,
    fallback
)
    local text =
        tostring(
            value
            or fallback
            or ""
        )

    if text == "" then
        return tostring(
            fallback
            or ""
        )
    end

    return text
end

--------------------------------------------------
-- Configuration validation
--------------------------------------------------

function machine.isValidType(machineType)
    return validTypes[machineType]
        == true
end

function machine.getTypes()
    return {
        "menu",
        "slots",
        "blackjack",
        "roulette",
        "higher_lower",
        "video_poker",
        "craps",
        "atm",
        "admin",
        "server"
    }
end

function machine.getDefault()
    local config =
        copyTable(defaultConfig)

    config.id =
        createDefaultId()

    return config
end

--------------------------------------------------
-- Save configuration
--------------------------------------------------

function machine.save(config)
    if type(config) ~= "table" then
        return false,
            "INVALID CONFIGURATION"
    end

    if not machine.isValidType(
        config.type
    )
    then
        return false,
            "INVALID MACHINE TYPE"
    end

    ensureDirectory()

    local file =
        fs.open(
            CONFIG_PATH,
            "w"
        )

    if file == nil then
        return false,
            "COULD NOT OPEN CONFIG FILE"
    end

    local savedConfig = {
        id =
            normalizeText(
                config.id,
                createDefaultId()
            ),

        type =
            config.type,

        name =
            normalizeText(
                config.name,
                "Casino Terminal"
            ),

        enabled =
            config.enabled
            ~= false
    }

    file.write(
        textutils.serialize(
            savedConfig
        )
    )

    file.close()

    if state.config ~= nil then
        state.config =
            copyTable(savedConfig)
    end

    return true
end

--------------------------------------------------
-- Load configuration
--------------------------------------------------

function machine.load()
    if not fs.exists(
        CONFIG_PATH
    )
    then
        local config =
            machine.getDefault()

        local success, problem =
            machine.save(config)

        if not success then
            return nil,
                problem
        end

        state.config =
            copyTable(config)

        return config
    end

    local file =
        fs.open(
            CONFIG_PATH,
            "r"
        )

    if file == nil then
        return nil,
            "COULD NOT READ CONFIG FILE"
    end

    local contents =
        file.readAll()

    file.close()

    local config =
        textutils.unserialize(
            contents
        )

    if type(config) ~= "table" then
        return nil,
            "CONFIG FILE IS INVALID"
    end

    if not machine.isValidType(
        config.type
    )
    then
        return nil,
            "CONFIG HAS INVALID TYPE"
    end

    config.id =
        normalizeText(
            config.id,
            createDefaultId()
        )

    config.name =
        normalizeText(
            config.name,
            "Casino Terminal"
        )

    config.enabled =
        config.enabled
        ~= false

    state.config =
        copyTable(config)

    return config
end

--------------------------------------------------
-- Configuration helpers
--------------------------------------------------

function machine.exists()
    return fs.exists(
        CONFIG_PATH
    )
end

function machine.reset()
    if fs.exists(
        CONFIG_PATH
    )
    then
        fs.delete(
            CONFIG_PATH
        )
    end

    state.config = nil
    state.registered = false
    state.serverId = nil

    return machine.getDefault()
end

function machine.getPath()
    return CONFIG_PATH
end

function machine.getConfig()
    if state.config == nil then
        local config, problem =
            machine.load()

        if config == nil then
            return nil,
                problem
        end
    end

    return copyTable(
        state.config
    )
end

--------------------------------------------------
-- Machine information
--------------------------------------------------

function machine.getId()
    local config =
        machine.getConfig()

    if config == nil then
        return nil
    end

    return config.id
end

function machine.getName()
    local config =
        machine.getConfig()

    if config == nil then
        return nil
    end

    return config.name
end

function machine.getType()
    local config =
        machine.getConfig()

    if config == nil then
        return nil
    end

    return config.type
end

function machine.isEnabled()
    local config =
        machine.getConfig()

    return config ~= nil
        and config.enabled
        == true
end

--------------------------------------------------
-- Runtime status
--------------------------------------------------

function machine.setStatus(status)
    if status ~= protocol.STATUS_IDLE
    and status ~= protocol.STATUS_BUSY
    and status ~= protocol.STATUS_OFFLINE
    then
        return false,
            "INVALID MACHINE STATUS"
    end

    state.status =
        status

    return true
end

function machine.getStatus()
    return state.status
end

function machine.setPlayer(playerName)
    if playerName == nil
    or tostring(playerName) == ""
    then
        state.player = nil
    else
        state.player =
            tostring(playerName)
    end

    return state.player
end

function machine.clearPlayer()
    state.player = nil
end

function machine.getPlayer()
    return state.player
end

--------------------------------------------------
-- Network payload
--------------------------------------------------

local function createMachineData()
    local config, problem =
        machine.getConfig()

    if config == nil then
        return nil,
            problem
    end

    return {
        id =
            config.id,

        name =
            config.name,

        type =
            config.type,

        enabled =
            config.enabled,

        status =
            state.status,

        player =
            state.player,

        version =
            protocol.VERSION,

        computerId =
            os.getComputerID(),

        computerLabel =
            os.getComputerLabel()
    }
end

--------------------------------------------------
-- Reply validation
--------------------------------------------------

local function waitForReply(
    expectedSender,
    expectedType
)
    local deadline =
        currentTime()
        + (
            RESPONSE_TIMEOUT
            * 1000
        )

    while currentTime() < deadline do
        local remaining =
            (
                deadline
                - currentTime()
            ) / 1000

        local senderId, message =
            network.receive(
                math.max(
                    0.1,
                    remaining
                )
            )

        if senderId ~= nil
        and message ~= nil
        and senderId == expectedSender
        and message.type == expectedType
        then
            return message.data
                or {}
        end
    end

    return nil,
        "SERVER RESPONSE TIMEOUT"
end

--------------------------------------------------
-- Server registration
--------------------------------------------------

function machine.register()
    local config, configProblem =
        machine.getConfig()

    if config == nil then
        state.lastError =
            configProblem

        return false,
            configProblem
    end

    if config.type == "server" then
        return false,
            "SERVER CANNOT REGISTER WITH ITSELF"
    end

    if not config.enabled then
        return false,
            "MACHINE IS DISABLED"
    end

    local opened, openProblem =
        network.open()

    if not opened then
        state.registered = false
        state.lastError =
            openProblem

        return false,
            openProblem
    end

    local serverId, findProblem =
        network.findServer()

    if serverId == nil then
        state.registered = false
        state.serverId = nil
        state.lastError =
            findProblem

        return false,
            findProblem
    end

    local data, dataProblem =
        createMachineData()

    if data == nil then
        state.lastError =
            dataProblem

        return false,
            dataProblem
    end

    local sent, sendProblem =
        network.send(
            serverId,
            protocol.REGISTER,
            data
        )

    if not sent then
        state.registered = false
        state.lastError =
            sendProblem

        return false,
            sendProblem
    end

    local reply, replyProblem =
        waitForReply(
            serverId,
            protocol.REGISTER_ACK
        )

    if reply == nil then
        state.registered = false
        state.serverId = nil
        state.lastError =
            replyProblem

        return false,
            replyProblem
    end

    if reply.success ~= true then
        local problem =
            reply.error
            or reply.message
            or "REGISTRATION REJECTED"

        state.registered = false
        state.lastError =
            problem

        return false,
            problem
    end

    state.registered = true
    state.serverId =
        reply.serverId
        or serverId

    state.lastRegistration =
        currentTime()

    state.lastError = nil

    logger.info(
        "Machine registered with server: "
        .. tostring(state.serverId)
    )

    return true,
        reply
end

--------------------------------------------------
-- Heartbeats
--------------------------------------------------

function machine.sendHeartbeat()
    if not state.registered
    or state.serverId == nil
    then
        local registered, problem =
            machine.register()

        if not registered then
            return false,
                problem
        end
    end

    local data, dataProblem =
        createMachineData()

    if data == nil then
        state.lastError =
            dataProblem

        return false,
            dataProblem
    end

    local sent, sendProblem =
        network.send(
            state.serverId,
            protocol.HEARTBEAT,
            data
        )

    if not sent then
        state.registered = false
        state.serverId = nil
        state.lastError =
            sendProblem

        return false,
            sendProblem
    end

    local reply, replyProblem =
        waitForReply(
            state.serverId,
            protocol.HEARTBEAT_ACK
        )

    if reply == nil then
        state.registered = false
        state.serverId = nil
        state.lastError =
            replyProblem

        return false,
            replyProblem
    end

    if reply.success ~= true then
        state.registered = false

        local problem =
            reply.error
            or reply.message
            or "HEARTBEAT REJECTED"

        state.lastError =
            problem

        return false,
            problem
    end

    state.registered = true
    state.lastHeartbeat =
        currentTime()

    state.lastError = nil

    return true,
        reply
end

--------------------------------------------------
-- Start and stop
--------------------------------------------------

function machine.start()
    if state.running then
        return true
    end

    local config, problem =
        machine.load()

    if config == nil then
        state.lastError =
            problem

        return false,
            problem
    end

    if not config.enabled then
        return false,
            "MACHINE IS DISABLED"
    end

    state.running = true
    state.status =
        protocol.STATUS_IDLE

    if config.type == "server" then
        return true
    end

    local registered, registerProblem =
        machine.register()

    if not registered then
        logger.warning(
            "Initial registration failed: "
            .. tostring(registerProblem)
        )

        return true,
            registerProblem
    end

    return true
end

function machine.stop()
    state.running = false
    state.registered = false
    state.serverId = nil
    state.status =
        protocol.STATUS_OFFLINE

    network.close()

    return true
end

function machine.isRunning()
    return state.running
end

function machine.isRegistered()
    return state.registered
end

function machine.getServerId()
    return state.serverId
end

--------------------------------------------------
-- Heartbeat service
--------------------------------------------------

function machine.heartbeatLoop()
    if not state.running then
        local started, problem =
            machine.start()

        if not started then
            error(
                problem
                or "MACHINE COULD NOT START"
            )
        end
    end

    while state.running do
        local config =
            machine.getConfig()

        if config
        and config.type ~= "server"
        then
            local success, problem =
                machine.sendHeartbeat()

            if not success then
                logger.warning(
                    "Heartbeat failed: "
                    .. tostring(problem)
                )

                sleep(
                    REGISTER_RETRY_INTERVAL
                )
            else
                sleep(
                    HEARTBEAT_INTERVAL
                )
            end
        else
            sleep(
                HEARTBEAT_INTERVAL
            )
        end
    end
end

--------------------------------------------------
-- Runtime information
--------------------------------------------------

function machine.getState()
    return {
        running =
            state.running,

        registered =
            state.registered,

        serverId =
            state.serverId,

        status =
            state.status,

        player =
            state.player,

        lastHeartbeat =
            state.lastHeartbeat,

        lastRegistration =
            state.lastRegistration,

        lastError =
            state.lastError
    }
end

function machine.getLastHeartbeat()
    return state.lastHeartbeat
end

function machine.getLastError()
    return state.lastError
end

function machine.getVersion()
    return protocol.VERSION
end

--------------------------------------------------
-- Return module
--------------------------------------------------

return machine
