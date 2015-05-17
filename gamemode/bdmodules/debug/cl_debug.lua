local debug_hitboxes = CreateConVar("bd_debug_hitboxes", "0", FCVAR_CHEAT)
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
