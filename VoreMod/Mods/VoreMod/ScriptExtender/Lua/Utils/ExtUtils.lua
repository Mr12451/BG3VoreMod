--- File for utils that work with osiris or ext, but don't interact with the vore systems

---Returns a character's name given it's GUID
---@param guid GUIDSTRING
---@return CHARACTER
function Vore.UtilsExt:CharFromGUID(guid)
    local name = Ext.Entity.Get(guid).ServerCharacter.Template.Name
    return name .. "_" .. guid
end

---@param character CHARACTER the character to query
---@return number size of the character
function Vore.UtilsExt:SizeCategory(character)
    local charData = Ext.Entity.Get(character)
    return charData.ObjectSize.Size
end

---Fetches display name of a thing given its GUIDSTRING.
---@param target GUIDSTRING
---@return string
function Vore.UtilsExt:DisplayNameFromGUID(target)
    return Osi.ResolveTranslatedString(Osi.GetDisplayName(target))
end

---Returns a random integer in range
---@param amin integer
---@param amax integer
---@return integer
function Vore.UtilsExt:RandBetween(amin, amax)
    local range = amax - amin + 1
    return Osi.Random(range) + amin
end

---Checks if a character has a status caused by another character
---@param character CHARACTER
---@param status string
---@param cause CHARACTER
---@return boolean
function Vore.UtilsExt:HasStatusWithCause(character, status, cause)
    local causeGUID = string.sub(cause, -36)
    local charStatusData = Ext.Entity.Get(character).ServerCharacter.StatusManager.Statuses
    for _, i in ipairs(charStatusData) do
        if i.CauseGUID == causeGUID and i.StatusId == status then
            return true
        end
    end
    return false
end

---Teleports a prey to a pred. If prey is "ALL", teleports all prey to their respective preds.
---@param character CHARACTER
---@param destChar CHARACTER
function Vore.UtilsExt:TeleportTo(character, destChar)
    local destX, destY, destZ = Osi.GetPosition(destChar)
    Osi.TeleportToPosition(character, destX, destY, destZ, "", 0, 0, 0, 0, 1)
end

---Delays a function call for a given number of ticks.
---Server runs at a target of 30hz, so each tick is ~33ms and 30 ticks is ~1 second. This IS synced between server and client.
---@param ticks integer
---@param fn function
function Vore.UtilsExt:DelayCallTicks(ticks, fn)
    local ticksPassed = 0
    local eventID
    eventID = Ext.Events.Tick:Subscribe(function ()
        ticksPassed = ticksPassed + 1
        if ticksPassed >= ticks then
            fn()
            Ext.Events.Tick:Unsubscribe(eventID)
        end
    end)
end
