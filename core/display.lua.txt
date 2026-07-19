--================================================--
-- Casino Royal
-- Version: 0.5.5
-- File: core/display.lua
-- Description: Monitor drawing engine
--================================================--

local display = {}
local theme = require("core.theme")

local monitor = nil
local monitorName = "top"

--------------------------------------------------
-- Get or reconnect monitor
--------------------------------------------------

local function getMonitor()
    if monitor == nil then
        monitor = peripheral.wrap(monitorName)
    end

    if monitor == nil then
        error(
            "Monitor not found: "
            .. tostring(monitorName)
        )
    end

    return monitor
end

--------------------------------------------------
-- Initialize monitor
--------------------------------------------------

function display.init(name)
    monitorName = name or "top"
    monitor = peripheral.wrap(monitorName)

    if monitor == nil then
        error(
            "Monitor not found: "
            .. tostring(monitorName)
        )
    end

    monitor.setTextScale(1)
    display.clear()
end

--------------------------------------------------
-- Clear screen
--------------------------------------------------

function display.clear()
    local screen = getMonitor()

    screen.setBackgroundColor(
        theme.get().background
    )

    screen.setTextColor(colors.white)
    screen.clear()
end

--------------------------------------------------
-- Get screen size
--------------------------------------------------

function display.size()
    local screen = getMonitor()
    return screen.getSize()
end

--------------------------------------------------
-- Center text
--------------------------------------------------

function display.center(y, text, color)
    local screen = getMonitor()
    local width = screen.getSize()

    local x = math.floor(
        (width - #text) / 2
    )

    screen.setCursorPos(x + 1, y)

    if color then
        screen.setTextColor(color)
    end

    screen.write(text)
end

--------------------------------------------------
-- Draw title
--------------------------------------------------

function display.title(text)
    display.center(
        2,
        "* " .. text .. " *",
        theme.get().primary
    )
end

--------------------------------------------------
-- Draw border
--------------------------------------------------

function display.border()
    local screen = getMonitor()
    local width, height = screen.getSize()

    screen.setTextColor(
        theme.get().secondary
    )

    screen.setCursorPos(1, 1)
    screen.write(
        string.rep("=", width)
    )

    screen.setCursorPos(1, height)
    screen.write(
        string.rep("=", width)
    )
end

return display
