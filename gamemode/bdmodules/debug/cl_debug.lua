hook.Add("Think", "BD.DebugNextBotHitboxes", function()
	if true then return end

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
				debugoverlay.Text(bonepos, nb:GetBoneName(bone), 0.1)

				print( "Hit box group " .. group .. ", hitbox " .. hitbox .. " is attached to bone " .. nb:GetBoneName( bone ) )
			end
		end
	end
end)
