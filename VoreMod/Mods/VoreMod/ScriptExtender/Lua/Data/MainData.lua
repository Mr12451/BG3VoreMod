

---Data of every pred who has at least 1 prey inside them
---@type table<CHARACTER, PredEntry>
PredData = {}

---Data of every prey who is currently involved in vore
---@type table<CHARACTER, PreyEntry>
PreyData = {}

---Data of every character (only companions) with vore level progression
---@type table<CHARACTER, LevelEntry>
VoreLvlData = {}

---Data of every pred that persists between vore encounters - fat, satiation, etc.
---@type table<CHARACTER, PersistentEntry>
VorePerData = {}

--- @alias Organ "O"|"A"|"U"|"C"|"B"
---@type table<Organ, boolean>
Organs = {
    ["O"] = true,
    ["A"] = true,
    ["U"] = true,
    ["C"] = true,
    ["B"] = true
}

--- @enum Digestion
Digestion = {
    None = 0, -- used only when digestion value is not initialized
    Endo = 1,
    Lethal = 2,
    Dead = 3
}

---a template for a new entry in PredData
---@class PredEntry
---@field Prey table<CHARACTER, Organ> name of the prey is the organ they are in
---@field Items table<Organ, GUIDSTRING> ids of items that contain swallowed items in preds inventory, one item as an organ, can be empty
---@field Stuffed integer how much capacity current prey takes
---@field AcidLevel integer increases each turn during digestion up to 5, reduced when no digestion happens
---@field DigestionTimer integer how close this pred is to doing gradual digestion
PredEntry = {
    Prey = {},
    Items = {},
    Stuffed = 0,
    AcidLevel = 0,
    DigestionTimer = 0,
}

---a template for a new entry in VoreData
---@class PreyEntry
---@field Pred CHARACTER pred of this character.
---@field Digestion Digestion digestion type
---@field SwallowProcess integer this is 0 when the prey is fully swallowed
---@field DigestionProcess number 0 for living prey, increases for dead prey til 100
---@field Weight integer weight of this character, only for prey, 0 for preds. This is dynamically changed
---@field WeightReduction integer by how much preys weight was reduced by preds perks
---@field Size integer takes pred's capacity and visual belly size
---@field DisableDowned boolean if a tag that disables downed state was appled on swallow. Should be false for non-prey
---@field Unpreferred boolean if a tag that makes AI prefer attacking other targets was applied on swallow. Should be false for non-prey
---@field SwallowedStatus string what swallowed status is appled
---@field DigestionStatus string what digestion status is appled
---@field FakeId number if this is > 0, than this prey is not a real character. Used for temporary characters who disappear after death
PreyEntry = {
    Pred = "",
    Digestion = Digestion.None,
    SwallowProcess = 0,
    DigestionProcess = 0,
    Weight = 0,
    WeightReduction = 0,
    Size = 0,
    DisableDowned = false,
    Unpreferred = false,
    SwallowedStatus = "",
    DigestionStatus = "",
    FakeId = 0
}

---a template for a new entry in VoreLvlData
---@class LevelEntry
---@field Xp integer
---@field Level integer
---@field Pred integer
---@field Prey integer
---@field Observer integer
LevelEntry = {
    Xp = 0,
    Level = 0,
    Pred = 0,
    Prey = 0,
    Observer = 0
}

---a template for a new entry in VorePerData
---@class PersistentEntry
---@field Fat integer For weigth gain, only visually increases the size of belly
---@field Satiation integer stores satiation that decreases hunger stacks
---@field Scale integer rounded scale of a character. Used for calculating belly size when character's size is changed
PersistentEntry = {
    Fat = 0,
    Satiation = 0,
    Scale = 100
}
