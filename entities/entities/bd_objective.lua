AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/weapons/w_bugbait.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Description", {KeyName = "description"})
	self:NetworkVar("String", 1, "NextObjectiveName", {KeyName = "nextobjective"})

	self:NetworkVar("Int", 0, "ObjectiveItemRequirement", {KeyName = "objectiveitems"})
	self:NetworkVar("Int", 1, "ObjectiveItemsPicked")
end

function ENT:GetNextObjective()
	return ents.FindByName(self:GetNextObjectiveName())[1]
end

function ENT:KeyValue( key, value )
	if (self:SetNetworkKeyValue(key, value)) then
		return
	end

	if key == "OnEndObjective" then
		self:StoreOutput(key, value)
	end

	MsgN("Objective ", key, " = ", value)
end

function ENT:AcceptInput(name, activator)
	if name == "SetAsMainObjective" then
		SetGlobalEntity("Objective", self)
	end
end

function ENT:CheckObjectItemCount()
	if self:GetObjectiveItemRequirement() > 0 and self:GetObjectiveItemsPicked() >= self:GetObjectiveItemRequirement() then
		self:TriggerOutput("OnEndObjective", self)
	end
end

-- We want access to objective information from all around the map..
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:SetNoDraw(true)
		self:DrawShadow(false)
		self:SetSolid(SOLID_NONE)
		self:SetMoveType(MOVETYPE_NONE)
	end
end
