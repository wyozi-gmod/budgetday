concommand.Add("spawnnpc", function(ply)
	for _,oldnpc in pairs(ents.FindByClass("bd_ai_base")) do
		oldnpc:Remove()
	end
	local hit = ply:GetEyeTrace().HitPos

	local npc = ents.Create("bd_ai_base")
	npc:SetPos(hit)
	npc:SetBrain {
		CheckForCameras = function(self, pos, dir, callback, checked_monitors)

			checked_monitors = checked_monitors or {}

			callback(pos, dir)

			local check_ents = ents.FindByClass("bd_camera_monitor")

			for _,ce in pairs(check_ents) do
				if table.HasValue(checked_monitors, ce) then continue end

				local pos_diff = (ce:GetPos() - pos)
				local pos_diff_normal = pos_diff:GetNormalized()
				local dot = dir:Dot(pos_diff_normal)
				local dist = pos_diff:Length()

				if dist < 512 and dot > 0.25 then
					table.insert(checked_monitors, ce)
					local acam = ce:GetActiveCamera()
					if IsValid(acam) then
						local cpos, cang = acam:GetCameraPosAng()
						self:CheckForCameras(cpos, cang:Forward(), callback, checked_monitors)
					end
				end

			end
		end,
		SpotEntities = function(self, pos, dir)
			local check_ents = {player.GetByID(1)}

			for _,ce in pairs(check_ents) do
				local targpos = ce.EyePos and ce:EyePos() or ce:GetPos()

				local pos_diff = (targpos - pos)
				local pos_diff_normal = pos_diff:GetNormalized()
				local dot = dir:Dot(pos_diff_normal)
				local dist = pos_diff:Length()

				if dist < 512 and dot > 0.6 and ce:IsLineOfSightClear(pos) then
					MsgN(ce, " getting spotted")
				end
			end
		end,
		SpotPosition = function(self, ent)
			self:CheckForCameras(ent:GetPos() + Vector(0,0,60), ent:GetAngles():Forward(), function(pos, dir)
				self:SpotEntities(pos, dir)
			end)
		end,
		Think = function(self, data, ent)
			local stat, err = pcall(function()
				self:SpotPosition(ent)

				if not data.NextRoam or data.NextRoam < CurTime() then
					ent.loco:SetAcceleration(100)
					ent.loco:SetDesiredSpeed(100)
					ent.loco:SetDeathDropHeight(40)
					ent:StartActivity(ACT_WALK)
					local p = table.Random(ents.FindByClass("bd_npc_poi")):GetPos()
					ent:MoveToPos(p, {
						draw = true,
						terminate_condition = function()
							self:SpotPosition(ent)
							return false
						end}
					)

					data.NextRoam = CurTime() + math.random(2, 15)
				end

				ent:PlaySequenceAndWait("LineIdle0" .. math.random(1, 2))
				--ent:StartActivity(ACT_IDLE)
			end)
			if not stat then MsgN(err) end
			return CurTime()
		end
	}
	npc:Activate()
	npc:Spawn()

	npc:AddFlashlight()
end)

hook.Add("Think", "SADdadas", function()
	for _,npc in pairs(ents.FindByClass("bd_ai_base")) do
		debugoverlay.Line(npc:GetPos(), npc:GetPos()+npc:GetAngles():Forward()*100, 0.1)
	end
end)