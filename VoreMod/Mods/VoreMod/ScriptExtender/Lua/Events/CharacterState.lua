---Runs when someone dies.
---@param character CHARACTER
local function VO_OnBeforeDeath(character)
    local predData = Vore.Pred:Get(character)
    local preyData = Vore.Prey:Get(character)
    _P("DIED " .. character)
    if predData ~= nil then
        Vore.Swallow:Regurgitate(character, PreySelectMode.All, {}, PreyState.Any, RegurgitateTypes.Default)
    end

    -- If character was prey (both can be true at the same time)
    if preyData ~= nil then
        _P("Was prey " .. character)
        local pred = preyData.Pred
        local predsData = Vore.Pred:Get(pred)
        if not predsData then
            _P("No pred data?")
            return
        end
        local organ = predsData.Prey[character]
        if not organ then
            organ = Organs.Oral
        end
        -- Temp characters' corpses are not saved is save file, so they might cause issues unless disposed of on death.
        if Ext.Entity.Get(character).ServerCharacter.Temporary == true then
            _P("Removing temp character")
            local fakePrey, entry = Vore.Prey:MakeFakeFrom(preyData.Weight, preyData.Size)
            -- Absorb transfers loot to pred and completely erases the prey
            Vore.Swallow:Regurgitate(pred, PreySelectMode.Array, {[character] = true}, PreyState.Any,
                                     RegurgitateTypes.Absorb)
            Vore.Swallow:Swallow(pred, {fakePrey}, false, organ)
        else
            _P("Switching digestion to dead")
            preyData.Digestion = DType.Dead
            if organ == Organs.Oral then
                -- this already calls Vore.Digestion:UpdatePrey
                Vore.Digestion:MoveToOrgan(character, Organs.Anal)
            else
                Vore.Digestion:UpdatePrey(character)
            end
            -- Digested but not released prey will be stored out of bounds.
            -- investigate if teleporting char out of bounds and reloading breaks them
            Osi.TeleportToPosition(character, -100000, 0, -100000, "", 0, 0, 0, 1, 0)
        end
    end
end

---@param newLevel string
local function VO_LevelLoaded(newLevel)
    _P("Add Passive")
    Osi.AddPassive(Osi.GetHostCharacter(), "VO_IsPred")
    Osi.AddPassive(Osi.GetHostCharacter(), "VO_CanOralVore")
    Osi.AddPassive(Osi.GetHostCharacter(), "VO_CanAnalVore")
    Osi.AddPassive(Osi.GetHostCharacter(), "VO_CanUnbirth")
end

Ext.Osiris.RegisterListener("Died", 1, "before", VO_OnBeforeDeath)
Ext.Osiris.RegisterListener("LevelLoaded", 1, "after", VO_LevelLoaded)