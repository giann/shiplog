local colors = require "term".colors

local function fileToString(filename)
    local file, _ = io.open(filename, "r")

    if not file then
        return nil
    end

    local str = file:read("*all")

    file:close()

    return str
end

local dump
dump = function(t, inc, seen)
    if type(t) == "table" and (inc or 0) < 5 then
        inc = inc or 1
        seen = seen or {}

        seen[t] = true

        io.write(
            "{  "
            .. colors.dim .. colors.cyan .. "-- " .. tostring(t) .. colors.reset
            .. "\n"
        )

        local metatable = getmetatable(t)
        if metatable then
            io.write(
                ("     "):rep(inc)
                    .. colors.dim(colors.cyan "metatable = ")
            )
            if not seen[metatable] then
                dump(metatable, inc + 1, seen)
                io.write ",\n"
            else
                io.write(colors.yellow .. tostring(metatable) .. colors.reset .. ",\n")
            end
        end

        local count = 0
        for k, v in pairs(t) do
            count = count + 1

            if count > 10 then
                io.write(("     "):rep(inc) .. colors.dim(colors.cyan("...")) .. "\n")
                break
            end

            io.write(("     "):rep(inc))

            local typeK = type(k)
            local typeV = type(v)

            if typeK == "table" and not seen[v] then
                io.write "["

                dump(k, inc + 1, seen)

                io.write "] = "
            elseif typeK == "string" then
                io.write(colors.blue .. k:format("%q") .. colors.reset
                    .. " = ")
            else
                io.write("["
                    .. colors.yellow .. tostring(k) .. colors.reset
                    .. "] = ")
            end

            if typeV == "table" and not seen[v] then
                dump(v, inc + 1, seen)
                io.write ",\n"
            elseif typeV == "string" then
                io.write(colors.green .. "\"" .. v .. "\"" .. colors.reset .. ",\n")
            else
                io.write(colors.yellow .. tostring(v) .. colors.reset .. ",\n")
            end
        end

        io.write(("     "):rep(inc - 1).. "}")

        return
    elseif type(t) == "string" then
        io.write(colors.green .. "\"" .. t .. "\"" .. colors.reset)

        return
    end

    io.write(colors.yellow .. tostring(t) .. colors.reset)
end

local function contains(hay, needle)
    for _, v in pairs(hay) do
        if v == needle then
            return true
        end
    end

    return false
end

local splitCache = {}

local function split(self, delim, maxNb)
    local cache = splitCache[self] and splitCache[self][delim]
    if cache then
        return cache
    end

    if string.find(self, delim) == nil then
        return { self }
    end
    local result = {}
    if delim == '' or not delim then
        for i=1,#self do
            result[i]=self:sub(i,i)
        end
        return result
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0
    end
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(self, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end

    if nb ~= maxNb then
        result[nb + 1] = string.sub(self, lastPos)
    end

    splitCache[self] = splitCache[self] or {}
    splitCache[self][delim] = result

    return result
end

return {
    fileToString = fileToString,
    dump         = dump,
    contains     = contains,
    split        = split,
}
