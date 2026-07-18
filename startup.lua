--================================================--
-- Casino Royal
-- Version: 0.1.0
-- File: startup.lua
-- Description: Main boot sequence
--================================================--


--------------------------------------------------
-- Load modules
--------------------------------------------------

local config = require("config")

local hardware =
    require("core.hardware")

local logger =
    require("core.logger")

local display =
    require("core.display")



--------------------------------------------------
-- Boot Start
--------------------------------------------------

logger.clear()

logger.info(
    "Casino Royal Starting"
)


--------------------------------------------------
-- Hardware Scan
--------------------------------------------------

local devices =
    hardware.scan()


logger.info(
    "Hardware Scan Complete"
)



--------------------------------------------------
-- Check Monitor
--------------------------------------------------

if devices.monitor == nil then

    logger.error(
        "No monitor detected"
    )

    print(
        "ERROR: No monitor found"
    )

    return

end



--------------------------------------------------
-- Initialize Display
--------------------------------------------------

display.init(
    devices.monitor
)


--------------------------------------------------
-- Draw Boot Screen
--------------------------------------------------

display.clear()


display.border()


display.center(
    4,
    "CASINO ROYAL",
    colors.yellow
)


display.center(
    6,
    "ATM10 EDITION",
    colors.cyan
)


display.center(
    8,
    "Initializing...",
    colors.white
)


sleep(2)


display.clear()

display.border()


display.title(
    config.casinoName
)


display.center(
    6,
    "SYSTEM READY",
    colors.lime
)


logger.info(
    "Casino Royal Ready"
)
