--================================================--
-- Casino Royal
-- Version: 0.1.0
-- File: core/display.lua
-- Description: Monitor drawing engine
--================================================--

local display = {}

local theme =  require("core.theme")

local monitor = nil


--------------------------------------------------
-- Initialize monitor
--------------------------------------------------

function display.init(name)

    monitor = peripheral.wrap(name)

    if monitor == nil then
        error(
            "Monitor not found: " 
            .. tostring(name)
        )
    end


    monitor.setTextScale(1)

    display.clear()

end



--------------------------------------------------
-- Clear screen
--------------------------------------------------

function display.clear()

    if monitor then

        monitor.setBackgroundColor(
            colors.black
        )

        monitor.setTextColor(
            colors.white
        )

        monitor.clear()

    end

end



--------------------------------------------------
-- Get screen size
--------------------------------------------------

function display.size()

    if monitor then
        return monitor.getSize()
    end

    return 0,0

end



--------------------------------------------------
-- Center text
--------------------------------------------------

function display.center(
    y,
    text,
    color
)

    if not monitor then
        return
    end


    local width =
        monitor.getSize()


    local x =
        math.floor(
            (width - #text) / 2
        )


    monitor.setCursorPos(
        x + 1,
        y
    )


    if color then
        monitor.setTextColor(color)
    end


    monitor.write(text)

end



--------------------------------------------------
-- Draw title
--------------------------------------------------

function display.title(text)

    local width,height =
        display.size()


    display.center(
        2,
        "♛ " .. text .. " ♛",
        colors.yellow
    )


end



--------------------------------------------------
-- Draw border
--------------------------------------------------

function display.border()

    local width,height =
        display.size()


    monitor.setTextColor(
        colors.gold
    )


    monitor.setCursorPos(
        1,
        1
    )


    monitor.write(
        string.rep(
            "=",
            width
        )
    )


    monitor.setCursorPos(
        1,
        height
    )


    monitor.write(
        string.rep(
            "=",
            width
        )
    )

end



return display
