--- Functions to make fetching a list of nextbots easier
local MODULE = bd.module("util")

function MODULE.GetGuards()
    return ents.FindByClass("bd_nextbot*")
end
function MODULE.GetGuardsByType(type)
    return bd.util.FilterSeq(MODULE.GetGuards(), function(guard)
        return guard:GetNWString("NPCType") == type
    end)
end

function MODULE.GetGuardRagdolls()
    return ents.FindByClass("prop_ragdoll")    
end
