local utils = require "shiplog.utils"
local colors = require "term".colors

local function rows(connection, statement)
    local cursor = assert(
        connection:execute(statement),
        "Could not execute statement `" .. statement .. "`"
    )

    return function ()
        return cursor:fetch()
    end, cursor
end

local function first_row(connection, statement)
    local cursor = assert(
        connection:execute(statement),
        "Could not execute statement `" .. statement .. "`"
    )

    return cursor:fetch(), cursor
end

local function coloredTag(tag)
    local a = ("a"):byte(1)
    local r = math.floor(((tag:lower():byte(2) - a) / 26) * 255)
    local g = math.floor(((tag:lower():byte(3) - a) / 26) * 255)
    local b = math.floor(((tag:lower():byte(4) - a) / 26) * 255)

    return "\27[38;2;" .. r .. ";" .. g .. ";" .. b .. "m" .. tag .. "\27[0m"
end

local function add(conn, entry)
    local location = entry.attributes.location

    local statement =
        "insert into entries (content"
            .. (location and location:len() > 0 and ", location" or "")
            .. ")"
        .. "values ("
            .. "'" .. conn:escape(entry.content) .. "'"
            .. (location and location:len() and (", '" .. conn:escape(location) .. "'")  or "")
        ..")"

    local ok, err = conn:execute(statement)

    if not ok then
        return ok, err
    end

    for _, tag in ipairs(entry.tags) do
        assert(tag:len() >= 3, "Tag must be at least 3 characters long")

        statement =
            "insert into entries_tags (entry_id, tag) values ("
                .. "last_insert_rowid(),"
                .. "'" .. conn:escape(tag) .. "'"
            .. ")"

        ok, err = conn:execute(statement)

        if not ok then
            return ok, err
        end
    end

    return true
end

local function modify(conn, id, entry)
    return true
end

local function delete(conn, id)
    id = conn:escape(id)

    local affected = conn:execute("delete from entries where rowid = '" .. id .. "';")
    affected = affected + conn:execute("delete from entries_tags where rowid = '" .. id .. "';")

    return affected and affected > 0,
        (not affected or affected == 0) and "Could not find entry with id `" .. id .. "`"
end

local function list(conn, filter, limit)
    for i, tag in ipairs(filter.tags) do
        filter.tags[i] = conn:escape(tag)
    end

    for i, tag in ipairs(filter.excludedTags) do
        filter.excludedTags[i] = conn:escape(tag)
    end

    for k, v in pairs(filter.attributes) do
        filter.attributes[k] = conn:escape(v)
    end

    local tags =
        #filter.tags > 0
            and "'" .. table.concat(filter.tags, "', '") .. "'"
            or nil

    local statement = "select distinct entries.rowid as id, created_at, updated_at, content, location "
        .. "from entries_tags, entries "
        .. "where entries_tags.entry_id = entries.rowid "
        .. (tags and " and tag in (" .. tags .. ")" or "")
        -- TODO: attr
        .. (limit and " limit " .. conn:escape(limit) or "")

    local result = {}
    local iterator, cursor = rows(conn, statement)
    for id, created_at, updated_at, content, location in iterator do
        local entry = {
            id = id,
            content = content,
            location = location,
            entryTags = {},
            created_at = created_at,
            updated_at = updated_at,
        }

        local excluded = false
        local iterator2, cursor2 =
            rows(conn, "select tag from entries_tags where entry_id = '" .. id .. "'")
        for tag in iterator2 do
            table.insert(entry.entryTags, tag)

            if filter.excludedTags and #filter.excludedTags > 0
                and utils.contains(filter.excludedTags, tag) then
                excluded = true
                break
            end
        end
        cursor2:close()

        if not excluded then
            table.insert(result, entry)
        end
    end
    cursor:close()

    -- Sort by desc date
    table.sort(result, function(r1, r2)
        return r1.created_at > r2.created_at
    end)

    return result
end

local function prettyList(conn, filter, limit)
    local results = list(conn, filter, limit)

    for _, entry in pairs(results) do
        local line = (entry.content:match("^([^\n]+)") or entry.content)
            :sub(1, 80 - entry.created_at:len())

        local tags = entry.entryTags
        for i, tag in ipairs(tags) do
            tags[i] = coloredTag("+" .. tag)
        end

        print(
            "\n"
            .. colors.dim(entry.updated_at or entry.created_at) .. " "
            .. line
            .. "\n"
            .. table.concat(tags, " ")
        )
    end
end

return {
    add = add,
    modify = modify,
    delete = delete,
    list = prettyList
}
