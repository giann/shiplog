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

    return cursor, cursor:fetch()
end

-- TODO: choose from palette instead of using actual values
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
            "replace into entries_tags (entry_id, tag) values ("
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
    -- Check for entry existence
    local exist = false
    local it, cur =
        rows(conn, "select count(*) from entries where rowid = '" .. conn:escape(id) .. "'")
    for count in it do
        if count > 0 then
            exist = true
            break
        end
    end
    cur:close()

    if not exist then
        return false, "Could not find entry with id `" .. id .. "`"
    end

    -- TODO: attributes
    if entry.content and entry.content:len() > 0 then
        if conn:execute(
            "update entries set content = '" .. conn:escape(entry.content) .. "' "
            .. "where entries.rowid = '" .. conn:escape(id) .. "'"
        ) == 0 then
            return false, "Could not modify entry with id `" .. id .. "`"
        end
    end

    for _, tag in ipairs(entry.tags) do
        assert(tag:len() >= 3, "Tag must be at least 3 characters long")

        local statement =
            "replace into entries_tags (entry_id, tag) values ("
                .. conn:escape(id) .. ","
                .. "'" .. conn:escape(tag) .. "'"
            .. ")"

        local ok, err = conn:execute(statement)

        if not ok then
            return ok, err
        end
    end

    for _, tag in ipairs(entry.excludedTags) do
        if conn:execute(
            "delete from entries_tags where entry_id = '" .. conn:escape(id) .. "' "
            .. " and entry.tag = '" .. tag .. "'"
        ) == 0 then
            return false, "Could not modify entry with id `" .. id .. "`"
        end
    end

    return true
end

local function delete(conn, id)
    id = conn:escape(id)

    local affected = conn:execute("delete from entries where rowid = '" .. id .. "';")
    affected = affected + conn:execute("delete from entries_tags where rowid = '" .. id .. "';")

    return affected and affected > 0,
        (not affected or affected == 0) and "Could not modify entry with id `" .. id .. "`"
end

local function list(conn, filter, limit)
    filter = filter or {} -- Filter can be empty
    limit = limit or 10

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
        .. (tags and "where entries_tags.entry_id = entries.rowid "
            .. " and tag in (" .. tags .. ") " or "")
        -- TODO: attr
        .. "limit " .. conn:escape(limit)

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
            :sub(1, 80)

        local tags = entry.entryTags
        for i, tag in ipairs(tags) do
            tags[i] = coloredTag("+" .. tag)
        end

        print(
            "\n"
            .. colors.cyan("#" .. entry.id .. " ")
            .. colors.green(line)
            .. "\n"
            .. colors.dim(entry.updated_at or entry.created_at) .. " "
            .. table.concat(tags, " ")
        )
    end
end

local function view(conn, id)
    local cursor, createdAt, updatedAt, content, _ = first_row(
        conn,
        "select created_at, updated_at, content, location "
        .. "from entries "
        .. "where rowid = '" .. conn:escape(id) .. "'"
    )
    cursor:close()

    local line = (content:match("^([^\n]+)") or content)
        :sub(1, 80)

    local tags = {}

    local it, cur =
        rows(conn, "select tag from entries_tags where entry_id = '" .. id .. "'")
    for tag in it do
        table.insert(tags, coloredTag("+" .. tag))
    end
    cur:close()

    print(
        "\n"
        .. colors.cyan("#" .. id .. " ")
        .. colors.green(line)
        .. "\n"
        .. colors.dim(updatedAt or createdAt) .. " "
        .. table.concat(tags, " ")
    )

    print("\n" .. utils.trim(content:sub(line:len() + 1)))
end

return {
    add    = add,
    modify = modify,
    delete = delete,
    list   = prettyList,
    view   = view
}
