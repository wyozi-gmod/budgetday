concommand.Add("spawnnpc", function(ply)
	local hit = ply:GetEyeTrace().HitPos

	local npc = ents.Create("bd_ai_base")
	npc:SetPos(hit)
	npc:SetBrain {
		Think = function(data, ent)
			ent.loco:SetAcceleration(100)
			ent.loco:SetDesiredSpeed(100)
			ent.loco:SetDeathDropHeight(40)
			ent:StartActivity(ACT_WALK)
			local p = table.Random(ents.FindByClass("bd_npc_poi")):GetPos()
			ent:MoveToPos(p, {draw = true})

			ent:StartActivity(ACT_IDLE)
			return CurTime() + math.random(2, 15)
		end
	}
	npc:Activate()
	npc:Spawn()
end)