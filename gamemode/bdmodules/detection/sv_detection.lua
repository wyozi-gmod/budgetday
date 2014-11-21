hook.Add("BDGuardSpotted", "BDRaiseGuardSuspicion", function(data)
	local ent = data.ent
	local guard = data.original_spotter

	local base_incr

	local falloff, falloff_exp = 512, 3.5
	local final_mul = 1

	-- Guard spotted something through another mean (eg security camera)
	--  That means he should be way less suspicious of a bad quality camera stream than irl
	if data.original_spotter ~= data.spotter then
		falloff = 64
		falloff_exp = 1
		final_mul = 0.66
	end

	local cause = "spotted_unknown"
	if ent:GetClass() == "prop_ragdoll" then
		base_incr = 0.2
		cause = "spotted_ragdoll"
	end
	if ent:IsPlayer() then
		base_incr = ent:KeyDown(IN_DUCK) and 0.04 or 0.1
		cause = "spotted_player"
	end

	if base_incr then
		local suspicionmul = math.Clamp(1 / math.pow(data.distance/falloff, falloff_exp), 0, 1)
		local incr = base_incr * suspicionmul * final_mul

		guard:NotifyDistraction({level = incr, pos = ent:GetPos(), spotter_ent = data.spotter, cause = cause})
	end
end)

local time_per_decrtick = 0.2
hook.Add("Think", "BD.LowerGuardSuspicionOverTime", function()
	for _,guard in pairs(bd.util.GetGuards()) do
		local decr_suspicion_by = 0
		if guard.DistractionHistory then
			local elapsed = CurTime() - guard.DistractionHistory[#guard.DistractionHistory].happened
			if elapsed > 1 then
				decr_suspicion_by = 0.01 * (2^(elapsed*0.2)) * time_per_decrtick
			end
		end

		if guard:GetSuspicionLevel() > 0 and (not guard.NextLowerSusp or guard.NextLowerSusp <= CurTime()) then
			local old = guard:GetSuspicionLevel()

			guard:SetSuspicionLevel(math.max(0, guard:GetSuspicionLevel() - decr_suspicion_by))
			guard.NextLowerSusp = CurTime() + time_per_decrtick
		end
	end
end)
