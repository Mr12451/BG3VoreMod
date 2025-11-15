Ext.Require("Data/Main.lua")
Ext.Require("Data/Enums.lua")

Ext.Require("Events/Ticks.lua")

Ext.Require("Utils/Output.lua")
Ext.Require("Utils/LuaUtils.lua")
Ext.Require("Utils/ExtUtils.lua")

Ext.Require("Config/Config.lua")

Ext.Require("Data/Vore.lua")
Ext.Require("Data/Persistent.lua")
Ext.Require("Utils/DataUtils.lua")

Ext.Require("Events/CharacterState.lua")
Ext.Require("Events/Spell.lua")
Ext.Require("Events/Effect.lua")

Ext.Require("Vore/Swallow.lua")
Ext.Require("Vore/Digestion.lua")
Ext.Require("Vore/WeightSize.lua")

--[[function makePredator(character)
    Osi.AddTag(character, "Predator")
end

function makeUnwillingPrey(character)
    Osi.AddTag(character, "Prey")
    Osi.AddTag(character, "Unwilling")
end

function makeWillingPrey(character)
    Osi.AddTag(character, "Prey")
    Osi.AddTag(character, "Willing")
end]]

local function OnSessionLoaded()
    _D(PersistentVars)
    VO_SetupData()
end

-- If you know where to get type hints for this, please let me know.
if Ext.Osiris == nil then
    Ext.Osiris = {}
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)

--[[function registerOsirisListeners()
    Ext.Osiris.RegisterListener("CharacterJoinedParty", 2, "after", function(char, partyMember)
        makePredator(char)
        _P(Ext.Entity.Get(char).Tags:Has("Predator"))
    end)
end

Ext.Events.SessionLoaded:Subscribe(function()
    local allChars = Ext.GetCharacters()
    --registerOsirisListeners()
end) ]]

