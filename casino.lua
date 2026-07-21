local hardware = require("core.hardware")
local display = require("core.display")
local ui = require("core.ui")
local menu = require("games.menu")

local function showMessage(title, message, color)
    ui.clear()
    display.clear()
    display.border()
    display.center(2, title, color or colors.yellow)
    display.center(6, message, colors.white)
    display.center(9, "TOUCH TO RETURN", colors.lightGray)
end

local function returnToMenuOnTouch()
    os.pullEvent("monitor_touch")
    menu.open()
end

local function unavailable(title, message)
    showMessage(title, message, colors.orange)
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
            unavailable("INSERT DIAMONDS", "WALLET MODULE IS NEXT")
        end,
        voucher = function()
            unavailable("INSERT VOUCHER", "TICKET SYSTEM IS PLANNED")
        end,
        games = function()
            unavailable("CHOOSE GAME", "SLOTS COMING AFTER WALLET")
        end,
        cashout = function()
            unavailable("CASH OUT", "NO ACTIVE BALANCE")
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
        display.center(2, "CASINO ROYAL ERROR", colors.red)
        display.center(5, tostring(problem), colors.white)
    end)
    error(problem, 0)
end
