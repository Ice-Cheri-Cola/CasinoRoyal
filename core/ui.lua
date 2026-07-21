local ui = {}
local hardware = require("core.hardware")
local theme = require("core.theme")

local buttons = {}

local function monitor()
    return hardware.requireMonitor()
end

function ui.clear()
    buttons = {}
end

function ui.button(id, text, x, y, width, height, callback, background, foreground)
    local button = {
        id = id,
        text = tostring(text),
        x = x,
        y = y,
        width = width,
        height = height,
        callback = callback,
        background = background or theme.get().secondary,
        foreground = foreground or theme.get().background
    }

    buttons[#buttons + 1] = button

    local screen = monitor()
    screen.setBackgroundColor(button.background)
    screen.setTextColor(button.foreground)

    for row = button.y, button.y + button.height - 1 do
        screen.setCursorPos(button.x, row)
        screen.write(string.rep(" ", button.width))
    end

    local label = button.text:sub(1, button.width)
    local labelX = button.x + math.floor((button.width - #label) / 2)
    local labelY = button.y + math.floor((button.height - 1) / 2)
    screen.setCursorPos(labelX, labelY)
    screen.write(label)

    return button
end

function ui.handleTouch(x, y)
    for i = #buttons, 1, -1 do
        local button = buttons[i]
        if x >= button.x
            and x < button.x + button.width
            and y >= button.y
            and y < button.y + button.height then
            if button.callback then button.callback(button.id) end
            return button.id
        end
    end
    return nil
end

return ui
