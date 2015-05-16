local debug_hitboxes = CreateConVar("bd_debug_hitboxes", "0", FCVAR_CHEAT)
local debug_sight = CreateConVar("bd_debug_sight", "0", FCVAR_CHEAT)
local debug_cams = CreateConVar("bd_debug_cams", "0", FCVAR_CHEAT)

hook.Add("Think", "BD.DebugNextBotHitboxes", function()
	if not debug_hitboxes:GetBool() then return end

	for _,nb in pairs(ents.FindByClass("bd_nextbot_guard")) do
		local numHitBoxGroups = nb:GetHitBoxGroupCount()

		for group=0, numHitBoxGroups - 1 do
			local numHitBoxes = nb:GetHitBoxCount( group )

			for hitbox=0, numHitBoxes - 1 do
				local bone = nb:GetHitBoxBone( hitbox, group )

				local bonepos, boneang = nb:GetBonePosition(bone)
				local bound_min, bound_max = nb:GetHitBoxBounds(group, hitbox)
				if bound_min then
					debugoverlay.BoxAngles(bonepos, bound_min, bound_max, boneang, 0.1, Color(0, 255, 0, 1), false)
				end
				bd.debugdraw.Text(bonepos, string.format("%d: %s", hitbox, nb:GetBoneName(bone)), 0.1)

				print( "Hit box group " .. group .. ", hitbox " .. hitbox .. " is attached to bone " .. nb:GetBoneName( bone ) )
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

			bd.debugdraw.Line(cone_apex, cone_apex + cone_dir*cone_height, 0.2, Color(0, 255, 0))

			-- Let's compute right and up vectors from the forward vector using cross products
			local right_vec = cone_dir:Cross(Vector(0, 0, 1))
			local up_vec = -cone_dir:Cross(right_vec)

			local radius = math.tan(math.rad(cone_angle)) * cone_height

			local points = 32
			local rad_per_point = math.pi*2 / points
			for i=0,points do
				local point1 = cone_apex
				local point2 = cone_apex + cone_dir * cone_height
									+ right_vec * math.cos(rad_per_point * i) * radius
									+ up_vec * math.sin(rad_per_point * i) * radius

				bd.debugdraw.Line(point1, point2, 0.1, Color(255, 127, 0))
			end
		end
	end
end)

hook.Add("Think", "BD.DebugCameras", function()
	if not debug_cams:GetBool() then return end

	for _,ent in pairs(ents.FindByClass("bd_camera_monitor")) do

		local acam = ent:GetActiveCamera()
		if IsValid(acam) then
			local clr = HSVToColor(ent:EntIndex() * 10, 0.5, 1)
			bd.debugdraw.Line(ent:GetPos(), acam:GetPos(), 0.1, clr, true)
		end
	end
end)
