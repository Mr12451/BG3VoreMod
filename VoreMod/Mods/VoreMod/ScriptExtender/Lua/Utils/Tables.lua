---Returns a shallowcopy of a table.
---@param table table<any, any> table to be copied
---@return table<any, any>
function VO_Shallowcopy(table)
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
function VO_Deepcopy(table, copies)
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
                copy[VO_Deepcopy(orig_key, copies)] = VO_Deepcopy(orig_value, copies)
            end
            setmetatable(copy, VO_Deepcopy(getmetatable(table), copies))
        end
    else
        -- number, string, boolean, etc
        copy = table
    end
    return copy
end