local SKILL = {}

function SKILL:RegisterVariables(ply)
end

function SKILL:UnRegisterVariables(ply)
end

skills.RegisterModule("aisah_cameramitm", SKILL)

if CLIENT then
	local MOD = {}

	function MOD:Has(ply)
	    return ply:HasSkill("aisah_cameramitm")
	end

	function MOD:Setup()
	end

	function MOD:HUDData(data)
		local ent = LocalPlayer():GetNWEntity("BD_CameraMITM")

	    data.title = string.format("Camera MITM: %s", IsValid(ent) and ent:GetCameraName() or "offline")

	    local t = {}

	    for _,monitor in pairs(ents.FindByClass("bd_camera_monitor")) do
	    	if monitor:GetActiveCamera() == ent then
	    		table.insert(t, "#" .. monitor:EntIndex())
	    	end
	    end
	    data.indicators = {
	        {title = "Camera is active in monitors: ", text = string.format("[%s]", table.concat(t, ", "))},
	    }
	end

	aisah.RegisterModule("cameramitm", MOD)
end