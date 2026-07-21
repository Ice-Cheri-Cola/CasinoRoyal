local receipts = {}

local hardware = require("core.hardware")

local function centerText(text, width)
    text = tostring(text or "")
    if #text >= width then return text:sub(1, width) end
    return string.rep(" ", math.floor((width - #text) / 2)) .. text
end

local function formatDate(timestamp, includeTime)
    timestamp = math.floor((tonumber(timestamp) or os.epoch("utc")) / 1000)
    local pattern = includeTime and "%Y-%m-%d %H:%M" or "%Y-%m-%d"
    local ok, value = pcall(os.date, pattern, timestamp)
    if ok and value then return value end
    return "DATE UNAVAILABLE"
end

local function beginPage()
    local printer = hardware.getPrinter()
    if not printer then return nil, nil, "NO PRINTER CONNECTED" end
    if printer.getPaperLevel and printer.getPaperLevel() <= 0 then return nil, nil, "PRINTER NEEDS PAPER" end
    if printer.getInkLevel and printer.getInkLevel() <= 0 then return nil, nil, "PRINTER NEEDS INK" end
    local ok, started = pcall(printer.newPage)
    if not ok or not started then return nil, nil, "PRINTER COULD NOT START PAGE" end
    local width = 25
    if printer.getPageSize then
        local pageWidth = printer.getPageSize()
        width = tonumber(pageWidth) or width
    end
    return printer, width
end

local function finishPage(printer, title)
    if printer.setPageTitle then pcall(printer.setPageTitle, title) end
    local ended, printed = pcall(printer.endPage)
    if not ended or not printed then return false, "PRINTER COULD NOT FINISH PAGE" end
    return true
end

function receipts.printDeposit(amount, balance, status, transaction)
    local printer, width, problem = beginPage()
    if not printer then return false, problem end
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
    line(13, formatDate(timestamp, true))
    line(15, tostring(status or "DEPOSIT COMPLETE"))
    line(17, string.rep("-", width))
    line(19, centerText("THANK YOU FOR VISITING", width))
    line(20, centerText("CASINO ROYAL", width))
    local ok, finishProblem = finishPage(printer, "Casino Royal " .. tostring(transactionId))
    if not ok then return false, finishProblem end
    return true, "RECEIPT " .. tostring(transactionId) .. " PRINTED"
end

function receipts.printMembershipCard(profile)
    if type(profile) ~= "table" then return false, "NO ACTIVE MEMBER" end
    local printer, width, problem = beginPage()
    if not printer then return false, problem end
    local function line(y, text)
        printer.setCursorPos(1, y)
        printer.write(tostring(text or ""):sub(1, width))
    end
    line(1, centerText("CASINO ROYAL", width))
    line(2, centerText("MEMBERSHIP CARD", width))
    line(3, string.rep("=", width))
    line(5, centerText(profile.displayName or profile.username or "MEMBER", width))
    line(7, "MEMBER ID")
    line(8, tostring(profile.id or "UNAVAILABLE"))
    line(10, "RANK")
    line(11, tostring(profile.rank or "MEMBER"))
    line(13, "MEMBER SINCE")
    line(14, formatDate(profile.joinedAt, false))
    line(16, string.rep("-", width))
    line(18, centerText("PROPERTY OF", width))
    line(19, centerText(profile.displayName or profile.username or "MEMBER", width))
    line(21, centerText("CASINO ROYAL", width))
    local ok, finishProblem = finishPage(printer, "Member " .. tostring(profile.id or "Card"))
    if not ok then return false, finishProblem end
    return true, "MEMBERSHIP CARD PRINTED"
end

return receipts