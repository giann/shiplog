local colors = require "term.colors"
local utils = require "shiplog.utils"

local log = function(level, message, ...)
    level = level or "info"

    local color = colors.white

    if level == "warning" then
        color = colors.yellow
    elseif level == "failure" then
        color = colors.red
    elseif level == "debug" then
        color = colors.blue
    elseif level == "success" then
        color = colors.green
    end

    local variables = {...}

    message = (type(message) == "string"
        and color(message)
        or utils.dump(message))
            .. "\t"

    for _, variable in ipairs(variables) do
        message = message
            .. utils.dump(variable)
            .. "\t"
    end

    io.write(message .. colors.reset .. "\n")
end

return {
    info = function(message, ...)
        log("info", message, ...)
    end,
    warning = function(message, ...)
        log("warning", message, ...)
    end,
    failure = function(message, ...)
        log("failure", message, ...)
    end,
    success = function(message, ...)
        log("success", message, ...)
    end,
    debug = function(message, ...)
        log("debug", message, ...)
    end,
}
