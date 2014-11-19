
local debug_dist = CreateConVar("bd_debug_distractions", "0")
local debug_distclusters = CreateConVar("bd_debug_distractionclusters", "0")
local debug_sight = CreateConVar("bd_debug_sight", "0")
local debug_losents = CreateConVar("bd_debug_losentities", "0")

hook.Add("BDNextbotDistraction", "BD.DebugDistractions", function(nextbot, data)
	if not debug_dist:GetBool() then return end

	local duration = math.Clamp(data.level * 140, 0.5, 4)

	if IsValid(data.spotter_ent) and data.spotter_ent ~= nextbot then
		debugoverlay.Line(bd.util.GetEntPosition(nextbot), bd.util.GetEntPosition(data.spotter_ent), duration, Color(127, 255, 0))
		debugoverlay.Text((bd.util.GetEntPosition(nextbot) + bd.util.GetEntPosition(data.spotter_ent))/2, string.format("%s (+%.4f)", data.cause, data.level), duration)

		debugoverlay.Line(bd.util.GetEntPosition(data.spotter_ent), data.pos, duration, Color(255, 127, 0))
	else
		debugoverlay.Line(bd.util.GetEntPosition(nextbot), data.pos, duration)
		debugoverlay.Text((bd.util.GetEntPosition(nextbot) + data.pos)/2, string.format("%s (+%.4f)", data.cause, data.level), duration)
	end

	MsgN(nextbot, " distraction: ", math.Round(data.level, 3) , " to ", nextbot:GetSuspicionLevel(), " caused by ", data.cause)
end)

hook.Add("Think", "BD.DebugNextbotDistractionClusters", function(nextbot, data)
	if not debug_distclusters:GetBool() then return end

	for _,nb in pairs(ents.FindByClass("bd_nextbot*")) do
		local clusters = nb:ComputeDistractionClusters()

		for groupname,group in pairs(clusters) do
			if group.level > 0 then
				debugoverlay.Text(group.pos + Vector(0, 0, 20), string.format("%s (%f)", groupname, group.level))
				debugoverlay.Sphere(group.pos, 10, 0.1)
			end
		end
	end
end)

hook.Add("Think", "BD.DebugSight", function()
	if not debug_sight:GetBool() then return end

	for _,ent in pairs(ents.GetAll()) do
		if ent.Sight then
			local cone_apex = (ent.Sight.ent_pos) and ent.Sight.ent_pos(ent) or bd.util.GetEntPosition(ent)
			local cone_dir = (ent.Sight.ent_dir) and ent.Sight.ent_dir(ent) or ent:GetAngles():Forward()

			local cone_height = ent.Sight.distance
			local cone_angle = ent.Sight.angle

			debugoverlay.Line(cone_apex, cone_apex + cone_dir*cone_height, 0.2, Color(0, 255, 0))

			-- Let's compute right and up vectors from the forward vector using cross products
			local right_vec = cone_dir:Cross(Vector(0, 0, 1))
			local up_vec = -cone_dir:Cross(right_vec)

			local radius = math.tan(math.rad(cone_angle)) * cone_height

			local points = 32
			local rad_per_point = math.pi*2 / points
			for i=0,points do
				debugoverlay.Line(cone_apex, cone_apex + cone_dir * cone_height
										+ right_vec * math.cos(rad_per_point * i) * radius
										+ up_vec * math.sin(rad_per_point * i) * radius
					,0.1, Color(100, 255, 100))
			end
		end
	end
end)

hook.Add("Think", "BD.DebugLOSEntities", function()
	if not debug_losents:GetBool() then return end

	for _,ent in pairs(ents.FindByClass("bd_nextbot*")) do

		local spotted_ents = ent:ComputeLOSEntities({
			filter = function(ent) return ent:IsPlayer() or ent:GetClass() == "prop_ragdoll" or ent:GetClass():StartWith("bd_nextbot*") end
		})

		for _,sent in pairs(spotted_ents) do
			--MsgN(ent, " ", sent.spotter, " ", sent.ent, (sent.ent:GetClass() == "bd_camera_monitor" and sent.ent:GetActiveCamera():GetCameraName() or ""))
			if sent.spotter ~= ent then
				debugoverlay.Line(bd.util.GetEntPosition(ent), bd.util.GetEntPosition(sent.spotter), 0.2, Color(127, 255, 0))
				debugoverlay.Line(bd.util.GetEntPosition(sent.spotter), bd.util.GetEntPosition(sent.ent), 0.2, Color(127, 255, 0))
			else
				debugoverlay.Line(bd.util.GetEntPosition(ent), bd.util.GetEntPosition(sent.ent), 0.2, Color(127, 255, 0))
			end
		end
	end
end)
