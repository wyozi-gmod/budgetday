local SKILL = {}

function SKILL:RegisterVariables(ply)
end

function SKILL:UnRegisterVariables(ply)
end

bd.RegisterSkill("aisah_cameramitm", SKILL)

if CLIENT then
	hook.Add("PostDrawOpaqueRenderables", "BDDrawBuggedCameras", function()
		local ply = LocalPlayer()
		local ent = ply:GetNWEntity("BD_CameraMITM")
		if not ply:HasSkill("aisah_cameramitm") or not IsValid(ent) then return end

	    local is_recording = false

	    for _,monitor in pairs(ents.FindByClass("bd_camera_monitor")) do
	    	if monitor:GetActiveCamera() == ent then
	    		is_recording = true
	    	end
	    end

	    if is_recording then
	    	render.SetColorModulation(1, 0, 0)
	    else
	    	render.SetColorModulation(0, 1, 0)
	    end
	    cam.IgnoreZ(true)
	    render.SuppressEngineLighting(true)

	    ent:DrawModel()

	    render.SuppressEngineLighting(false)
	    cam.IgnoreZ(false)
	    render.SetColorModulation(1, 1, 1)

	    cam.Start2D()
	    local ts = (ent:LocalToWorld(ent:OBBCenter()) + Vector(0, 0, -10)):ToScreen()
	    draw.SimpleText(is_recording and "Recording" or "Not recording", "DermaDefaultBold", ts.x, ts.y, _, TEXT_ALIGN_CENTER)
	    cam.End2D()
	end)
end