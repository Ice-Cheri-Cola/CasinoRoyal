local hardware = {}

local devices = {
    monitor = nil,
    speaker = nil,
    inventoryManager = nil,
    modem = nil,
    diskDrive = nil
}

local function findFirst(types)
    for _, peripheralType in ipairs(types) do
        local wrapped = peripheral.find(peripheralType)
        if wrapped then
            return wrapped
        end
    end
    return nil
end

function hardware.scan()
    devices.monitor = peripheral.find("monitor")
    devices.speaker = peripheral.find("speaker")
    devices.inventoryManager = findFirst({
        "inventory_manager",
        "inventoryManager"
    })
    devices.modem = peripheral.find("modem")
    devices.diskDrive = peripheral.find("drive")
    return devices
end

function hardware.get()
    return devices
end

function hardware.requireMonitor()
    if not devices.monitor then hardware.scan() end
    if not devices.monitor then
        error("Casino Royal requires an Advanced Monitor.", 0)
    end
    return devices.monitor
end

function hardware.getSpeaker()
    if not devices.speaker then hardware.scan() end
    return devices.speaker
end

function hardware.getInventoryManager()
    if not devices.inventoryManager then hardware.scan() end
    return devices.inventoryManager
end

function hardware.getDiskDrive()
    if not devices.diskDrive then hardware.scan() end
    return devices.diskDrive
end

function hardware.status()
    if not devices.monitor then hardware.scan() end
    return {
        monitor = devices.monitor ~= nil,
        speaker = devices.speaker ~= nil,
        inventoryManager = devices.inventoryManager ~= nil,
        modem = devices.modem ~= nil,
        diskDrive = devices.diskDrive ~= nil
    }
end

return hardware
