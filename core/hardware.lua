--================================================--
-- Casino Royal
-- Version: 1.0.0
-- File: core/hardware.lua
-- Description: Hardware detection and management
--================================================--

local hardware = {}

hardware.devices = {
    monitor = nil,
    speaker = nil,
    playerDetector = nil,
    inventory = nil,
    storage = nil,
    allMonitors = {}
}

--------------------------------------------------
-- Reset detected hardware
--------------------------------------------------

function hardware.reset()
    hardware.devices.monitor = nil
    hardware.devices.speaker = nil
    hardware.devices.playerDetector = nil
    hardware.devices.inventory = nil
    hardware.devices.storage = nil
    hardware.devices.allMonitors = {}
end

--------------------------------------------------
-- Scan all attached peripherals
--------------------------------------------------

function hardware.scan()
    hardware.reset()

    local peripherals =
        peripheral.getNames()

    for _, name
        in ipairs(peripherals)
    do
        local pType =
            peripheral.getType(name)

        if pType then

            if pType == "monitor" then
                table.insert(
                    hardware.devices.allMonitors,
                    name
                )

                if name == "top" then
                    hardware.devices.monitor =
                        name
                end
            end

            if pType == "speaker" then
                hardware.devices.speaker =
                    name
            end

            if pType == "player_detector" then
                hardware.devices.playerDetector =
                    name
            end

            if pType == "inventory_manager" then
                hardware.devices.inventory =
                    name
            end

            if string.find(
                pType,
                "inventory"
            )
            and pType ~= "inventory_manager"
            then
                hardware.devices.storage =
                    name
            end
        end
    end

    if hardware.devices.monitor == nil then
        hardware.devices.monitor =
            hardware.devices.allMonitors[1]
    end

    return hardware.devices
end

--------------------------------------------------
-- Get all hardware information
--------------------------------------------------

function hardware.get()
    return hardware.devices
end

--------------------------------------------------
-- Get wrapped monitor
--------------------------------------------------

function hardware.getMonitor()
    if hardware.devices.monitor == nil then
        hardware.scan()
    end

    if hardware.devices.monitor == nil then
        error(
            "Monitor not found. "
            .. "Check the wired network."
        )
    end

    return peripheral.wrap(
        hardware.devices.monitor
    )
end

--------------------------------------------------
-- Get wrapped Player Detector
--------------------------------------------------

function hardware.getPlayerDetector()
    if hardware.devices.playerDetector == nil then
        hardware.scan()
    end

    if hardware.devices.playerDetector == nil then
        error(
            "Player Detector not found. "
            .. "Check the wired network."
        )
    end

    return peripheral.wrap(
        hardware.devices.playerDetector
    )
end

--------------------------------------------------
-- Get wrapped speaker
--------------------------------------------------

function hardware.getSpeaker()
    if hardware.devices.speaker == nil then
        hardware.scan()
    end

    if hardware.devices.speaker == nil then
        return nil
    end

    return peripheral.wrap(
        hardware.devices.speaker
    )
end

--------------------------------------------------
-- Check whether optional speaker exists
--------------------------------------------------

function hardware.hasSpeaker()
    return hardware.getSpeaker()
        ~= nil
end

--------------------------------------------------
-- Check required casino hardware
--------------------------------------------------

function hardware.ready()
    if hardware.devices.monitor == nil
    or hardware.devices.playerDetector == nil
    then
        hardware.scan()
    end

    return hardware.devices.monitor ~= nil
        and hardware.devices.playerDetector ~= nil
end

return hardware
