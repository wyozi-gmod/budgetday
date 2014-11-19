hook.Add("BDGuardSpotted", "BDRaiseGuardSuspicion", function(data)
	local ent = data.ent
	local guard = data.original_spotter

	local base_incr
	local cause = "spotted_unknown"
	if ent:GetClass() == "prop_ragdoll" then
		base_incr = 0.15
		cause = "spotted_ragdoll"
	end
	if ent:IsPlayer() then
		base_incr = ent:KeyDown(IN_DUCK) and 0.04 or 0.1
		cause = "spotted_player"
	end

	if base_incr then
		local dist_mul = math.Clamp(1 / (data.distance / 128), 0, 1)
		local incr = base_incr * dist_mul

		guard:NotifyDistraction({level = incr, pos = ent:GetPos(), spotter_ent = data.spotter, cause = cause})
	end
end)
