---Data of every pred who has at least 1 prey inside them
---@type table<CHARACTER, PredEntry>
local _predData = {}

---Data of every prey who is currently involved in vore
---@type table<CHARACTER, PreyEntry>
local _preyData = {}

---Data of every character (only companions) with vore level progression
---@type table<CHARACTER, LevelEntry>
local _voreLvlData = {}

---Data of every pred that persists between vore encounters - fat, satiation, etc.
---@type table<CHARACTER, PersistentEntry>
local _vorePerData = {}

---a template for a new entry in PredData
---@class PredEntry
---@field Prey table<CHARACTER, Organs> name of the prey is the organ they are in
---@field Items table<Organs, GUIDSTRING> ids of items that contain swallowed items in preds inventory, one item as an organ, can be empty
---@field OrganDigestion table<Organs, ModesEnum> increases each turn during digestion up to 5, reduced when no digestion happens
---@field AcidLevel integer increases each turn during digestion up to 5, reduced when no digestion happens
---@field DigestionTimer integer how close this pred is to doing gradual digestion
---@field OrganSize table<Organs, integer> how much capacity current prey takes in each organ
---@field TotalSize integer how much capacity current prey takes
---@field BellyWeightSelf integer total prey weight in gramms, reduced by pred's and prey's passives
---@field BellyWeightReal integer total prey weight in gramms, without any reductions. Used when this pred is swallowed
local PredEntry = {
    Prey = {},
    Items = {
        [Organs.Oral] = "",
        [Organs.Anal] = "",
        [Organs.Unbirth] = "",
        [Organs.Cock] = "",
        [Organs.Breasts] = "",
    },
    OrganDigestion = {
        [Organs.Oral] = ModesEnum.LethalStomach,
        [Organs.Anal] = ModesEnum.LethalAnalReverse,
        [Organs.Unbirth] = ModesEnum.LethalUnbirth,
        [Organs.Cock] = ModesEnum.LethalUnbirth,
        [Organs.Breasts] = ModesEnum.LethalUnbirth,
    },
    AcidLevel = 0,
    DigestionTimer = 0,
    OrganSize = {
        [Organs.Oral] = 0,
        [Organs.Anal] = 0,
        [Organs.Unbirth] = 0,
        [Organs.Cock] = 0,
        [Organs.Breasts] = 0,
    },
    TotalSize = 0,
    BellyWeightSelf = 0,
    BellyWeightReal = 0,
}

---return or makes a prey data entry for a character
---@param character CHARACTER
---@return PredEntry|nil total weight
function Vore.Pred:Get(character)
    local pred = _predData[character]
    return pred
end

---deletes prey data entry
---@param character CHARACTER
function Vore.Pred:Delete(character)
    _predData[character] = nil
end

---return or makes a prey data entry for a character
---@param character CHARACTER
---@return PredEntry total weight
function Vore.Pred:GetOrMake(character)
    local pred = _predData[character]
    if pred == nil then
        pred = Vore.UtilsLua:DeepCopy(PredEntry)
        _predData[character] = pred
    end
    return pred
end

---a template for a new entry in PreyData
---@class PreyEntry
---@field Pred CHARACTER pred of this character.
---@field Digestion DType digestion type
---@field SwallowProcess integer this is 0 when the prey is fully swallowed
---@field DigestionProcess number 0 for living prey, increases for dead prey til 100
---@field FullTourProcess number 0 when near stomach, 100 when near exit. Used for anal vore in general, not just 'full tour'
---@field MeltingCounter integer 
---@field Weight integer weight of this character, only for prey, 0 for preds. Never changes
---@field Size integer takes pred's capacity and visual belly size. Never changes
---@field DisableDowned boolean if a tag that disables downed state was appled on swallow. Should be false for non-prey
---@field Unpreferred boolean if a tag that makes AI prefer attacking other targets was applied on swallow. Should be false for non-prey
---@field SwallowedStatus string what swallowed status is appled
---@field DigestionStatus string what digestion status is appled
---@field FakeId number if this is > 0, than this prey is not a real character. Used for temporary characters who disappear after death
local PreyEntry = {
    Pred = "",
    Digestion = DType.Endo,
    SwallowProcess = 0,
    DigestionProcess = 0,
    FullTourProcess = 0,
    MeltingCounter = 0,
    Weight = 0,
    Size = 0,
    DisableDowned = false,
    Unpreferred = false,
    SwallowedStatus = "",
    DigestionStatus = "",
    FakeId = 0,
}



