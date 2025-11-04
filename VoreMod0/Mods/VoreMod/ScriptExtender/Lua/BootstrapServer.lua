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

_P("hello world server")

function OnSessionLoaded()
    --[[_P("Add Passive")
    Osi.AddPassive(GetHostCharacter(), "SP_CanOralVore")]]
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
