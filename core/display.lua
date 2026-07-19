--================================================--
-- Casino Royal
-- Version: 2.2.0
-- File: core/display.lua
-- Description: Monitor drawing engine
--================================================--

local display = {}

local theme =
    require("core.theme")

local hardware =
    require("core.hardware")

local monitor = nil

--------------------------------------------------
-- Get or reconnect monitor
--------------------------------------------------

local function getMonitor()
    if monitor == nil then
        monitor =
            hardware.getMonitor()
    end

    return monitor
end

--------------------------------------------------
-- Initialize monitor
--------------------------------------------------

function display.init()
    monitor =
        hardware.getMonitor()

    monitor.setTextScale(1)

    display.clear()
end

--------------------------------------------------
-- Refresh monitor connection
--------------------------------------------------

function display.refresh()
    hardware.scan()

    monitor =
        hardware.getMonitor()

    monitor.setTextScale(1)

    return monitor
end

--------------------------------------------------
-- Clear screen
--------------------------------------------------

function display.clear()
    local screen =
        getMonitor()

    screen.setBackgroundColor(
        theme.get().background
    )

    screen.setTextColor(
        colors.white
    )

    screen.clear()
end

--------------------------------------------------
-- Get screen size
--------------------------------------------------

function display.size()
    local screen =
        getMonitor()

    return screen.getSize()
end

--------------------------------------------------
-- Center text
--------------------------------------------------

function display.center(y, text, color)
    local screen =
        getMonitor()

    text =
        tostring(text or "")

    local width =
        screen.getSize()

    local x =
        math.floor(
            (width - #text) / 2
        )

    screen.setCursorPos(
        x + 1,
        y
    )

    if color then
        screen.setTextColor(
            color
        )
    end

    screen.write(text)
end

--------------------------------------------------
-- Draw title
--------------------------------------------------

function display.title(text)
    display.center(
        2,
        "* " .. tostring(text) .. " *",
        theme.get().primary
    )
end

--------------------------------------------------
-- Draw border
--------------------------------------------------

function display.border()
    local screen =
        getMonitor()

    local width, height =
        screen.getSize()

    screen.setTextColor(
        theme.get().secondary
    )

    screen.setCursorPos(
        1,
        1
    )

    screen.write(
        string.rep(
            "=",
            width
        )
    )

    screen.setCursorPos(
        1,
        height
    )

    screen.write(
        string.rep(
            "=",
            width
        )
    )
end

return display
