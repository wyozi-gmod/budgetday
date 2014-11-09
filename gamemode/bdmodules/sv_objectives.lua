
local function SetupObjectives()
	if bd.MapSettings then
		local objective_name = bd.MapSettings.FirstObjectiveName
		SetGlobalEntity("Objective", ents.FindByName(objective_name)[1])
	end

	if not IsValid(GetGlobalEntity("Objective")) then
		ErrorNoHalt("No valid first objective found!")
	end
	
end

hook.Add("BDRoundStateChanged", "SetupObjectives", function(old_state, state)
	if state == "pre" then
		SetupObjectives()
	end
end)