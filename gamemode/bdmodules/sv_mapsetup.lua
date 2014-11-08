
local brain_generic = {
	CheckForCameras = function(self, pos, dir, spotter_ent, callback, checked_cameras)
		checked_cameras = checked_cameras or {}

		callback(pos, dir, spotter_ent)

		local check_ents = ents.FindByClass("bd_camera_monitor")

		for _,ce in pairs(check_ents) do
			if table.HasValue(checked_cameras, ce) then continue end

			local pos_diff = (ce:GetPos() - pos)
			local pos_diff_normal = pos_diff:GetNormalized()
			local dot = dir:Dot(pos_diff_normal)
			local dist = pos_diff:Length()

			if dist < 512 and dot > 0.25 then
				local acam = ce:GetActiveCamera()
				if IsValid(acam) and not table.HasValue(checked_cameras, acam) then
					table.insert(checked_cameras, acam)
					local cpos, cang = acam:GetCameraPosAng()
					self:CheckForCameras(cpos, cang:Forward(), acam, callback, checked_cameras)
				end
			end

		end
	end,
	SpotEntities = function(self, pos, dir, spot_callback, spotter_ent)
		local check_ents = {}
		table.Add(check_ents, player.GetAll())
		table.Add(check_ents, ents.FindByClass("prop_ragdoll"))

		debugoverlay.Line(pos, pos+dir*100, 0.1)

		for _,ce in pairs(check_ents) do
			local targpos = ce:GetPos()
			if ce:IsPlayer() then
				targpos = ce:EyePos()
			end

			local pos_diff = (targpos - pos)
			local pos_diff_normal = pos_diff:GetNormalized()
			local dot = dir:Dot(pos_diff_normal)
			local dist = pos_diff:Length()

			local is_los_clear = bd.ComputeLos(spotter_ent:GetClass() == "bd_camera" and spotter_ent:GetCameraPosAng() or spotter_ent, ce)

			if dist < 1024 and dot > 0.5 and is_los_clear then
				spot_callback({
					ent = ce,
					spotter_ent = spotter_ent,
					pos = pos,
					targpos = targpos,
					dot = dot,
					dist = dist
				})
			end
		end
	end,
	SpotPosition = function(self, ent, spot_callback)
		self:CheckForCameras(ent:GetPos() + Vector(0,0,60), ent:GetAngles():Forward(), ent, function(pos, dir, spotter_ent)
			self:SpotEntities(pos, dir, spot_callback, spotter_ent)
		end)
	end,
	Roam = function(self, data, ent, spot_callback)
		ent.loco:SetAcceleration(100)
		ent.loco:SetDesiredSpeed(100)
		ent.loco:SetDeathDropHeight(40)
		ent:StartActivity(ACT_WALK)
		local p = table.Random(ents.FindByClass("bd_npc_poi")):GetPos()
		ent:MoveToPos(p, {
			terminate_condition = function()
				self:SpotPosition(ent, spot_callback)
				return false
			end}
		)
	end,
	Think = function(self, data, ent)
		local stat, err = pcall(function()
			local spot_callback = function(data)
				data.guard = ent
				hook.Call("BDGuardSpotted", GAMEMODE, data)
			end

			self:SpotPosition(ent, spot_callback)

			if data.type == "roaming" and (not data.NextRoam or data.NextRoam < CurTime()) then
				self:Roam(data, ent, spot_callback)

				data.NextRoam = CurTime() + math.random(2, 15)
			end

			--data.IdleSequence = data.IdleSequence or ("LineIdle0" .. math.random(1, 2))
			--ent:SetSequence(data.IdleSequence)

			ent:StartActivity(ACT_IDLE)
		end)
		if not stat then MsgN(err) end
		return CurTime()
	end
}

for _,npc in pairs(ents.FindByClass("bd_ai_base")) do
	npc.Brain = brain_generic
end

local function SpawnMapNPCs()
	local spawner_ents = ents.FindByClass("bd_npc_spawn")

	for _,spawner in pairs(spawner_ents) do
		local t = spawner:GetGuardType()

		local npc = ents.Create("bd_ai_base")
		npc:SetPos(spawner:GetPos())
		npc:SetAngles(spawner:GetAngles())

		npc:SetBrain(brain_generic)
		npc.BrainData.type = t

		npc:Activate()
		npc:Spawn()

		npc:AddFlashlight()
	end
end

hook.Add("BDRoundStateChanged", "SpawnMapNPCs", function(old_state, state)
	if state == "active" then
		SpawnMapNPCs()
	end
end)