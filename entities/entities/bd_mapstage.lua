AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "FirstObjectiveName", {KeyName = "firstobjective"})
	self:NetworkVar("String", 1, "StageSettings", {KeyName = "stagesettings"})
end

function ENT:KeyValue( key, value )
	if (self:SetNetworkKeyValue(key, value)) then
		return
	end

	if key == "PoliceInformed" then
		self:StoreOutput(key, value)
	end
end
