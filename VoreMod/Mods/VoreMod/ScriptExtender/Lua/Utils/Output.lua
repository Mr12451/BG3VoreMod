local LOG_PREFIX = "Vore | "

local IsDeveloperMode = Ext.Debug.IsDeveloperMode()

---Printing info to the stdout. "Print". Overrides BG3SE's _P().
---@param s string
_P = function(s)
    Ext.Log.Print(LOG_PREFIX .. tostring(s))
end

---Printing error to the stderr. "Fail", since _E is already defined.
---@param s string
_F = function(s)
    Ext.Log.PrintError(LOG_PREFIX .. tostring(s))
end

---Printing debug info to the stdout. "Verbose", since _D is already defined.
---@param s string
_V = function(s)
    if not IsDeveloperMode then
        return
    end
    Ext.Log.Print(LOG_PREFIX .. "DEBUG | " .. tostring(s))
end
