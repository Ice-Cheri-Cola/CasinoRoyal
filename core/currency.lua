local currency = {
    item = "minecraft:diamond",
    singular = "Diamond",
    plural = "Diamonds",
    creditSingular = "Credit",
    creditPlural = "Credits",
    creditsPerItem = 1
}

local function wholeNumber(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

function currency.toCredits(itemCount)
    return wholeNumber(itemCount) * wholeNumber(currency.creditsPerItem)
end

function currency.toItems(creditCount)
    local rate = wholeNumber(currency.creditsPerItem)
    if rate <= 0 then return 0 end
    return math.floor(wholeNumber(creditCount) / rate)
end

function currency.formatItems(amount)
    amount = wholeNumber(amount)
    local label = amount == 1 and currency.singular or currency.plural
    return tostring(amount) .. " " .. label
end

function currency.formatCredits(amount)
    amount = wholeNumber(amount)
    local label = amount == 1 and currency.creditSingular or currency.creditPlural
    return tostring(amount) .. " " .. label
end

return currency
