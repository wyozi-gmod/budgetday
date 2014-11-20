local SKILL = {}

function SKILL:RegisterVariables(ply)
end

function SKILL:UnRegisterVariables(ply)
end

bd.skills.Register("aisah_cameramitm", SKILL)

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
	    cam.IgnoreZ(false)
	    render.SuppressEngineLighting(true)

	    ent:DrawModel()

	    render.SuppressEngineLighting(false)
	    cam.IgnoreZ(false)
	    render.SetColorModulation(1, 1, 1)

		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		cam.Start3D2D((ent:LocalToWorld(ent:OBBCenter()) + Vector(0, 0, -10)), Angle(0, ang.y, 90), 0.3)
			draw.DrawText(is_recording and "Recording" or "Not recording", "DermaDefaultBold", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end)
end
