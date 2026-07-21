local receipts = {}

local hardware = require("core.hardware")

local function centerText(text, width)
    text = tostring(text or "")
    if #text >= width then return text:sub(1, width) end
    return string.rep(" ", math.floor((width - #text) / 2)) .. text
end

local function formatDate(timestamp)
    timestamp = math.floor((tonumber(timestamp) or os.epoch("utc")) / 1000)
    local ok, value = pcall(os.date, "%Y-%m-%d %H:%M", timestamp)
    if ok and value then return value end
    return "DATE UNAVAILABLE"
end

function receipts.printDeposit(amount, balance, status, transaction)
    local printer = hardware.getPrinter()
    if not printer then
        return false, "NO PRINTER CONNECTED"
    end

    if printer.getPaperLevel and printer.getPaperLevel() <= 0 then
        return false, "PRINTER NEEDS PAPER"
    end

    if printer.getInkLevel and printer.getInkLevel() <= 0 then
        return false, "PRINTER NEEDS INK"
    end

    local ok, started = pcall(printer.newPage)
    if not ok or not started then
        return false, "PRINTER COULD NOT START PAGE"
    end

    local width = 25
    if printer.getPageSize then
        local pageWidth = printer.getPageSize()
        width = tonumber(pageWidth) or width
    end

    local function line(y, text)
        printer.setCursorPos(1, y)
        printer.write(tostring(text or ""):sub(1, width))
    end

    local transactionId = transaction and transaction.id or "CR-UNAVAILABLE"
    local timestamp = transaction and transaction.timestamp or os.epoch("utc")

    line(1, centerText("CASINO ROYAL", width))
    line(2, centerText("OFFICIAL RECEIPT", width))
    line(3, string.rep("=", width))
    line(5, "ID: " .. tostring(transactionId))
    line(6, "TYPE: DEPOSIT")
    line(8, "AMOUNT: +" .. tostring(amount))
    line(9, "CURRENCY: DIAMONDS")
    line(11, "NEW BALANCE: " .. tostring(balance))
    line(13, formatDate(timestamp))
    line(15, tostring(status or "DEPOSIT COMPLETE"))
    line(17, string.rep("-", width))
    line(19, centerText("THANK YOU FOR VISITING", width))
    line(20, centerText("CASINO ROYAL", width))

    if printer.setPageTitle then
        pcall(printer.setPageTitle, "Casino Royal " .. tostring(transactionId))
    end

    local ended, printed = pcall(printer.endPage)
    if not ended or not printed then
        return false, "PRINTER COULD NOT FINISH PAGE"
    end

    return true, "RECEIPT " .. tostring(transactionId) .. " PRINTED"
end

return receipts