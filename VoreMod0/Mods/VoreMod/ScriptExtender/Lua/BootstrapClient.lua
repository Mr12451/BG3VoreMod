_P("hello world client")

function OnStatsLoaded()
    -- local spell = Ext.Stats.Get("Shout_Rage")
    -- spell.UseCosts = "ActionPoint:1"

    -- Ext.Stats.Get("Shout_Rage")
end

Ext.Events.StatsLoaded:Subscribe(OnStatsLoaded)