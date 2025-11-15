--- File for utils that work with vore datas
---Returns character weight + their inventory weight, without weight placeholders from vore
---@param character CHARACTER character to querey
---@return integer total weight
function Vore.UtilsData:Weight(character)
    local charData = Ext.Entity.Get(character)
    local weight = 0

    if charData.Data ~= nil and charData.Data.Weight ~= nil then
        weight = weight + charData.Data.Weight
        if charData.InventoryWeight ~= nil then
            weight = weight + charData.InventoryWeight.Weight
            ---If this character is a pred, weight placeholders will be subtracted from inventory weight
            local predData = Vore.Pred:Get(character)
            if predData ~= nil then
                weight = weight - predData.BellyWeightSelf // GramsPerKilo
            end
        end
    end
    -- to avoid division by 0 in certain places and other unexpected behaviour
    if weight <= 0 then
        weight = 1
    end
    return weight
end

---Returns base character weight and the weight of their prey. It is used as "size"
---@param character CHARACTER character to querey
---@return integer total weight
function Vore.UtilsData:Size(character)
    local charData = Ext.Entity.Get(character)
    local size = 0

    if charData.Data ~= nil and charData.Data.Weight ~= nil then
        size = size + charData.Data.Weight
    end
    return size
end

---returns all preys that fit certain criteria
---@param allPreys table<GUIDSTRING, Organs>
---@param mode PreySelectMode
---@param preys table<GUIDSTRING, boolean> ignored if mode ~= PreySelectMode.Array
---@param preyState PreyState Limits what preys will be regurgitated
---@param organ? Organs
---@return table<GUIDSTRING, Organs>
function Vore.UtilsData:PreySelector(allPreys, mode, preys, preyState, organ)
    local goodPreys = {}

    for prey, v in pairs(allPreys) do

        if (not organ or v == organ) and
            (mode ~= PreySelectMode.Array or mode == PreySelectMode.Array and preys[prey] ~= nil) then

            local preyData = Vore.Prey:GetOrMake(prey)

            -- check if we should regurigitate this character
            local beingDigested = preyData.Digestion == DType.Dead and preyData.DigestionProcess < 100
            local digested = preyData.Digestion == DType.Dead and preyData.DigestionProcess >= 100
            local fulltoured = preyData.Digestion ~= DType.Dead and
                                   (v ~= Organs.Anal or preyData.FullTourProcess >= 100)

            if (preyState == PreyState.Any or preyState == PreyState.BeingDigested and beingDigested or preyState ==
                PreyState.Digested and digested or preyState == PreyState.CanRelease and (fulltoured or digested)) then

                goodPreys[prey] = v
            end
        end
    end

    if mode ~= PreySelectMode.Random then
        return goodPreys
    else
        -- TODO: NEEDS TESTING
        -- NOT SURE IF RANDOM CAN ROLL 0
        local randPreyId = Osi.Random(Vore.UtilsLua:TableLength(goodPreys))
        for prey, v in pairs(goodPreys) do
            if randPreyId == 0 then
                return {[prey] = v}
            end
            randPreyId = randPreyId - 1
        end
        return {}
    end

end
