function bd.DragBody(ply, body, bone)
	ply.BD_DragData = {body=body, bone=bone}
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
				if len > 40 or not ply:KeyDown(IN_DUCK) then
					ply.BD_DragData = nil
					return
				end
				vec:Normalize()
				local tvec = vec * len * 15
				local avec = tvec - phys:GetVelocity()
				avec = avec:GetNormal() * math.min(45, avec:Length())
				avec = avec / phys:GetMass() * 16
				phys:AddVelocity(avec)
			end
		end
	end
end)