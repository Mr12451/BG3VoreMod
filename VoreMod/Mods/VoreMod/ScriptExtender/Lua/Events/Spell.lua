---Triggers on spell cast.
---@param caster CHARACTER
---@param spell string
---@param spellType string
---@param spellElement string Like fire, lightning, etc I think.
---@param storyActionID integer
function VO_OnSpellCast(caster, spell, spellType, spellElement, storyActionID)

    if string.sub(spell, 1, 3) ~= "VO_" then
        return
    end
    local spellParams = Vore.UtilsLua:SplitString(spell, "_")

    local spellName = spellParams[3]

    if spellName == 'Regurgitate' then
        local organ = spellParams[4]
        -- local prey = table.concat({table.unpack(spellParams, 5, #spellParams)}, "_")
        Vore.Swallow:Regurgitate(caster, PreySelectMode.All, {}, PreyState.CanRelease, RegurgitateTypes.Default, organ)
    elseif spellName == "SwallowDown" then
        local predData = Vore.Pred:Get(caster)
        if predData ~= nil then
            for k, v in pairs(predData.Prey) do
                if Vore.Prey:GetOrMake(k).SwallowProcess > 0 then
                    -- endo doesn't matter here, it will be the same as initial swallow
                    Osi.ApplyStatus(k, "VO_TrySwallow", 0, 1, caster)
                end
            end
        end
    end
end

Ext.Osiris.RegisterListener("CastedSpell", 5, "after", VO_OnSpellCast)
