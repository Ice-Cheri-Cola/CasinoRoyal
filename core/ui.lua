--================================================--
-- Casino Royal
-- Version: 0.3.0
-- File: core/ui.lua
-- Description: Touchscreen UI system
--================================================--

local ui = {}

local display = require("core.display")
local theme = require("core.theme")


ui.buttons = {}

--------------------------------------------------
-- Create a button
--------------------------------------------------

function ui.clearButton()
    ui.buttons = {}
end

--------------------------------------------------
-- Create a button
--------------------------------------------------

function ui.button(
    text,
    x,
    y,
    width,
    height,
    callback
)

    local button = {

        text = text,

        x = x,
        y = y,

        width = width,
        height = height,

        callback = callback

    }


    table.insert(
        ui.buttons,
        button
    )


    ui.drawButton(button)

end



--------------------------------------------------
-- Draw button
--------------------------------------------------

function ui.drawButton(button)

    local monitor = peripheral.wrap("top")

    if not monitor then
        return
    end


    monitor.setBackgroundColor(
        theme.get().secondary
    )


    for row =
        button.y,
        button.y + button.height - 1
    do

        monitor.setCursorPos(
            button.x,
            row
        )

        monitor.write(
            string.rep(
                " ",
                button.width
            )
        )

    end


    monitor.setTextColor(
        theme.get().background
    )


    monitor.setCursorPos(
        button.x + 1,
        button.y + math.floor(button.height / 2)
    )


    monitor.write(
        button.text
    )

end



--------------------------------------------------
-- Touch handler
--------------------------------------------------

function ui.handleTouch(x,y)

    for _,button in ipairs(ui.buttons)
    do

        if x >= button.x
        and x <= button.x + button.width
        and y >= button.y
        and y <= button.y + button.height
        then

            if button.callback then

                button.callback()

            end

            return true

        end

    end


    return false

end



--------------------------------------------------
-- Clear buttons
--------------------------------------------------

function ui.clear()

    ui.buttons = {}

end



return ui
