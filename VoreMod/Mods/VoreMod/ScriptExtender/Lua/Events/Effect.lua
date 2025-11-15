---Runs each time a status is applied.
---@param object CHARACTER Recipient of status.
---@param status string Internal name of status.
---@param causee GUIDSTRING Thing that caused status to be applied.
---@param storyActionID? integer
local function VO_OnStatusApplied(object, status, causee, storyActionID)

    if string.sub(status, 1, 3) ~= "VO_" then
        return
    end
    local statusArgs = Vore.UtilsLua:SplitString(status, '_')
    if statusArgs[2] == "Digesting" then
        Vore.Digestion:DigestingTick(object)
    elseif statusArgs[2] == "DoSwallow" then
        local pred = Vore.UtilsExt:CharFromGUID(causee)
        Vore.Swallow:Success(pred, object, statusArgs[3], true)
    elseif statusArgs[2] == "FailSwallow" then
        local pred = Vore.UtilsExt:CharFromGUID(causee)
        Vore.Swallow:Fail(pred, object)
    end
end

---Runs each time a status is removed.
---@param object CHARACTER Recipient of status.
---@param status string Internal name of status.
---@param causee? GUIDSTRING Thing that caused status to be applied.
---@param storyActionID? integer
local function VO_OnStatusRemoved(object, status, causee, storyActionID)
    -- _P("StatusRemoved")
    -- regurgitates prey it they are not fully swallowed
    if string.sub(status, 1, 3) ~= "VO_" then
        return
    end
    local statusArgs = Vore.UtilsLua:SplitString(status, '_')
    -- if the pred didn't swallow preys in time, they'll escape
    if statusArgs[2] == 'PartiallySwallowed' or statusArgs[2] == 'PartiallySwallowedGentle' then
        local preyData = Vore.Prey:Get(object)
        if preyData ~= nil and preyData.SwallowProcess > 0 then
            Vore.Swallow:Fail(preyData.Pred, object)
        end
    end
end

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", VO_OnStatusApplied)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", VO_OnStatusRemoved)
