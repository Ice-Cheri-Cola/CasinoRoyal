--================================================--
-- Casino Royal
-- File: core/cashout.lua
-- Description: Converts machine credits into casino vouchers safely
--================================================--

local credits = require("core.credits")
local vouchers = require("core.vouchers")

local cashout = {}

local function wholeNumber(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

-- Converts the entire machine-credit balance into one active voucher.
-- The voucher is created first. Credits are then cleared. If clearing the
-- credits fails, the voucher is cancelled so value cannot be duplicated.
function cashout.all(issuedFor, note)
    local amount = wholeNumber(credits.get())

    if amount <= 0 then
        return false, "NO CREDITS TO CASH OUT"
    end

    local created, voucherOrProblem = vouchers.create(
        amount,
        issuedFor,
        note or "MACHINE CASH OUT"
    )

    if not created then
        return false, voucherOrProblem or "VOUCHER CREATION FAILED"
    end

    local voucher = voucherOrProblem
    local cleared, oldBalanceOrProblem = credits.reset(
        "CASH OUT " .. tostring(voucher.id)
    )

    if not cleared then
        vouchers.cancel(
            voucher.id,
            "CREDIT RESET FAILED",
            "CASHOUT ROLLBACK"
        )

        return false, oldBalanceOrProblem or "COULD NOT CLEAR CREDITS"
    end

    return true, voucher
end

-- Cashes out a specific amount while leaving the remaining credits loaded.
-- This is intended for future partial-cash-out screens.
function cashout.amount(amount, issuedFor, note)
    amount = wholeNumber(amount)

    if amount <= 0 then
        return false, "INVALID CASH OUT AMOUNT"
    end

    if not credits.canAfford(amount) then
        return false, "NOT ENOUGH CREDITS"
    end

    local created, voucherOrProblem = vouchers.create(
        amount,
        issuedFor,
        note or "PARTIAL MACHINE CASH OUT"
    )

    if not created then
        return false, voucherOrProblem or "VOUCHER CREATION FAILED"
    end

    local voucher = voucherOrProblem
    local removed, removeProblem = credits.remove(
        amount,
        "CASH OUT " .. tostring(voucher.id)
    )

    if not removed then
        vouchers.cancel(
            voucher.id,
            "CREDIT REMOVAL FAILED",
            "CASHOUT ROLLBACK"
        )

        return false, removeProblem or "COULD NOT REMOVE CREDITS"
    end

    return true, voucher
end

return cashout
