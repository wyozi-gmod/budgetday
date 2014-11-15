
local function SetupObjectives()
	if bd.MapSettings then
		local stage_name = bd.MapSettings.FirstStageName
		local stage = ents.FindByName(stage_name)[1]
		if IsValid(stage) then
			SetGlobalEntity("Objective", ents.FindByName(stage:GetFirstObjectiveName())[1])
		end
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