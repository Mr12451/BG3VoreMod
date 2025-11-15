---Should be called in any situation when prey must be swallowed.
---@param pred CHARACTER
---@param prey CHARACTER
local function VO_SwallowProcessLength(pred, prey)
    local predSize = Vore.UtilsExt:SizeCategory(pred)
    local preySize = Vore.UtilsExt:SizeCategory(prey)
    return math.max(preySize - predSize + 1, 0)
end

---Should be called in any situation when prey must be swallowed.
---@param pred CHARACTER
---@param allPreys table<GUIDSTRING>
---@param swallowStages boolean If swallow happens in multiple stages
---@param organ Organs
function Vore.Swallow:Swallow(pred, allPreys, swallowStages, organ)

    _P('Swallowing')

    local predData = Vore.Pred:GetOrMake(pred)

    for _, prey in ipairs(allPreys) do
        -- case 1: item
        if Osi.IsItem(prey) == 1 then
            -- do item swallow
        else
            local preyData = nil
            -- case 2: character
            if Osi.IsCharacter(prey) == 1 then
                preyData = Vore.Prey:GetOrMake(prey)
            else
                -- this can be a fake character
                -- fake character have prey data. If there is no prey data, prey is just an invalid string
                preyData = Vore.Prey:Get(prey)
            end
            if preyData ~= nil then
                local oldPred = preyData.Pred

                local oldPredData = Vore.Pred:Get(oldPred)

                preyData.Pred = pred
                predData.Prey[prey] = organ

                preyData.SwallowProcess = 0
                preyData.DigestionProcess = 0
                preyData.FullTourProcess = 0

                -- no old pred - prey data was just created, prey is not swallowed yet
                if oldPred == "" and preyData.FakeId == 0 then
                    preyData.Weight = Vore.UtilsData:Weight(prey)
                    preyData.Size = Vore.UtilsData:Size(prey)
                    -- full toured starts near the 'exit'
                    if organ == Organs.Anal then
                        preyData.FullTourProcess = 100
                    end

                    -- Osi.AddSpell(prey, 'VO_Zone_ReleaseMe', 0, 0)
                    -- Osi.AddSpell(prey, "VO_Zone_MoveToPred", 0, 0)
                    -- FULL TOUR SPELLS, WILL ADD LATER
                    -- if Osi.IsPlayer(prey) == 1 then
                    --     if Osi.IsTagged(prey, "f7265d55-e88e-429e-88df-93f8e41c821c") == 1 then
                    --         Osi.AddSpell(prey, "VO_Zone_PreySwallow_Endo_OAUC", 0, 0)
                    --         Osi.AddSpell(prey, "VO_Zone_PreySwallow_Lethal_OAUC", 0, 0)
                    --     end
                    -- end

                    Osi.SetVisible(prey, 0)
                    Osi.SetDetached(prey, 1)

                    -- Tag that disables downed state. Very important
                    if Osi.IsTagged(prey, '7095912e-fcb9-41dd-aec3-3cf7803e4b22') ~= 1 then
                        Osi.SetTag(prey, '7095912e-fcb9-41dd-aec3-3cf7803e4b22')
                        preyData.DisableDowned = true
                    end
                    -- Tag that makes AI less likely to target prey, for edge cases
                    if Osi.IsTagged(prey, '9787450d-f34d-43bd-be88-d2bac00bb8ee') ~= 1 then
                        Osi.SetTag(prey, '9787450d-f34d-43bd-be88-d2bac00bb8ee')
                        preyData.Unpreferred = true
                    end
                    if swallowStages then
                        preyData.SwallowProcess = VO_SwallowProcessLength(pred, prey)
                    end

                    -- multi stage swallow
                    if preyData.SwallowProcess > 0 then
                        -- moved this to another function
                        -- local pswallow = VO_GetPartialSwallowStatus(pred, prey)
                        -- VoreData[prey].SwallowedStatus = pswallow
                        -- Osi.ApplyStatus(prey, pswallow, (VoreData[prey].SwallowProcess + 1) * SecondsPerTurn, 1, pred)
                        Osi.ApplyStatus(pred, 'VO_CanSwallowDown', SecondsPerTurn)
                    else
                        preyData.SwallowProcess = 0
                    end
                    -- character is being transferred from another stomach
                elseif oldPredData ~= nil then

                    -- if the old pred doesn't have this prey in it's prey list, this means the old prey has already regurigitated this prey
                    -- for example this will happen when "swallow prey" is called from the regurigitate function (voreception)
                    -- in this case, old pred has already been processed by the regurigitate function
                    -- if it hasn't been processed by regurigitate function, we call the regurigitate function that will update the old pred
                    if oldPredData.Prey[prey] ~= nil then
                        Vore.Swallow:Regurgitate(oldPred, PreySelectMode.Array, {[prey] = true}, PreyState.Any,
                                                 RegurgitateTypes.Transfer)
                    end
                end
            end

        end

    end
    Vore.WeightSize:UpdatePred(pred)
    Vore.Digestion:UpdatePred(pred, organ)

    -- if VO_MCMGet("SweatyVore") == true then
    --     Osi.ApplyStatus(pred, "SWEATY", 5 * SecondsPerTurn)
    -- end
