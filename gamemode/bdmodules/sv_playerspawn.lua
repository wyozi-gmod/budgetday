function GM:PlayerSelectSpawn(ply)
	return table.Random(ents.FindByClass("info_player_terrorist"))
end

function GM:PlayerSpawn(ply)
	ply:SetModel("models/player/alyx.mdl")

	ply:StripWeapons()
	ply:Give("weapon_bd_usp")

	ply:GiveSkill("aisah_vitalstats")
	ply:GiveSkill("aisah_nightvision")

	ply:SetupHands() -- Create the hands and call GM:PlayerSetHandsModel
end

function GM:PlayerDeathThink( pl )
end

function GM:PlayerDeathSound()
	return true
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
