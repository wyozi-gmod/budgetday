AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:KeyValue( key, value )
	if key == "firstobjective" then
		bd.MapSettings = bd.MapSettings or {}

		bd.MapSettings.FirstObjectiveName = value
	end
end