end

---releases a prey
---@param pred CHARACTER
---@param mode PreySelectMode
---@param preys table<GUIDSTRING, boolean> ignored if mode ~= RegurgitateMod.Array
---@param preyState PreyState Limits what preys will be regurgitated
---@param regType? RegurgitateTypes for certain specific types of regurgitation
---@param organ? Organs organ to regurgitate from
function Vore.Swallow:Regurgitate(pred, mode, preys, preyState, regType, organ)
    local predData = Vore.Pred:Get(pred)
    if predData == nil then
        return
    end

    local predAsPreyData = Vore.Prey:Get(pred)

    local regurgitatedLiving = 0
    ---@type table<CHARACTER, Organs>
    local markedForRelease = {}
    ---@type table<CHARACTER>
    local markedForSwallow = {}

    for prey, v in pairs(Vore.UtilsData:PreySelector(predData.Prey, mode, preys, preyState, organ)) do

        local preyData = Vore.Prey:GetOrMake(prey)
        predData.Prey[prey] = nil
        -- weight is now calculated differently
        -- SP_ReduceWeightRecursive(pred, VoreData[prey].Weight, true, false)

        if preyData.Digestion ~= DType.Dead then
            regurgitatedLiving = regurgitatedLiving + 1
        end
        -- Osi.RemoveStatus(prey, "VO_StilledPrey")
        -- Osi.RemoveStatus(prey, "VO_StunnedPrey")
        -- Osi.RemoveStatus(prey, "VO_StruggleExhaustion")
        -- Osi.RemoveStatus(prey, "VO_ReformationStatus")
        -- every other regType (absorption, forced prey removal on vore reset or level change) implies complete removal of prey from vore
        if predAsPreyData ~= nil and (regType == RegurgitateTypes.Default or regType == RegurgitateTypes.SwallowFail) then
            table.insert(markedForSwallow, prey)
            -- RegurgitateTypes.Transfer means that the prey is being swallowed by another pred. We don't remove the prey from vore or feed them to another pred,
            -- we just ignore this prey - the main purpose of regurigitation in this case is to remove prey from the current pred and clear the current pred
        elseif regType ~= RegurgitateTypes.Transfer then
            markedForRelease[prey] = v
        end
    end

    -- transfers prey to pred's pred for nested vore
    if #markedForSwallow > 0 and predAsPreyData ~= nil then
        -- determines what organ the current pred is in
        local predsPredData = Vore.Pred:Get(predAsPreyData.Pred)
        if predsPredData ~= nil then
            local predOrgan = predsPredData.Prey[pred]
            Vore.Swallow:Swallow(pred, markedForSwallow, false, predOrgan)
        end
    end

    -- offset to avoid placing prey into each other
    local rotationOffsetDisosal = 0
    local rotationOffsetDisosal1 = 30

    -- Remove regurgitated prey from the table and release them
    for prey, v in pairs(markedForRelease) do
        local preyData = Vore.Prey:GetOrMake(prey)
        -- release real prey - fake preys are just deleted
        if preyData.FakeId == 0 then
            -- during absorption we send preys to the void
            if type == RegurgitateTypes.Absorb then
                local predEntity = Ext.Entity.Get(pred)
                local predRoom = (predEntity.EncumbranceStats["HeavilyEncumberedWeight"] -
                                     predEntity.InventoryWeight.Weight - 100)
                local itemList = Ext.Entity.Get(prey).InventoryOwner.Inventories

                local rotationOffset = 0
                local rotationOffset1 = 360 // 30

                -- NEEDS REWORKING DURING ITEM VORE
                for _, t in pairs(itemList) do
                    local nextInventory = t:GetAllComponents().InventoryContainer.Items

                    for _, v2 in pairs(nextInventory) do
                        local uuid = v2.Item:GetAllComponents().Uuid.EntityUuid
                        local itemWeight = v2.Item.Data.Weight

                        if predRoom > itemWeight then
                            Osi.ToInventory(uuid, pred, 9999, 0, 0)
                            predRoom = predRoom - itemWeight
                        else
                            -- something is wrong, i can feel it...
                            local predX, predY, predZ = Osi.GetPosition(pred)
                            local predXRotation, predYRotation, predZRotation = Osi.GetRotation(pred)
                            predYRotation = (predYRotation + rotationOffset) * math.pi / 180
                            local newX = predX + 1 * math.cos(predYRotation)
                            local newZ = predZ + 1 * math.sin(predYRotation)
                            Osi.ItemMoveToPosition(uuid, newX, predY, newZ, 100000, 100000)
                            rotationOffset = rotationOffset + rotationOffset1
                        end
                    end
                end
                Osi.TeleportToPosition(prey, 100000, 0, 100000, "", 0, 0, 0, 1, 1)
            else
                -- something is wrong, i can feel it...
                local predX, predY, predZ = Osi.GetPosition(pred)
                local predXRotation, predYRotation, predZRotation = Osi.GetRotation(pred)
                predYRotation = (predYRotation + rotationOffsetDisosal) * math.pi / 180
                local newX = predX + 2 * math.cos(predYRotation)
                local newZ = predZ + 2 * math.sin(predYRotation)
                Osi.TeleportToPosition(prey, newX, predY, newZ, "", 0, 0, 0, 0, 1)
                rotationOffsetDisosal = rotationOffsetDisosal + rotationOffsetDisosal1
                Osi.ApplyStatus(prey, "PRONE", 1 * SecondsPerTurn, 1, pred)
                Osi.ApplyStatus(prey, "WET", 2 * SecondsPerTurn, 1, pred)
            end

            -- clear universal prey statuses
            Osi.RemoveStatus(prey, preyData.DigestionStatus, pred)
            Osi.RemoveStatus(prey, preyData.SwallowedStatus, pred)
            Osi.RemoveStatus(prey, "VO_InOrgan_" .. v, pred)

            -- clear prey spells
            -- Osi.RemoveSpell(prey, 'SP_Zone_ReleaseMe', 1)
            -- Osi.RemoveSpell(prey, 'SP_Zone_MoveToPred', 1)
            -- if Osi.IsPlayer(prey) == 1 then
            --     if Osi.IsTagged(prey, "f7265d55-e88e-429e-88df-93f8e41c821c") == 1 then
            --         Osi.RemoveSpell(prey, "SP_Zone_PreySwallow_Endo_OAUC", 1)
            --         Osi.RemoveSpell(prey, "SP_Zone_PreySwallow_Lethal_OAUC", 1)
            --     end
            -- end

            -- return prey to the world
            Osi.SetVisible(prey, 1)
            Osi.SetDetached(prey, 0)

            -- finish clearing prey data

            if preyData.DisableDowned then
                Osi.ClearTag(prey, '7095912e-fcb9-41dd-aec3-3cf7803e4b22')
            end
            if preyData.Unpreferred then
                Osi.ClearTag(prey, "9787450d-f34d-43bd-be88-d2bac00bb8ee")
            end
        end
        Vore.Prey:Delete(prey)
        if Vore.Pred:Get(prey) then
            Vore.WeightSize:UpdatePred(prey)
        end
    end

    -- TODO item vore
    local hasItems = false

    local removeSwallowDown = true
    local finalPreyCount = 0
    for py, v in pairs(predData.Prey) do
        local preyData = Vore.Prey:Get(py)
        if preyData ~= nil then
            finalPreyCount = finalPreyCount + 1
            if preyData.SwallowProcess > 0 then
                removeSwallowDown = false
            end
        end
    end

    -- If pred has no prey inside, remove swallow down enabler status
    if removeSwallowDown then
        Osi.RemoveStatus(pred, 'VO_CanSwallowDown')
    end

    -- if not SP_HasLivingPrey(pred, true) and not SP_MCMGet("IndigestionRest") then
    --     Osi.RemoveStatus(pred, "SP_Indigestion")
    -- end

    -- add swallow cooldown after regurgitation
    if (mode == PreySelectMode.All and regType ~= RegurgitateTypes.ForceRemovePrey or regType ==
        RegurgitateTypes.SwallowFail) and regurgitatedLiving > 0 then
        if CO_CooldownSwallow > 0 then
            Osi.ApplyStatus(pred, 'VO_CooldownSwallow', CO_CooldownSwallow * SecondsPerTurn, 1)
        end
        -- if SP_MCMGet("RegurgitationHunger") > 0 and SP_MCMGet("Hunger") and Osi.IsPartyMember(pred, 0) == 1 then
        --     Osi.ApplyStatus(pred, 'SP_Hunger', SP_MCMGet("RegurgitationHunger") * SecondsPerTurn * regurgitatedLiving, 1)
        -- end
    end

    if finalPreyCount == 0 and not hasItems then
        Vore.Pred:Delete(pred)
    end
    Vore.WeightSize:UpdatePred(pred)
    Vore.Digestion:UpdatePred(pred)
