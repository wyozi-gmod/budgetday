hook.Add("Think", "BD.DebugSight", function()
	--[[
	local ent = {}
	table.Add(ent, ents.FindByClass("bd_camera"))
	table.Add(ent, ents.FindByClass("bd_nextbot*"))

	for _,cam in pairs(ent) do
		local posang = cam.GetCameraPosAng and {cam:GetCameraPosAng()} or {cam:EyePosN(), cam:GetAngles()}
		local pos, ang = posang[1], posang[2]

		local reqval = detection_ranges[cam:GetClass()] or detection_ranges.default
		local dist, dot = reqval.dist, reqval.dot

		debugoverlay.Line(pos, pos+ang:Forward()*dist, 0.1, Color(0, 255, 0))

		-- Dot product into an angle
		local added_ang = math.acos(dot)

		local radius = math.tan(added_ang) * dist

		local points = 32
		local rad_per_point = math.pi*2 / points
		for i=0,points do
			debugoverlay.Line(pos, pos+ang:Forward()*dist +
									ang:Right()*math.cos(rad_per_point*i)*radius +
									ang:Up()*math.sin(rad_per_point*i)*radius, 0.1, Color(100, 255, 100))
		end
	end
	]]
end)
