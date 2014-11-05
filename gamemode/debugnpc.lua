concommand.Add("spawnnpc", function(ply)
	for _,oldnpc in pairs(ents.FindByClass("bd_ai_base")) do
		oldnpc:Remove()
	end
	local hit = ply:GetEyeTrace().HitPos

	local npc = ents.Create("bd_ai_base")
	npc:SetPos(hit)
	npc:SetBrain {
		Think = function(data, ent)
			local function CheckForCameras(pos, dir, callback, monitors)
				monitors = monitors or {}

				callback(pos, dir)

				local check_ents = ents.FindByClass("bd_camera_monitor")

				for _,ce in pairs(check_ents) do
					if table.HasValue(monitors, ce) then continue end

					local pos_diff = (ce:GetPos() - pos)
					local pos_diff_normal = pos_diff:GetNormalized()
					local dot = dir:Dot(pos_diff_normal)
					local dist = pos_diff:Length()

					if dist < 512 and dot > 0.25 then
						table.insert(monitors, ce)
						local acam = ce:GetActiveCamera()
						if IsValid(acam) then
							local cpos, cang = acam:GetCameraPosAng()
							CheckForCameras(cpos, cang:Forward(), callback, monitors)
						end
					end

				end
			end
			local function Check(pos, dir)
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
			end
			local stat, err = pcall(function()
				CheckForCameras(ent:GetPos() + Vector(0,0,60), ent:GetAngles():Forward(), function(pos, dir)
					MsgN("Checking cameras ", pos, " ", dir)
					Check(pos, dir)
				end)
			end)
			if not stat then MsgN(err) end

			if not data.NextRoam or data.NextRoam < CurTime() then
				ent.loco:SetAcceleration(100)
				ent.loco:SetDesiredSpeed(100)
				ent.loco:SetDeathDropHeight(40)
				ent:StartActivity(ACT_WALK)
				local p = table.Random(ents.FindByClass("bd_npc_poi")):GetPos()
				ent:MoveToPos(p, {
					draw = true,
					terminate_condition = function()
						Check()
						return false
					end})

				data.NextRoam = CurTime() + math.random(2, 15)
			end
			Check()

			ent:StartActivity(ACT_IDLE)
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