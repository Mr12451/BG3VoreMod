---updates digestion and cc statuses for the prey
---@param prey CHARACTER
function Vore.Digestion:UpdatePrey(prey)
    local preyData = Vore.Prey:Get(prey)
    -- ignore fake preys - they only exist as "weight"
    if preyData == nil or preyData.FakeId ~= 0 then
        return
    end
    local predData = Vore.Pred:Get(preyData.Pred)
    if predData == nil then
        return
    end
    local organ = predData.Prey[prey]
    if preyData.Digestion == DType.Dead then
        if preyData.DigestionStatus ~= DigestionDead then
            _P("Set prey to dead")
            preyData.DigestionStatus = DigestionDead
        end
        -- no need to touch swallowed status
    else
        -- pred's digestion mod for this organ
        local properDigestion = KnownModes[predData.OrganDigestion[organ]]

        preyData.Digestion = properDigestion.Safe
        -- determine digestion status

        -- determine cc (swallowed) status
        if preyData.SwallowProcess == 0 then
            if properDigestion.PreyStatuses.Source == StatusProperty.None then
                preyData.DigestionStatus = properDigestion.PreyStatuses.Status[0]
            elseif properDigestion.PreyStatuses.Source == StatusProperty.Acid then
                -- temporary acid level scaling
                -- will rework later to scale with prey count
                for k, v in pairs(properDigestion.PreyStatuses.Status) do
                    if predData.AcidLevel >= k then
                        preyData.DigestionStatus = v
                    end
                end
            end
            if properDigestion.Safe == DType.Endo then
                preyData.SwallowedStatus = "VO_SwallowedGentle"
            else
                preyData.SwallowedStatus = "VO_Swallowed"
            end
        else
            preyData.DigestionStatus = DigestionSwallow
            if properDigestion.Safe == DType.Endo then
                preyData.SwallowedStatus = "VO_PartiallySwallowedGentle"
            else
                preyData.SwallowedStatus = "VO_PartiallySwallowed"
            end
        end
    end
    -- apply the statuses if they are not already applied
    if not Vore.UtilsExt:HasStatusWithCause(prey, preyData.DigestionStatus, preyData.Pred) then
        Osi.ApplyStatus(prey, preyData.DigestionStatus, 1 * SecondsPerTurn, 1, preyData.Pred)
    end
    if not Vore.UtilsExt:HasStatusWithCause(prey, preyData.SwallowedStatus, preyData.Pred) then
        if preyData.SwallowProcess == 0 then
            Osi.ApplyStatus(prey, preyData.SwallowedStatus, 100 * SecondsPerTurn, 1, preyData.Pred)
        else
            Osi.ApplyStatus(prey, preyData.SwallowedStatus, (preyData.SwallowProcess + 1) * SecondsPerTurn, 1,
                            preyData.Pred)
        end
    end
    if not Vore.UtilsExt:HasStatusWithCause(prey, "VO_InOrgan_" .. organ, preyData.Pred) then
        Osi.ApplyStatus(prey, "VO_InOrgan_" .. organ, 1 * SecondsPerTurn, 1, preyData.Pred)
    end
end

