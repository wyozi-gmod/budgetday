AddCSLuaFile()

ENT.Type = "anim"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "InteractLength", {KeyName = "interacttime"})
	self:NetworkVar("Int", 0, "HighlightItemType", {KeyName = "highlightitem"})
	self:NetworkVar("Bool", 0, "CarriedByPlayer", {KeyName = "carriedbyply"})
	self:NetworkVar("String", 0, "ObjectiveName", {KeyName = "objective"})
end

function ENT:KeyValue( key, value )
	if (self:SetNetworkKeyValue(key, value)) then
		return
	end

	if key == "model" then
		self.Model = Model(value)
	elseif key == "highlightitem" then
		MsgN("Highlightitem: ", value)
	end
	MsgN("Objective item ", key, " = ", value)
end

function ENT:GetObjective()
	return ents.FindByName(self:GetObjectiveName())[1]
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
	end
end
