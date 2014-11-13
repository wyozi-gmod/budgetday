local SKILL = {}

function SKILL:RegisterVariables(ply)
end

function SKILL:UnRegisterVariables(ply)
end

bd.skills.Register("aisah_policeradio", SKILL)

if CLIENT then
	local MOD = {}

	local icon_heart = Material("icon16/heart.png")
	local icon_shield = Material("icon16/shield.png")
	local icon_sports = Material("icon16/sports.png")

	function MOD:Has(ply)
	    return ply:HasSkill("aisah_policeradio")
	end

	function MOD:Setup()
	end

	function MOD:HUDData(data)
	    data.title = "Police Radio Analyzer"
	    data.indicators = {
	        {title = "Threat level", bars = {count = 0, max = 5}, text = "Low", textcolor = LerpColor(0, Color(255, 255, 255), Color(255, 0, 0))},
	    }
	end

	bd.RegisterAISAHModule("policeradio", MOD)
end