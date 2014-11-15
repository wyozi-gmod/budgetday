
local debug_dist = CreateConVar("bd_debug_distractions", "0")
local debug_distclusters = CreateConVar("bd_debug_distractionclusters", "0")

hook.Add("BDNextbotDistraction", "BD_DebugDistractions", function(nextbot, data)
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

hook.Add("Think", "BD_DebugNextbotDistractionClusters", function(nextbot, data)
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