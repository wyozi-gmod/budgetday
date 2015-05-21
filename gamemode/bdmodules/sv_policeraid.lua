local MODULE = bd.module("policeraid")

function MODULE.Start()
    if MODULE.PoliceInformed then return end

    MODULE.PoliceInformed = true

    -- TODO call the active map stage only. Not all of them
    local mapstages = ents.FindByClass("bd_mapstage")
    for _,ms in pairs(mapstages) do
        ms:TriggerOutput("PoliceInformed", ms)
    end

    for _,nb in pairs(bd.util.GetGuards()) do
        -- This needs to be true so that they don't call for help again
        -- TODO make it a method?
        nb.HasCalledForHelp = true

        nb:NotifyDistraction({level = 1, cause = "policeraid_start"})
    end

    timer.Create("BDRaidTimer", 1, 1, function()
        timer.Create("BDRaidTimer", 5, 3, function()
            local e = ents.Create("bd_nextbot_swat")
            e:SetPos(Vector(-24.689302, -923.557068, 129.031250))
            e:Spawn()
        end)
    end)
end

hook.Add("BDRoundStateChanged", "BD.ResetPoliceRaid", function(oldstate, newstate)
    MODULE.PoliceInformed = false
    timer.Destroy("BDRaidTimer")
end)
