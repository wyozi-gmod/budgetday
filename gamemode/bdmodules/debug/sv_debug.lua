local debug_dist = CreateConVar("bd_debug_distractions", "0")
local debug_falloff = CreateConVar("bd_debug_sound_falloff", "0")
local debug_falloff_filter = CreateConVar("bd_debug_sound_falloff_filter", "")
local debug_distclusters = CreateConVar("bd_debug_distclusters", "0")
local debug_losents = CreateConVar("bd_debug_losents", "0")

hook.Add("BDNextbotDistraction", "BD.DebugDistractions", function(nextbot, data)
	if not debug_dist:GetBool() then return end

	local duration = math.Clamp(data.level * 140, 0.5, 4)

	if IsValid(data.spotter_ent) and data.spotter_ent ~= nextbot then
		bd.debugdraw.Line(bd.util.GetEntPosition(nextbot), bd.util.GetEntPosition(data.spotter_ent), duration, Color(127, 255, 0))
		bd.debugdraw.Text((bd.util.GetEntPosition(nextbot) + bd.util.GetEntPosition(data.spotter_ent))/2, string.format("%s (+%.4f)", data.cause, data.level), duration)

		bd.debugdraw.Line(bd.util.GetEntPosition(data.spotter_ent), data.pos, duration, Color(255, 127, 0))
	else
		bd.debugdraw.Line(bd.util.GetEntPosition(nextbot), data.pos, duration)
		bd.debugdraw.Text((bd.util.GetEntPosition(nextbot) + data.pos)/2, string.format("%s (+%.4f) %s", data.cause, data.level, table.ToString(data.debug_data or {})), duration)
	end

	MsgN(nextbot, " distraction: ", math.Round(data.level, 3) , " to ", nextbot:GetSuspicionLevel(), " caused by ", data.cause)
end)

hook.Add("BDNextbotDistraction", "BD.DebugSoundFalloff", function(nextbot, data)
	if not debug_falloff:GetBool() then return end

	if not data.debug_data or not data.debug_data.falloff then return end

	local filter = debug_falloff_filter:GetString()
	if filter ~= "" and not data.cause:find(filter) then return end

	local falloff = data.debug_data.falloff
	local falloff_exp = data.debug_data.falloff_exp or 1

	-- This is how suspicionmul is calculated:
	--   1 / math.pow(dist/falloff, falloff_exp)
	--
	-- To get distance from suspicionmul, we can use the following equation
	--  (derived from suspicionmul calculation algebraically, nothing magical)
	--
	--  dist = falloff * math.pow(1/suspicionmul, 1/falloff_exp)
	--
	-- To give developer a nice view of how falloff works, we start from x = 1/2
	-- and multiply that by 1/2 for y amount of times, and draw the lines

	bd.debugdraw.SoundWave(data.pos, falloff, falloff_exp, 2)

	local old_point = bd.util.GetEntPosition(nextbot)
	local norm_diff = (data.pos - old_point):GetNormalized()
	for p=1, 4 do
		local suspmul = math.pow(0.5, p)
		local dist = falloff * math.pow(1/suspmul, 1/falloff_exp)


		debugoverlay.Sphere(data.pos, dist, 1, Color(255, 255, 255, 64*suspmul), true)
	end

	MsgN(data.cause, table.ToString(data.debug_data))
end)

hook.Add("Think", "BD.DebugNextbotDistractionClusters", function(nextbot, data)
	if not debug_distclusters:GetBool() then return end

	for _,nb in pairs(bd.util.GetGuards()) do
		local clusters = nb:ComputeDistractionClusters()

		for groupname,group in pairs(clusters) do
			if group.level > 0 then
				bd.debugdraw.Text(group.pos + Vector(0, 0, 20), string.format("%s (%f)", groupname, group.level), 0.1)
				bd.debugdraw.Point(group.pos, 0.1)
			end
		end
	end
end)

hook.Add("Think", "BD.DebugLOSEntities", function()
	if not debug_losents:GetBool() then return end

	for _,ent in pairs(bd.util.GetGuards()) do

		local spotted_ents = ent:ComputeLOSEntities({
			filter = function(ent) return ent:IsPlayer() or ent:GetClass() == "prop_ragdoll" or ent:GetClass():StartWith("bd_nextbot*") end
		})

		for _,sent in pairs(spotted_ents) do
			--MsgN(ent, " ", sent.spotter, " ", sent.ent, (sent.ent:GetClass() == "bd_camera_monitor" and sent.ent:GetActiveCamera():GetCameraName() or ""))
			if sent.spotter ~= ent then
				bd.debugdraw.Line(bd.util.GetEntPosition(ent), bd.util.GetEntPosition(sent.spotter), 0.2, Color(127, 255, 0))
				bd.debugdraw.Line(bd.util.GetEntPosition(sent.spotter), bd.util.GetEntPosition(sent.ent), 0.2, Color(127, 255, 0))
			else
				bd.debugdraw.Line(bd.util.GetEntPosition(ent), bd.util.GetEntPosition(sent.ent), 0.2, Color(127, 255, 0))
			end
		end
	end
end)
