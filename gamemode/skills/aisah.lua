local SKILL = {}

function SKILL:RegisterVariables(ply)
	ply:BD_RegisterVar("wear_aisah", "Bool", false)
end

function SKILL:UnRegisterVariables(ply)
end

skills.RegisterModule("aisah", SKILL)