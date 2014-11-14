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
	elseif key == "OnFinishInteraction" or key == "OnCancelInteraction" then
		self:StoreOutput(key, value)
	end

end

function ENT:GetObjective()
	return ents.FindByName(self:GetObjectiveName())[1]
end

function ENT:InteractionFinished(ply)
	self:TriggerOutput("OnFinishInteraction", ply)

	if self:GetCarriedByPlayer() then
		ply:PickupObject(self)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		MsgN("PICKING UP ", self)
	else
		self:Remove()
	end

	-- Increase the ObjectiveItemsPicked counter in parent objective
	local obj = self:GetObjective()
	if IsValid(obj) then
		obj:SetObjectiveItemsPicked(obj:GetObjectiveItemsPicked() + 1)
		obj:CheckObjectItemCount()
	end
end
function ENT:InteractionCanceled(ply)
	self:TriggerOutput("OnCancelInteraction", ply)
end

bd.interactions.Register("objective_item_pickup", {
	filter = function(ent, ply) return ent:GetClass() == "bd_objective_item" end,
	help = function(ent, ply) return "Pickup" end,
	finish = function(ent, ply)
		ent:InteractionFinished(ply)
	end,
	cancel = function(ent, ply)
		ent:InteractionCanceled(ply)
	end,
	length = function(ent) return ent:GetInteractLength() end
})

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
	end
end
