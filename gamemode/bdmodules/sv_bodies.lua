function bd.DragBody(ply, body, bone)
	ply.BD_DragData = {body=body, bone=bone}
	body:SetNWBool("BeingDragged", true)
end

-- Some code from Murder..
hook.Add("Think", "BDHandleBodyDrag", function()
	for _,ply in pairs(player.GetAll()) do
		local dd = ply.BD_DragData
		if dd and IsValid(dd.body) then
			local target = ply:GetAimVector() * 30 + ply:GetShootPos()
			local phys = dd.body:GetPhysicsObjectNum(dd.bone)

			if IsValid(phys) then
				local vec = target - phys:GetPos()
				local len = vec:Length()
				if len > 50 then
					ply.BD_DragData = nil
					dd.body:SetNWBool("BeingDragged", false)
					return
				end
				vec:Normalize()
				local tvec = vec * len * 20
				local avec = tvec - phys:GetVelocity()
				avec = avec:GetNormal() * math.min(45, avec:Length())
				avec = avec / phys:GetMass() * 24
				phys:AddVelocity(avec)
			end
		end
	end
end)

-- If these keys are down the body is dropped
local drop_keys = bit.bor(IN_ATTACK, IN_ATTACK2, IN_USE)
hook.Add("FinishMove", "BD.DropBody", function(ply, mv)
	local btns = mv:GetButtons()
	if (bit.band(btns, drop_keys) ~= 0) and ply.BD_DragData and IsValid(ply.BD_DragData.body) then
		ply.BD_DragData.body:SetNWBool("BeingDragged", false)
		ply.BD_DragData = nil
	end
end)
