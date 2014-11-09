hook.Add("BDGuardSpotted", "BDRaiseGuardSuspicion", function(data)
	local guard = data.guard
	local ent = data.ent

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

		guard:NotifyDistraction({level = incr, pos = ent:GetPos(), spotter = data.spotter_ent, cause = "Spotted " .. tostring(ent:GetClass())})
	end

end)

hook.Add("EntityEmitSound", "BDDetectSounds", function(data)
	local ent = data.Entity
	if IsValid(ent) and data.Pos then
		local suspicion = 0.01
		local cause = "Unknown sound"
		if data.Channel == 4 then -- Footsteps etc..
			suspicion = 0.02
			cause = "Footstep"
		elseif data.Channel == 1 then -- weapon
			suspicion = 0.1
			cause = "Weapon shot"
		end

		for _,npc in pairs(ents.FindByClass("bd_ai_base")) do
			local dist = npc:GetPos():Distance(data.Pos)
			local suspicionmul = math.Clamp(1 / (dist / 64), 0, 1)

			local level = suspicionmul * suspicion
			if level > 0.001 then
				npc:NotifyDistraction({level = suspicionmul*suspicion, pos = data.Pos, cause = cause})
			end
		end
	end
end)