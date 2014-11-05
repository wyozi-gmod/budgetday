concommand.Add("spawnnpc", function(ply)
	local hit = ply:GetEyeTrace().HitPos

	local npc = ents.Create("bd_ai_base")
	npc:SetPos(hit)
	npc:SetBrain {
		Think = function(data, ent)
			local function Check()
				local ent_dir = ent:GetAngles():Forward()
				local check_ents = {player.GetByID(1)}

				for _,ce in pairs(check_ents) do
					local pos_diff = (ce:GetPos() - ent:GetPos())
					local pos_diff_normal = pos_diff:GetNormalized()
					local dot = ent_dir:Dot(pos_diff_normal)
					local dist = pos_diff:Length()

					if dist < 512 and dot > 0.2 and ce:Visible(ent) then
						MsgN(ce, " getting spotted")
					end
				end
			end

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