---updates digestion and cc statuses for the preys and the pred
---@param pred CHARACTER
---@param organ? Organs
function Vore.Digestion:UpdatePred(pred, organ)
    local predData = Vore.Pred:Get(pred)
    if predData == nil then
        Osi.RemoveStatus(pred, "VO_Full")
        return
    end
    if Osi.HasActiveStatus(pred, "VO_Full") == 0 then
        Osi.ApplyStatus(pred, "VO_Full", 1 * SecondsPerTurn)
    end

    -- determine pred's digestion statuses for the organ (or all organs)
    for k, v in pairs(predData.OrganDigestion) do
        if organ == nil or k == organ then
            -- safe in this organ
            -- we check if pred has safe status for this organ (it's a separate status because it should persist outside of preddata)
            if Osi.HasActiveStatus(pred, "VO_SafeSwitch_" .. k) == 1 then
                if k == Organs.Oral then
                    predData.OrganDigestion[k] = ModesEnum.SafeStomach
                elseif k == Organs.Anal then
                    if Osi.HasActiveStatus(pred, "VO_FulltourReverseSwitch") == 1 then
                        predData.OrganDigestion[k] = ModesEnum.SafeAnalReverse
                    else
                        predData.OrganDigestion[k] = ModesEnum.SafeAnalNormal
                    end
                else
                    predData.OrganDigestion[k] = ModesEnum.SafeUnbirth
                end
            else
                -- digestion is happening in this organ 
                if k == Organs.Oral then
                    predData.OrganDigestion[k] = ModesEnum.LethalStomach
                elseif k == Organs.Anal then
                    if Osi.HasActiveStatus(pred, "VO_FulltourReverseSwitch") == 1 then
                        predData.OrganDigestion[k] = ModesEnum.LethalAnalReverse
                    else
                        predData.OrganDigestion[k] = ModesEnum.LethalAnalNormal
                    end
                else
                    predData.OrganDigestion[k] = ModesEnum.LethalUnbirth
                end
            end
        end
    end

    for k, v in pairs(predData.Prey) do
        if organ == nil or v == organ then
            Vore.Digestion:UpdatePrey(k)
        end
    end
end

---Moves prey between organs
---@param prey CHARACTER
---@param organ Organs
function Vore.Digestion:MoveToOrgan(prey, organ)
    local preyData = Vore.Prey:Get(prey)
    -- ignore fake preys - they only exist as "weight"
    if preyData == nil then
        return
    end
    local predData = Vore.Pred:Get(preyData.Pred)
    if predData == nil then
        return
    end
    local oldOrgan = predData.Prey[prey]
    if oldOrgan == nil then
        return
    end
    predData.Prey[prey] = organ
    Vore.WeightSize:UpdatePred(preyData.Pred)
    Vore.Digestion:UpdatePrey(prey)
end

---triggers every pred's turn
---@param pred CHARACTER
---@param mode PreySelectMode
---@param preys table<GUIDSTRING, boolean> ignored if mode ~= RegurgitateMod.Array
---@param amount number
function Vore.Digestion:DigestPreys(pred, mode, preys, amount)
    local predData = Vore.Pred:Get(pred)
    if not predData then
        return
    end
    local preyToDigest = Vore.UtilsData:PreySelector(predData.Prey, mode, preys, PreyState.BeingDigested)

    for prey, organ in pairs(preyToDigest) do
        local preyData = Vore.Prey:GetOrMake(prey)
        if preyData.DigestionProcess < 100 then
            -- prey weight is never 0
            local wkg = preyData.Weight / GramsPerKilo
            local hkg = HumanWeight / GramsPerKilo
            -- different formulas for high and low weight
            if wkg > 75 then
                preyData.DigestionProcess = math.min(100,
                                                     preyData.DigestionProcess + amount * hkg / ((wkg - hkg) ^ 0.8) +
                                                         hkg)
            else
                preyData.DigestionProcess = math.min(100, preyData.DigestionProcess + amount - 0.1 * (wkg - hkg))
            end
        end
    end

    -- add satiation gain

    Vore.WeightSize:UpdatePred(pred)
end

---triggers every pred's turn
---@param pred CHARACTER
function Vore.Digestion:DigestingTick(pred)
    local predData = Vore.Pred:Get(pred)
    local gradualCount = 0
    local lethalCount = 0
    if predData == nil then
        Osi.RemoveStatus(pred, "VO_Full")
        return
    end

    for loc, dt in pairs(predData.OrganDigestion) do
        if KnownModes[dt].PredTurnFunc ~= nil then
            KnownModes[dt].PredTurnFunc(pred, loc)
        end
    end

    -- iterate through prey
    for prey, locus in pairs(predData.Prey) do
        local preyData = Vore.Prey:GetOrMake(prey)
        if preyData.FakeId == 0 and preyData.Digestion ~= DType.Dead then
            Vore.UtilsExt:TeleportTo(prey, pred)
        end
        if preyData.Digestion == DType.Dead and preyData.DigestionProcess < 100 then
            gradualCount = gradualCount + 1
        end
    end

    -- if lethalCount > 0 then
    --     if VoreData[pred].AcidLevel < 5 then
    --         VoreData[pred].AcidLevel = VoreData[pred].AcidLevel + 1
    --         if VoreData[pred].AcidLevel % 2 == 0 then
    --             SP_UpdateAcidLevelDigestionStatus(pred)
    --         end
    --     end
    -- elseif VoreData[pred].AcidLevel > 0 then
    --     VoreData[pred].AcidLevel = VoreData[pred].AcidLevel - 1
    -- end

    -- if lethalRandomSwitch and SP_MCMGet("LethalRandomSwitch") then
    --     SP_SetLocusDigestion(pred, "All", true)
    -- end
    -- if Osi.HasActiveStatus(pred, "SP_LocusLethal_O") == 1 and VoreData[pred].Items ~= "" then
    --     SP_DigestItem(pred)
    -- end
    -- gradual digestion

    predData.DigestionTimer = predData.DigestionTimer + 1
    if predData.DigestionTimer >= CO_DigestEveryTurns then
        predData.DigestionTimer = 0
        if gradualCount > 0 then
            Vore.Digestion:DigestPreys(pred, PreySelectMode.All, {}, CO_DigestAmount)
        end
    end
    -- dynamic belly scaling
    -- if VoreData[pred].Pred == "" then
    --     local predScale = Ext.Entity.Get(pred).GameObjectVisual.Scale * 100
    --     if VoreData[pred].Scale ~= predScale then
    --         VoreData[pred].Scale = predScale
    --         SP_UpdateWeight(pred)
    --     end
    -- end
    -- SP_PlayGurgle(pred, lethalCount, gradualCount)
end

---@param pred CHARACTER
---@param organ Organs
function VO_UpdateAcid(pred, organ)
    local predData = Vore.Pred:Get(pred)
    if not predData then
        return
    end
    local doIncrease = false
    for prey, v in pairs(predData.Prey) do
        if organ == v or organ == nil then
            doIncrease = true
        end
    end
    -- temporary acid level limit
    -- will rework later to scale with prey count
    if doIncrease then
        if predData.AcidLevel < 11 then
            predData.AcidLevel = predData.AcidLevel + 1
            Vore.Digestion:UpdatePred(pred, organ)
        end
    else
        if predData.AcidLevel > 0 then
            predData.AcidLevel = predData.AcidLevel - 1
        end
    end
end

---@param pred CHARACTER
---@param organ Organs
function VO_ReduceAcid(pred, organ)
    local predData = Vore.Pred:Get(pred)
    if not predData then
        return
    end
    if predData.AcidLevel > 0 then
        predData.AcidLevel = predData.AcidLevel - 1
    end
end

---@param pred CHARACTER
---@param organ Organs
function VO_FulltourNormal(pred, organ)

end

---@param pred CHARACTER
---@param organ Organs
function VO_FulltourReverse(pred, organ)

end

---@param prey CHARACTER
function VO_MeltingAnal(prey)

end

---@param character CHARACTER
---@param organ Organs
function VO_OrgasmDigest(character, organ)

end
