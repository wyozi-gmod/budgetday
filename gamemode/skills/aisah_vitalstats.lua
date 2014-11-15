local SKILL = {}

function SKILL:RegisterVariables(ply)
end

function SKILL:UnRegisterVariables(ply)
end

bd.skills.Register("aisah_vitalstats", SKILL)

if CLIENT then
	local MOD = {}

	local icon_heart = Material("icon16/heart.png")
	local icon_sports = Material("icon16/sport_soccer.png")

	function MOD:Has(ply)
	    return ply:HasSkill("aisah_vitalstats")
	end

	function MOD:Setup()
	end

	function MOD:HUDData(data)
	    data.title = "Vital Statistics"

	    data.components:icon(icon_heart)
	    data.components:slider(LocalPlayer():Health() / LocalPlayer():GetMaxHealth())

	    data.components:icon(icon_sports)
	    data.components:slider(LocalPlayer():GetNWFloat("stamina"))
	end

	bd.aisah.RegisterModule("vitalstats", MOD)
end