AddCSLuaFile()

ENT.Type = "point"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "GuardType", {KeyName = "guardtype"})
	self:NetworkVar("String", 1, "CarryItem", {KeyName = "carryitem"})
end

function ENT:KeyValue( key, value )
	if (self:SetNetworkKeyValue(key, value)) then
		return
	end
end