---return prey data entry for a character
---@param character CHARACTER
---@return PreyEntry|nil
function Vore.Prey:Get(character)
    return _preyData[character]
end

---deletes prey data entry
---@param character CHARACTER
function Vore.Prey:Delete(character)
    _preyData[character] = nil
end

---return or makes a prey data entry for a character
---@param character CHARACTER
---@return PreyEntry
function Vore.Prey:GetOrMake(character)
    local prey = _preyData[character]
    if prey == nil then
        prey = Vore.UtilsLua:DeepCopy(PreyEntry)
        _preyData[character] = prey
    end
    return prey
end

---return or makes a prey data entry for a character
---@param weight integer
---@param size integer
---@return CHARACTER, PreyEntry
function Vore.Prey:MakeFakeFrom(weight, size)
    local fakeId = 0
    for prey, pD in pairs(_preyData) do
        if pD.FakeId >= fakeId then
            fakeId = pD.FakeId + 1
        end
    end
    ---@type PreyEntry
    local newFakePrey = Vore.UtilsLua:DeepCopy(PreyEntry)
    local fakeName = "Fake_" .. fakeId
    _preyData[fakeName] = newFakePrey
    newFakePrey.FakeId = fakeId
    newFakePrey.Weight = weight
    newFakePrey.Size = size

    newFakePrey.Digestion = DType.Dead
    newFakePrey.DigestionStatus = DigestionDead

    return fakeName, newFakePrey
end

---a template for a new entry in VoreLvlData
---@class LevelEntry
---@field Xp integer
---@field Level integer
---@field Pred integer
---@field Prey integer
---@field Observer integer
local LevelEntry = {
    Xp = 0,
    Level = 0,
    Pred = 0,
    Prey = 0,
    Observer = 0,
}

---a template for a new entry in VorePerData
---@class PersistentEntry
---@field Fat integer For weigth gain, only visually increases the size of belly
---@field Satiation integer stores satiation that decreases hunger stacks
---@field Scale integer rounded scale of a character. Used for calculating belly size when character's size is changed
local PersistentEntry = {
    Fat = 0,
    Satiation = 0,
    Scale = 100,
}

---checks if all entries of a vore data are correct and adds missing / removes extra fileds
---@param checkTable table table to check
---@param entryTable table entry example
---@param tableName string table name for logging
local function VO_CheckData(checkTable, entryTable, tableName)
    for k, v in pairs(checkTable) do
        for i, j in pairs(entryTable) do
            if v[i] == nil then
                _F('Character: ' .. k)
                _F(tableName .. ' missing value: ' .. i)
                if type(j) == "table" then
                    checkTable[k][i] = Vore.UtilsLua:DeepCopy(j)
                else
                    checkTable[k][i] = j
                end
            end
        end
        for i, _ in pairs(v) do
            if entryTable[i] == nil then
                _F('Character: ' .. k)
                _F(tableName .. ' unknown value: ' .. i)
                checkTable[k][i] = nil
            end
        end
    end
end

function VO_CheckVoreDatas()
    if PersistentVars['PredData'] == nil then
        PersistentVars['PredData'] = {}
    end
    ---@type table<CHARACTER, PredEntry>
    _predData = PersistentVars['PredData']
    VO_CheckData(_predData, PredEntry, "PredData")

    -- deletes preds without prey
    -- shouldn't normally happen, but who knows
    for k, v in pairs(_predData) do
        if next(v.Prey) == nil then
            _predData[k] = nil
        end
    end

    if PersistentVars['PreyData'] == nil then
        PersistentVars['PreyData'] = {}
    end
    ---@type table<CHARACTER, PreyEntry>
    _preyData = PersistentVars['PreyData']
    VO_CheckData(_preyData, PreyEntry, "PreyData")

    -- deletes preys without pred
    -- shouldn't normally happen, but who knows
    for k, v in pairs(_preyData) do
        if v.Pred == nil or v.Pred == "" then
            _preyData[k] = nil
        end
    end

    if PersistentVars['VoreLvlData'] == nil then
        PersistentVars['VoreLvlData'] = {}
    end
    _voreLvlData = PersistentVars['VoreLvlData']
    VO_CheckData(_voreLvlData, LevelEntry, "VoreLevelData")

    if PersistentVars['VorePerData'] == nil then
        PersistentVars['VorePerData'] = {}
    end
    _vorePerData = PersistentVars['VorePerData']
    VO_CheckData(_vorePerData, PersistentEntry, "VorePersistentData")
end
