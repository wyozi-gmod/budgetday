AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/computer_monitor.mdl")

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end
end