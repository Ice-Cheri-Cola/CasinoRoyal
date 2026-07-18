--================================================--
-- Casino Royal
-- Version: 0.1.0
-- File: core/logger.lua
-- Description: Logging and debugging system
--================================================--

local logger = {}

logger.enabled = true

logger.file = "casino.log"


--------------------------------------------------
-- Internal write function
--------------------------------------------------

local function write(level, message)

    if not logger.enabled then
        return
    end


    local line =
        "[" ..
        level ..
        "] " ..
        textutils.formatTime(
            os.time(),
            true
        )
        ..
        " - " ..
        message


    print(line)


    local file = fs.open(
        logger.file,
        "a"
    )


    if file then
        file.writeLine(line)
        file.close()
    end

end



--------------------------------------------------
-- Public logging functions
--------------------------------------------------

function logger.info(message)

    write(
        "INFO",
        message
    )

end



function logger.warning(message)

    write(
        "WARN",
        message
    )

end



function logger.error(message)

    write(
        "ERROR",
        message
    )

end



function logger.clear()

    if fs.exists(logger.file) then
        fs.delete(logger.file)
    end

end



return logger
