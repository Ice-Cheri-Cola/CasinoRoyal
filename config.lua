--================================================--
-- Casino Royal
-- Version: 0.1.0
-- File: config.lua
--================================================--

local config = {}

config.casinoName = "Casino Royal"
config.version = "0.1.0"

config.theme = "ATM10"

config.currency = "minecraft:diamond"

config.defaultBet = 1
config.minBet = 1
config.maxBet = 64

config.reelSpeed = 0.08

config.hardware = {
    monitor = nil,
    speaker = nil,
    inventoryManager = nil,
    chest = nil
}

return config
