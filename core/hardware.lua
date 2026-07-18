--================================================--
-- Casino Royal
-- Version: 0.1.0
-- File: core/hardware.lua
-- Description: Hardware detection and management
--================================================--

local hardware = {}

hardware.devices = {
    monitor = nil,
    speaker = nil,
    inventory = nil,
    storage = nil,
    allMonitors = {}
}


--------------------------------------------------
-- Scan all attached peripherals
--------------------------------------------------

function hardware.scan()

    local peripherals = peripheral.getNames()

    for _, name in ipairs(peripherals) do
        
        local pType = peripheral.getType(name)

        if pType then

            -- Detect monitors
            if pType == "monitor" then
                
                table.insert(
                    hardware.devices.allMonitors,
                    name
                )

                -- Prefer top monitor
                if name == "top" then
                    hardware.devices.monitor = name
                end

            end


            -- Detect speakers
            if pType == "speaker" then
                hardware.devices.speaker = name
            end


            -- Detect inventory managers
            if pType == "inventory_manager" then
                hardware.devices.inventory = name
            end


            -- Detect storage inventories
            if string.find(pType, "inventory") then
                hardware.devices.storage = name
            end

        end
    end


    -- If top monitor was not found,
    -- choose first available monitor

    if hardware.devices.monitor == nil then
        
        hardware.devices.monitor =
            hardware.devices.allMonitors[1]

    end


    return hardware.devices

end



--------------------------------------------------
-- Get hardware information
--------------------------------------------------

function hardware.get()

    return hardware.devices

end



--------------------------------------------------
-- Check if required hardware exists
--------------------------------------------------

function hardware.ready()

    if hardware.devices.monitor
    and hardware.devices.speaker
    then
        return true
    end

    return false

end



return hardware