end

---checks if pred can swallow prey
---@param pred CHARACTER
---@param prey CHARACTER
---@return boolean
function Vore.Swallow:VorePossible(pred, prey)
    if Osi.HasActiveStatus(pred, "VO_CooldownSwallow") ~= 0 then
        return false
    end
    local preyData = Vore.Prey:Get(prey)
    -- a prey can't it their own pred
    if preyData ~= nil and preyData.Pred == prey then
        Osi.ApplyStatus(pred, "VO_AI_HELPER_BLOCKVORE", SecondsPerTurn * CO_CooldownMax, 1, prey)
        return false
    end

    return true
end

---perform swallowing of a prey. Used for for swallowing prey and continue swallowing
---@param pred CHARACTER
---@param prey CHARACTER|ITEM
---@param organ Organs
---@param swallowStages? boolean for initial swallow only
function Vore.Swallow:Success(pred, prey, organ, swallowStages)
    local predData = Vore.Pred:Get(pred)
    local preyData = Vore.Prey:GetOrMake(prey)
    -- for preys that are already inside of a pred
    if preyData.Pred == pred then
        if preyData.SwallowProcess > 0 and predData ~= nil then
            preyData.SwallowProcess = preyData.SwallowProcess - 1
            if preyData.SwallowProcess == 0 then
                _P('Fully swallowed ' .. prey)
                -- switches to proper digestion status
                Vore.Digestion:UpdatePrey(prey)
                -- updates pred's belly because during swallow process prey is considered half-sized
                Vore.WeightSize:UpdatePred(pred)
            end

            local removeSwallowDownSpell = true
            for k, v in pairs(predData.Prey) do
                if Vore.Prey:GetOrMake(k).SwallowProcess > 0 then
                    removeSwallowDownSpell = false
                end
            end
            if removeSwallowDownSpell then
                Osi.RemoveStatus(pred, 'VO_CanSwallowDown')
            end
        end
    elseif Vore.Swallow:VorePossible(pred, prey) then
        local cooldown = Vore.UtilsExt:RandBetween(CO_CooldownMin, CO_CooldownMax)
        Osi.ApplyStatus(pred, "VO_AI_HELPER_BLOCKVORE", SecondsPerTurn * cooldown, 1, pred)

        Vore.Swallow:Swallow(pred, {prey}, swallowStages, organ)
    end
end

---fail a swallow down check or a swallow check
---@param pred CHARACTER
---@param prey GUIDSTRING
function Vore.Swallow:Fail(pred, prey)
    local predData = Vore.Pred:Get(pred)
    local preyData = Vore.Prey:Get(prey)
    if predData ~= nil and preyData ~= nil and preyData.Pred == pred and preyData.Digestion > DType.Dead then

        -- ?????
        if preyData.SwallowProcess == 0 then
            return
            -- local pswallow = VO_GetPartialSwallowStatus(pred, prey)
            -- Osi.ApplyStatus(prey, pswallow, (maxSwallowProcess + 1) * SecondsPerTurn, 1, pred)
        end

        -- the swallow down enabler effect will be removed in VO_Regurgitate anyway
        Vore.Swallow:Regurgitate(pred, PreySelectMode.Array, {[prey] = true}, PreyState.Any)

    else
        if Osi.IsPlayer(pred) ~= 1 then
            local cooldown = Vore.UtilsExt:RandBetween(CO_CooldownMin, CO_CooldownMax)
            Osi.ApplyStatus(pred, "VO_AI_HELPER_BLOCKVORE", SecondsPerTurn * cooldown, 1, pred)
        end
    end
end
