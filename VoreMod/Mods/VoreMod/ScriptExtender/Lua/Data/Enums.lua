-- ApplyStatus applies statuses for a number of seconds instead of turns.
-- Multiply the duration by this.
SecondsPerTurn = 6

---for converting internal weight to be displayed
GramsPerKilo = 1000


HumanWeight = 75000

MaxAcidLevel = 4

--- @enum PreySelectMode
PreySelectMode = {All = 0, Array = 1, Random = 2}

--- @enum PreyState
PreyState = {
    Any = 0, -- any prey will be released
    Digested = 1, -- only fully digested and dead prey will be released (used for absorption for example)
    CanRelease = 2, -- fully digested, alive, full tour'ed
    BeingDigested = 3,
}

--- @enum RegurgitateTypes
RegurgitateTypes = {Default = 0, SwallowFail = 1, Absorb = 2, Transfer = 3, ForceRemovePrey = 4}

---@enum Organs
Organs = {Oral = "O", Anal = "A", Unbirth = "U", Cock = "C", Breasts = "B"}

--- this determines prey reaction. It is (usually) based on 'Safe' property of the stomach mode, however some passives can overwrite it
--- @enum DType
DType = {
    Dead = 0,
    Endo = 1,
    Lethal = 2,
}

--- @enum ModesEnum
ModesEnum = {
    LethalStomach = 0,
    SafeStomach = 1,
    LethalAnalReverse = 2,
    LethalAnalNormal = 3,
    SafeAnalReverse = 4,
    SafeAnalNormal = 5,
    LethalUnbirth = 6,
    SafeUnbirth = 7,
}

DigestionDead = "VO_DigestionDead"
DigestionSwallow = "VO_DigestionSwallow"

---if prey status has multiple stages (like acid levels, this determines what these stages depend on)
---@enum StatusProperty
StatusProperty = {None = 0, Acid = 1}

---@enum StatusEvent
StatusEvent = {Orgasm = 0, Burp = 1}

---@class PreyStatuses
---@field Source StatusProperty
---@field Status table<integer, string>

---@class FuncOnEvent
---@field Source StatusEvent
---@field Func fun(character:CHARACTER, organ:Organs)

--- @class OrganMode
--- @field Safe DType determines NPC reaction to this digestion type
--- @field MeltingOnDamage integer if > 0, then this amount of damage instances will add a melting stack
--- @field PreyStatuses PreyStatuses statuses that will be applied to prey based on a certain property
--- @field FuncOnEvent table<FuncOnEvent> | nil functions that will trigger on certain events, aka pred's orgasm or burp
--- @field PredTurnFunc fun(pred:CHARACTER, organ:Organs) | nil function that is be called on pred's turn. For example will increase acid levels and do full tour
--- @field PreyTurnFunc fun(prey:CHARACTER) | nil function that is be called on prey's turn
OrganMode = {
    Safe = DType.Lethal,
    MeltingOnDamage = 3,
    PreyStatuses = {
        Source = StatusProperty.Acid,
        Status = {
            [0] = "VO_LethalAcid_0",
            [2] = "VO_LethalAcid_1",
            [4] = "VO_LethalAcid_2",
            [6] = "VO_LethalAcid_3",
            [8] = "VO_LethalAcid_4",
            [10] = "VO_LethalAcid_5",
        },
    },
    PredTurnFunc = function(pred, organ) VO_UpdateAcid(pred, organ) end,
    PreyTurnFunc = nil,
}

---@type table<ModesEnum, OrganMode>
KnownModes = {
    [ModesEnum.LethalStomach] = {
        Safe = DType.Lethal,
        MeltingOnDamage = 3,
        PreyStatuses = {
            Source = StatusProperty.Acid,
            Status = {
                [0] = "VO_LethalAcid_0",
                [2] = "VO_LethalAcid_1",
                [4] = "VO_LethalAcid_2",
                [6] = "VO_LethalAcid_3",
                [8] = "VO_LethalAcid_4",
                [10] = "VO_LethalAcid_5",
            },
        },
        PredTurnFunc = function(pred, organ) VO_UpdateAcid(pred, organ) end,
        PreyTurnFunc = nil,
    },
    [ModesEnum.SafeStomach] = {
        Safe = DType.Endo,
        MeltingOnDamage = 0,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_Safe"}},
        PredTurnFunc = function(pred, organ) VO_ReduceAcid(pred, organ) end,
        PreyTurnFunc = nil,
    },
    [ModesEnum.LethalAnalReverse] = {
        Safe = DType.Lethal,
        MeltingOnDamage = 0,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_LethalMelting"}},
        PredTurnFunc = function(pred, organ) VO_FulltourReverse(pred, organ) end,
        PreyTurnFunc = function(pred, organ) VO_MeltingAnal(pred, organ) end,
    },
    [ModesEnum.LethalAnalNormal] = {
        Safe = DType.Lethal,
        MeltingOnDamage = 0,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_LethalMelting"}},
        PredTurnFunc = function(pred, organ) VO_FulltourNormal(pred, organ) end,
        PreyTurnFunc = function(pred, organ) VO_MeltingAnal(pred, organ) end,
    },
    [ModesEnum.SafeAnalReverse] = {
        Safe = DType.Endo,
        MeltingOnDamage = 0,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_Safe"}},
        PredTurnFunc = function(pred, organ) VO_FulltourReverse(pred, organ) end,
        PreyTurnFunc = nil,
    },
    [ModesEnum.SafeAnalNormal] = {
        Safe = DType.Endo,
        MeltingOnDamage = 0,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_Safe"}},
        PredTurnFunc = function(pred, organ) VO_FulltourNormal(pred, organ) end,
        PreyTurnFunc = nil,
    },
    [ModesEnum.LethalUnbirth] = {
        Safe = DType.Lethal,
        MeltingOnDamage = 1,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_LethalArousal"}},
        FuncOnEvent = {{Source = StatusEvent.Orgasm, Func = function(pred, organ) VO_OrgasmDigest(pred, organ) end}},
        PredTurnFunc = nil,
        PreyTurnFunc = nil,
    },
    [ModesEnum.SafeUnbirth] = {
        Safe = DType.Endo,
        MeltingOnDamage = 0,
        PreyStatuses = {Source = StatusProperty.None, Status = {[0] = "VO_Safe"}},
        PredTurnFunc = nil,
        PreyTurnFunc = nil,
    },
}

-- I'd move physical damage to a separate mechaning
