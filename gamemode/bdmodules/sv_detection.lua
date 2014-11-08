hook.Add("BDGuardSpotted", "BDRaiseGuardSuspicion", function(data)
	local guard = data.guard
	local ent = data.ent

	guard.BrainData.Suspicion = guard.BrainData.Suspicion or 0

	local base_incr
	if ent:GetClass() == "prop_ragdoll" then
		base_incr = 0.15
	end
	if ent:IsPlayer() then
		base_incr = ent:KeyDown(IN_DUCK) and 0.04 or 0.1
	end

	if base_incr then
		local dist_mul = math.Clamp(1 / (data.dist / 128), 0, 1)
		local incr = base_incr * dist_mul

		guard.BrainData.Suspicion = guard.BrainData.Suspicion + incr
		MsgN(guard, " spotted ", ent, " using ", data.spotter_ent, " (susp: " , guard.BrainData.Suspicion, ")")

	end

end)