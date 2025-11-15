---updates the amount of "potatoes" in pred's inventory
---@param pred CHARACTER
local function VO_UpdatePlaceholders(pred)
end

---updates the overstuffing / capacity effects
---@param pred CHARACTER
local function VO_UpdateCapacity(pred)
end

---updates pred's belly size and size belly weight
---@param pred CHARACTER
local function VO_UpdateVisuals(pred)
end

local function VO_QueueUpdate(pred)
    
end

---updates pred's belly size and size belly weight
---This will do a recursive update of weight, size of the preys, and recalculate belly size of the top pred
---main function for updating Weight
---@param pred CHARACTER
function Vore.WeightSize:UpdatePred(pred)
    local predData = Vore.Pred:Get(pred)
    -- character is not a pred - no need to update them
    if predData == nil then
        VO_QueueUpdate(pred)
        return
    end

    -- used for calculating encumbrance of this character's pred (because weight reduction of prey shouldn't affect the top pred)
    -- aka if you have a passive that reduces the weight of your prey, and then you're swallowed, the top pred will still carry the full weight of your prey
    local newWeightReal = 0
    -- used for calculating encumbrance of this character
    local newWeightReduced = 0
    ---used for calculating visual organ sizes of this character
    ---@type table<Organs, integer>
    local newSizes = {
        [Organs.Oral] = 0,
        [Organs.Anal] = 0,
        [Organs.Unbirth] = 0,
        [Organs.Cock] = 0,
        [Organs.Breasts] = 0,
    }
    -- used for calculating capacity of this character's pred, and also for calculating this character's capacity limit and debuffs
    local newTotalSize = 0

    for k, v in pairs(predData.Prey) do
        local thisPreyData = Vore.Prey:GetOrMake(k)
        local digestionMulti = math.max(0, (100 - thisPreyData.DigestionProcess ) / 100)

        -- TODO: CALCULATE WEIGTH REDUCTION OF THIS PREY
        local weightReductionFlat = 0
        local weightReductionMulti = 1

        local sizeMulti = 1

        if thisPreyData.SwallowProcess > 0 then
            sizeMulti = sizeMulti / 2
        end

        newSizes[v] = newSizes[v] + thisPreyData.Size * digestionMulti * sizeMulti
        newTotalSize = newTotalSize + thisPreyData.Size * digestionMulti * sizeMulti

        newWeightReal = newWeightReal + thisPreyData.Weight * digestionMulti
        newWeightReduced = newWeightReduced + thisPreyData.Weight * digestionMulti * weightReductionMulti - weightReductionFlat

        if thisPreyData.Digestion > DType.Dead then
            local thisPredData = Vore.Pred:Get(k)
            if thisPredData ~= nil then
                newSizes[v] = newSizes[v] + thisPredData.TotalSize * sizeMulti
                newTotalSize = newTotalSize + thisPredData.TotalSize * sizeMulti

                newWeightReal = newWeightReal + thisPredData.BellyWeightReal
                newWeightReduced = newWeightReduced + thisPredData.BellyWeightReal * weightReductionMulti
            end
        end
    end

    -- remember to count items

    predData.OrganSize = newSizes
    predData.TotalSize = newTotalSize

    predData.BellyWeightReal = newWeightReal
    predData.BellyWeightSelf = math.max(0, newWeightReduced)

    local preyData = Vore.Prey:Get(pred)
    VO_QueueUpdate(pred)
    -- character is not a pred - no need to update them
    if preyData ~= nil then
        Vore.WeightSize:UpdatePred(preyData.Pred)
    else

    end
end
