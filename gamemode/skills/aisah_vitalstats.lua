local SKILL = {}

function SKILL:RegisterVariables(ply)
end

function SKILL:UnRegisterVariables(ply)
end

skills.RegisterModule("aisah_vitalstats", SKILL)

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
	    data.indicators = {
	        {icon = icon_heart, slider_frac = LocalPlayer():Health() / LocalPlayer():GetMaxHealth()},
	        {icon = icon_sports, slider_frac = LocalPlayer():GetNWFloat("stamina")},
	    }
	end

	aisah.RegisterModule("vitalstats", MOD)
end