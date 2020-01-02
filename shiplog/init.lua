local dump = require "shiplog.utils".dump

local function rows(connection, statement)
    local cursor = assert(
        connection:execute(statement),
        "Could not execute statement `" .. statement .. "`"
    )

    return function ()
        return cursor:fetch()
    end
end

local function first_row(connection, statement)
    local cursor = assert(
        connection:execute(statement),
        "Could not execute statement `" .. statement .. "`"
    )

    return cursor:fetch()
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
    id = conn:escape(id)
end

local function delete(conn, id)
    id = conn:escape(id)

    local affected = conn:execute("delete from entries where rowid = '" .. id .. "';")
    affected = affected + conn:execute("delete from entries_tags where rowid = '" .. id .. "';")

    return affected and affected > 0,
        (not affected or affected == 0) and "Could not find entry with id `" .. id .. "`"
end

local function list(conn, filter)
end

return {
    add = add,
    modify = modify,
    delete = delete,
    list = list
}
