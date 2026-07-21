local hardware = require("core.hardware")
local display = require("core.display")
local ui = require("core.ui")
local menu = require("games.menu")
local slots = require("games.slots")
local wallet = require("core.wallet")

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

local function openMenu()
    menu.setBalance(wallet.getBalance())
    menu.open()
end

local function returnToMenuOnTouch()
    os.pullEvent("monitor_touch")
    openMenu()
end

local function unavailable(title, lines)
    showMessage(title, lines, colors.orange)
    returnToMenuOnTouch()
end

local function deposit()
    showMessage("DEPOSIT", {
        "CHECKING INVENTORY",
        "PLEASE WAIT"
    }, colors.yellow)

    local ok, amount, status = wallet.depositAll()

    if ok then
        menu.setBalance(wallet.getBalance())
        showMessage("DEPOSIT", {
            "+" .. tostring(amount) .. " DIAMONDS",
            tostring(status)
        }, status == "VAULT FULL" and colors.orange or colors.lime)
    else
        showMessage("DEPOSIT", {
            tostring(status)
        }, colors.red)
    end

    returnToMenuOnTouch()
end

local function openSlots()
    slots.setBalance(wallet.getBalance())
    slots.setHandlers({
        betDown = function()
        end,
        betUp = function()
        end,
        spin = function()
        end,
        back = openMenu
    })
    slots.open()
end

local function initialize()
    local devices = hardware.scan()
    local monitor = hardware.requireMonitor()
    monitor.setTextScale(0.5)

    display.clear()
    display.border()
    display.center(4, "CASINO ROYAL", colors.yellow)
    display.center(6, "SYSTEM STARTING", colors.white)

    wallet.load()
    sleep(0.8)

    menu.setHandlers({
        deposit = deposit,
        voucher = function()
            unavailable("VOUCHER", {
                "VOUCHER SYSTEM",
                "COMING SOON"
            })
        end,
        games = openSlots,
        cashout = function()
            unavailable("CASH OUT", {
                "COMING SOON"
            })
        end
    })

    openMenu()

    return devices
end

local function run()
    initialize()

    while true do
        local event, p1, x, y = os.pullEvent()
        local handledBySlots = slots.handleEvent(event, p1)

        if event == "monitor_touch" and not handledBySlots then
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