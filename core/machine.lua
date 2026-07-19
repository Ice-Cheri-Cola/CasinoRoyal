--================================================--
-- Casino Royal
-- Version: 3.0.0
-- File: core/machine.lua
-- Description: Local machine configuration manager
--================================================--

local machine = {}

--------------------------------------------------
-- Configuration
--------------------------------------------------

local configDirectory =
    "config"

local configPath =
    configDirectory
    .. "/machine.txt"

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
-- Copy table
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

--------------------------------------------------
-- Create configuration directory
--------------------------------------------------

local function ensureDirectory()
    if not fs.exists(
        configDirectory
    )
    then
        fs.makeDir(
            configDirectory
        )
    end
end

--------------------------------------------------
-- Create a default machine ID
--------------------------------------------------

local function createDefaultId()
    return "casino_"
        .. tostring(
            os.getComputerID()
        )
end

--------------------------------------------------
-- Validate machine type
--------------------------------------------------

function machine.isValidType(
    machineType
)
    return validTypes[machineType]
        == true
end

--------------------------------------------------
-- Get available machine types
--------------------------------------------------

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

--------------------------------------------------
-- Create default configuration
--------------------------------------------------

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
            configPath,
            "w"
        )

    if file == nil then
        return false,
            "COULD NOT OPEN CONFIG FILE"
    end

    local savedConfig = {
        id =
            config.id
            or createDefaultId(),

        type =
            config.type,

        name =
            config.name
            or "Casino Terminal",

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

    return true
end

--------------------------------------------------
-- Load configuration
--------------------------------------------------

function machine.load()
    if not fs.exists(
        configPath
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

        return config
    end

    local file =
        fs.open(
            configPath,
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
        config.id
        or createDefaultId()

    config.name =
        config.name
        or "Casino Terminal"

    config.enabled =
        config.enabled
        ~= false

    return config
end

--------------------------------------------------
-- Check whether configuration exists
--------------------------------------------------

function machine.exists()
    return fs.exists(
        configPath
    )
end

--------------------------------------------------
-- Delete local configuration
--------------------------------------------------

function machine.reset()
    if fs.exists(
        configPath
    )
    then
        fs.delete(
            configPath
        )
    end

    return machine.getDefault()
end

--------------------------------------------------
-- Get configuration path
--------------------------------------------------

function machine.getPath()
    return configPath
end

return machine
