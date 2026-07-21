local receipts = {}

local hardware = require("core.hardware")

local function centerText(text, width)
    text = tostring(text or "")
    if #text >= width then return text:sub(1, width) end
    return string.rep(" ", math.floor((width - #text) / 2)) .. text
end

function receipts.printDeposit(amount, balance, status)
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

    line(1, centerText("CASINO ROYAL BANK", width))
    line(2, string.rep("=", width))
    line(4, "TRANSACTION: DEPOSIT")
    line(6, "AMOUNT: +" .. tostring(amount))
    line(7, "CURRENCY: DIAMONDS")
    line(9, "NEW BALANCE: " .. tostring(balance))
    line(11, tostring(status or "DEPOSIT COMPLETE"))
    line(13, string.rep("-", width))
    line(15, centerText("THANK YOU", width))

    if printer.setPageTitle then
        pcall(printer.setPageTitle, "Casino Royal Deposit")
    end

    local ended, printed = pcall(printer.endPage)
    if not ended or not printed then
        return false, "PRINTER COULD NOT FINISH PAGE"
    end

    return true, "RECEIPT PRINTED"
end

return receipts
