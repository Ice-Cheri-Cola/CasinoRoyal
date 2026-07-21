local hardware = require("core.hardware")
local display = require("core.display")
local ui = require("core.ui")
local menu = require("games.menu")
local slots = require("games.slots")
local wallet = require("core.wallet")
local receipts = require("core.receipts")

local function speakerNote(instrument, pitch, volume)
    local speaker = hardware.getSpeaker()
    if not speaker or not speaker.playNote then return end
    pcall(speaker.playNote, instrument or "pling", volume or 1, pitch or 12)
end

local function showMessage(title, lines, color, footer)
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

    display.center(height - 2, footer or "TOUCH TO RETURN", colors.lightGray)
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

local function depositAnimation()
    local frames = {
        { "SCANNING INVENTORY", "PLEASE WAIT" },
        { "DIAMONDS DETECTED", "VERIFYING AMOUNT" },
        { "MOVING TO VAULT", "SECURING FUNDS" }
    }

    for index, lines in ipairs(frames) do
        showMessage("DEPOSIT", lines, index == #frames and colors.yellow or colors.lightBlue, "PROCESSING...")
        speakerNote("hat", 7 + index * 2, 0.65)
        sleep(0.45)
    end
end

local function animateBalance(oldBalance, newBalance)
    local difference = math.max(0, newBalance - oldBalance)
    local steps = math.min(14, math.max(4, difference))

    for step = 1, steps do
        local shown = oldBalance + math.floor(difference * step / steps)
        showMessage("DEPOSIT ACCEPTED", {
            "BALANCE",
            tostring(shown),
            "+" .. tostring(difference) .. " DIAMONDS"
        }, step == steps and colors.lime or colors.yellow, "COUNTING CREDITS...")
        speakerNote("pling", 9 + step % 7, 0.7)
        sleep(0.07)
    end
end

local function deposit()
    local oldBalance = wallet.getBalance()
    depositAnimation()

    local ok, amount, status, transaction = wallet.depositAll()

    if ok then
        local newBalance = wallet.getBalance()
        menu.setBalance(newBalance)
        animateBalance(oldBalance, newBalance)

        local printed, printStatus = receipts.printDeposit(
            amount,
            newBalance,
            status,
            transaction
        )
        local receiptLine
        local receiptColor = colors.lime

        if printed then
            receiptLine = printStatus
        elseif hardware.getPrinter() then
            receiptLine = printStatus
            receiptColor = colors.orange
        else
            receiptLine = "NO PRINTER CONNECTED"
            receiptColor = colors.lightGray
        end

        local transactionLine = "ID: " .. tostring(
            transaction and transaction.id or "UNAVAILABLE"
        )

        showMessage("DEPOSIT COMPLETE", {
            "+" .. tostring(amount) .. " DIAMONDS",
            "BALANCE: " .. tostring(newBalance),
            transactionLine,
            tostring(status),
            receiptLine
        }, status == "VAULT FULL" and colors.orange or colors.lime)

        speakerNote("bell", 16, 1)
        sleep(0.08)
        speakerNote("bell", 20, 1)

        if receiptColor == colors.orange then
            sleep(0.2)
            speakerNote("bass", 5, 0.6)
        end
    else
        showMessage("DEPOSIT FAILED", {
            tostring(status)
        }, colors.red)
        speakerNote("bass", 4, 1)
    end

    returnToMenuOnTouch()
end

local function openSlots()
    slots.setBalance(wallet.getBalance())
    slots.setHandlers({
        betDown = function() end,
        betUp = function() end,
        spin = function() end,
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