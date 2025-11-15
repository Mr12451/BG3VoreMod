--- File for utils that work only with lua, without interacting with the game at all

---splits a string
---@param string string to split
---@param seperator string seperator
---@return string[] split string
function Vore.UtilsLua:SplitString(string, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t = {}
    for str in string.gmatch(string, "([^" .. seperator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

---Returns a shallowcopy of a table.
---@param table table<any, any> table to be copied
---@return table<any, any>
function Vore.UtilsLua:ShallowCopy(table)
    local orig_type = type(table)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(table) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = table
    end
    return copy
end

---Returns a deepcopy of a table.
---@param table table<any, any> table to be copied
---@param copies? table<any, any>
---@return table<any, any>
function Vore.UtilsLua:DeepCopy(table, copies)
    copies = copies or {}
    local origType = type(table)
    local copy
    if origType == 'table' then
        if copies[table] then
            copy = copies[table]
        else
            copy = {}
            copies[table] = copy
            for orig_key, orig_value in next, table, nil do
                copy[Vore.UtilsLua:DeepCopy(orig_key, copies)] = Vore.UtilsLua:DeepCopy(orig_value, copies)
            end
            setmetatable(copy, Vore.UtilsLua:DeepCopy(getmetatable(table), copies))
        end
    else
        -- number, string, boolean, etc
        copy = table
    end
    return copy
end

---returns length of a table when # does not work (table is not an array)
---@param table table table to query
---@return number length of table
function Vore.UtilsLua:TableLength(table)
    local l = 0
    for _, _ in pairs(table) do
        l = l + 1
    end
    return l
end