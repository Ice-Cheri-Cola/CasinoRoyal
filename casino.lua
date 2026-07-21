local hardware = require("core.hardware")
local display = require("core.display")
local ui = require("core.ui")
local menu = require("games.menu")

local function showMessage(title, lines, color)
    ui.clear()
    display.clear()
    display.border()

    local _, height = display.size()
    display.center(2, title, color or colors.yellow)

    if type(lines) ~= "table" then
        lines = { tostring(lines or "") }
    end

    local startY = math.max(4, math.floor(height / 2) - math.floor(#lines / 2))
    for index, line in ipairs(lines) do
        display.center(startY + index - 1, line, colors.white)
    end

    display.center(height - 2, "TOUCH TO RETURN", colors.lightGray)
end

local function returnToMenuOnTouch()
    os.pullEvent("monitor_touch")
    menu.open()
end

local function unavailable(title, lines)
    showMessage(title, lines, colors.orange)
    returnToMenuOnTouch()
end

local function initialize()
    local devices = hardware.scan()
    local monitor = hardware.requireMonitor()
    monitor.setTextScale(0.5)

    display.clear()
    display.border()
    display.center(4, "CASINO ROYAL", colors.yellow)
    display.center(6, "SYSTEM STARTING", colors.white)

    sleep(0.8)

    menu.setHandlers({
        deposit = function()
            unavailable("DEPOSIT", {
                "WALLET SYSTEM",
                "COMING SOON"
            })
        end,
        voucher = function()
            unavailable("VOUCHER", {
                "VOUCHER SYSTEM",
                "COMING SOON"
            })
        end,
        games = function()
            unavailable("PLAY", {
                "SLOTS ARE NEXT"
            })
        end,
        cashout = function()
            unavailable("CASH OUT", {
                "BALANCE IS EMPTY"
            })
        end
    })

    menu.setBalance(0)
    menu.open()

    return devices
end

local function run()
    initialize()

    while true do
        local event, _, x, y = os.pullEvent()
        if event == "monitor_touch" then
            ui.handleTouch(x, y)
        elseif event == "peripheral_detach" or event == "peripheral" then
            hardware.scan()
        elseif event == "terminate" then
            display.clear()
            return
        end
    end
end

local ok, problem = pcall(run)
if not ok then
    pcall(function()
        display.clear()
        display.center(2, "CASINO ERROR", colors.red)
        display.center(5, tostring(problem), colors.white)
    end)
    error(problem, 0)
end