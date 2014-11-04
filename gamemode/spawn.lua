function GM:PlayerSpawn(ply)
	ply:SetModel("models/player/alyx.mdl")

	ply:StripWeapons()
	ply:Give("bd_aisah")

	ply:GiveSkill("aisah")
	ply:GiveSkill("aisah_vitalstats")
end

hook.Add("PlayerDeath", "BD_RemovePlyAisah", function(ply)
	ply:BD_SetBool("wear_aisah", false)
end)