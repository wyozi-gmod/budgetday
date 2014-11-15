AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:KeyValue( key, value )
	if key == "firststage" then
		bd.MapSettings = bd.MapSettings or {}

		bd.MapSettings.FirstStageName = value
	end
end
