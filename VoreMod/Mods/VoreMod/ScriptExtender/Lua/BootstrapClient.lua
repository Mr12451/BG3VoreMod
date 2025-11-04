Ext.Require("Utils/Output.lua")

local function OnStatsLoaded()
    _P("Stats loaded")
    -- local spell = Ext.Stats.Get("Shout_Rage")
    -- spell.UseCosts = "ActionPoint:1"

    -- Ext.Stats.Get("Shout_Rage")
end

Ext.Events.StatsLoaded:Subscribe(OnStatsLoaded)
