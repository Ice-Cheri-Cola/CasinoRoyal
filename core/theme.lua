--================================================--
-- Casino Royal
-- Version: 0.2.0
-- File: core/theme.lua
-- Description: Theme manager
--================================================--

local available =
    require("assets.themes")


local theme = {}


theme.current =
    available.ATM10



function theme.load(name)

    if available[name] then

        theme.current =
            available[name]

        return true

    end


    return false

end



function theme.get()

    return theme.current

end



return theme
