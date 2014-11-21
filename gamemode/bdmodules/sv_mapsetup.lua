local function SpawnMapNPCs()
	local spawner_ents = ents.FindByClass("bd_npc_spawn")

	for _,spawner in pairs(spawner_ents) do
		local t = spawner:GetGuardType()

		local cls = "bd_nextbot_guard"
		-- TODO set class based on type and call a hook

		local npc = ents.Create(cls)
		npc:SetPos(spawner:GetPos())
		npc:SetAngles(spawner:GetAngles())

		npc.NPCType = t
		npc:SetNWString("NPCType", t)

		npc:Activate()
		npc:Spawn()

		local citem = spawner:GetCarryItem()
		if citem == "flashlight" then
			npc:AddFlashlight()
		elseif citem == "coffee" then
			npc:AddCoffeeCup()
		end
	end
end

hook.Add("BDRoundStateChanged", "SpawnMapNPCs", function(old_state, state)
	if state == "active" then
		SpawnMapNPCs()
	end
end)
