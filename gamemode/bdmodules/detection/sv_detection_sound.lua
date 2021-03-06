local MODULE = bd.module("detection")

-- Contains sounds that contribute to detection status
-- Note: these are the only sounds that affect detection status
MODULE.SoundDetection = {
	{
		match = function(soundname)
			return soundname:find("footstep") or soundname:find("glass_sheet_step")
		end,

		suspicion = 0.15,
		falloff_exp = 2,
		cause = "heard_footstep"
	},
	{
		match = function(soundname) return soundname:match("physics/metal/metal_box_break%d%.wav") end,

		suspicion = 0.3,
		cause = "heard_vent_break",
		falloff = 128,
		pos = function(data) return data.Entity:GetPos() end
	},
	{
		match = function(soundname) return soundname:match("physics/glass/glass_largesheet_break%d%.wav") end,
		
		suspicion = 0.5,
		cause = "heard_glass_break",
		falloff = 256,
		pos = function(data) return data.Entity:GetPos() end
	},
	{
		match = function(soundname) return soundname:match("physics/body/body_medium_scrape_smooth_loop1%.wav") end,

		-- Body fall raises a lot of suspicion but falls off really quickly
		--  -> killing people close to other guards is no good
		suspicion = 0.5,
		falloff = 64,
		falloff_exp = 1.75,
		throttle = 0.35, -- single body can trigger suspicion raise only once per 0.5sec
		cause = "heard_body",
		pos = function(data) return data.Entity:GetPos() end
	}
}

-- Contains weapon sounds that contribute to detection status
-- Note: all weapon sounds affect detection; this table allows additional metadata
--       about eg. silencer status of specific gunshot
MODULE.WeaponSoundDetection = {
	["weapons/usp/usp1.wav"] = {silenced = true}
}

hook.Add("EntityEmitSound", "BDDetectSounds", function(data)
	local ent = data.Entity

	if IsValid(ent) then
		local suspicion = 0.01
		local cause
		local pos = data.Pos

		local falloff = 64 -- How quickly suspicion falls off over distance.
		local falloff_exp = 1
		local throttle = 0

		-- weapon
		if data.Channel == 1 and data.OriginalSoundName ~= "BaseCombatCharacter.StopWeaponSounds" then
			local wep_detection = MODULE.WeaponSoundDetection[data.SoundName]

			local is_silenced = wep_detection and wep_detection.silenced or false

			suspicion = is_silenced and 0.2 or 1
			cause = "heard_weapon_shot"
			if data.Entity:IsPlayer() then
				pos = data.Entity:GetShootPos()
			elseif data.Entity.EyePosN then
				pos = data.Entity:EyePosN()
			else
				pos = data.Entity:GetPos()
			end

			-- Nonsilenced weapons are audible from really far away
			if not is_silenced then falloff = 600 end
		else
			local sound_data = bd.util.Find(MODULE.SoundDetection, function(tbl)
				return tbl.match(data.SoundName)
			end)

			--MsgN(data.SoundName, " matched against ", sound_data and sound_data.cause or nil)

			if sound_data then
				suspicion = sound_data.suspicion
				cause = sound_data.cause

				if sound_data.pos then pos = sound_data.pos(data) end
				if sound_data.falloff then falloff = sound_data.falloff end
				if sound_data.falloff_exp then falloff_exp = sound_data.falloff_exp end
				if sound_data.throttle then throttle = sound_data.throttle end
			end
		end

		-- The last time this ent notified of distraction for this cause
		local lastDistractionRegistered = ent.SoundDetections and ent.SoundDetections[cause]

		if suspicion > 0 and pos and cause and (not lastDistractionRegistered or lastDistractionRegistered < (CurTime()-throttle)) then
			ent.SoundDetections = ent.SoundDetections or {}
			ent.SoundDetections[cause] = CurTime()

			for _,npc in pairs(ents.FindByClass("bd_nextbot*")) do
				local dist = npc:GetPos():Distance(pos)

				local suspicionmul = math.Clamp(1 / math.pow(dist/falloff, falloff_exp), 0, 1)

				local level = suspicionmul * suspicion
				if level > 0.001 then
					npc:NotifyDistraction({
						level = suspicionmul*suspicion,
						pos = pos,
						cause = cause,
						debug_data = {
							suspmul = suspicionmul,
							falloff = falloff,
							falloff_exp = falloff_exp
						}
					})
				end
			end
		end
	end
end)
