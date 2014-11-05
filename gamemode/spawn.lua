function GM:PlayerSpawn(ply)
	ply:SetModel("models/player/alyx.mdl")

	ply:StripWeapons()
	ply:Give("bd_aisah")

	ply:GiveSkill("aisah")
	ply:GiveSkill("aisah_vitalstats")

	ply:SetWalkSpeed(170)
	ply:SetRunSpeed(235)

	ply:SetupHands() -- Create the hands and call GM:PlayerSetHandsModel
end

function GM:PlayerSetHandsModel( ply, ent )
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end

hook.Add("PlayerDeath", "BD_RemovePlyAisah", function(ply)
	ply:BD_SetBool("wear_aisah", false)
end)