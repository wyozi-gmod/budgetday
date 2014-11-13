local function GetMonitorObjects(monitor, callback)
	local acam = monitor:GetActiveCamera()
	if not IsValid(acam) then return end

	local pos, ang = acam:GetCameraPosAng()
	local dir = ang:Forward()
	local spotter_ent = acam

	local check_ents = {}
	table.Add(check_ents, ents.FindByClass("bd_ai_base"))
	table.Add(check_ents, ents.FindByClass("prop_ragdoll"))

	callback(acam, Color(127, 255, 0))

	for _,ce in pairs(check_ents) do
		local targpos = bd.GetEntVector(ce)

		local pos_diff = (targpos - pos)
		local pos_diff_normal = pos_diff:GetNormalized()
		local dot = dir:Dot(pos_diff_normal)
		local dist = pos_diff:Length()

		local is_los_clear = bd.ComputeLos(pos, ce)

		local reqval = {dist=768, dot=0.65}

		--MsgN(ce, " dist: ", (dist < reqval.dist), " dot: ", (dot < reqval.dot), " los: ", is_los_clear)

		if dist < reqval.dist and dot > reqval.dot and is_los_clear then
			callback(ce, nil, acam)
		end
	end

end
hook.Add("PostDrawOpaqueRenderables", "BDDrawObjectsThroughBuggedCameras", function()
	local ply = LocalPlayer()

	local highlight_objs = {}
    for _,monitor in pairs(ents.FindByClass("bd_camera_monitor")) do
    	if monitor:GetNWBool("Bugged") then
    		GetMonitorObjects(monitor, function(e, clr, mon) table.insert(highlight_objs, {ent=e, clr=clr, mon=mon}) end)
    	end
    end

    if #highlight_objs == 0 then return end

    cam.IgnoreZ(true)
    render.SuppressEngineLighting(true)

    for _,obj in pairs(highlight_objs) do
    	if obj.clr then
    		render.SetColorModulation(obj.clr.r/255, obj.clr.g/255, obj.clr.b/255)
    	else
    		render.SetColorModulation(1, 0.5, 0)
    	end
    	obj.ent:DrawModel()

    	if IsValid(obj.mon) then
    		render.DrawLine(bd.GetEntVector(obj.mon), bd.GetEntVector(obj.ent), obj.clr or Color(255, 127, 0), false)
    	end
    end

    render.SuppressEngineLighting(false)
    cam.IgnoreZ(false)
    render.SetColorModulation(1, 1, 1)
end)