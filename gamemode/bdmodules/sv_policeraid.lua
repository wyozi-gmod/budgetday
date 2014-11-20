local MODULE = bd.module("policeraid")

function MODULE.Start()
    if MODULE.PoliceInformed then return end

    MODULE.PoliceInformed = true

    -- TODO call the active map stage only. Not all of them
    local mapstages = ents.FindByClass("bd_mapstage")
    for _,ms in pairs(mapstages) do
        ms:TriggerOutput("PoliceInformed", ms)
    end

    for _,nb in pairs(ents.FindByClass("bd_nextbot*")) do
        -- This needs to be true so that they don't call for help again
        -- TODO make it a method?
        nb.HasCalledForHelp = true

        nb:NotifyDistraction({level = 1, cause = "policeraid_start"})
    end

end

hook.Add("BDRoundStateChanged", "BD.ResetPoliceRaid", function(oldstate, newstate)
    MODULE.PoliceInformed = false
end)
