AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("props/cs_assault/camera.mdl")

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
	end
end