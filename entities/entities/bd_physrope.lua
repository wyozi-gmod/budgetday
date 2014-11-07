AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/freeman/grapplinghook/scripthook.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "HookedPos")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end
end

function ENT:IsHookedPosValid()
	return self:GetHookedPos() ~= vector_origin
end

function ENT:PhysicsCollide(data, phys)
	if not self:IsHookedPosValid() then
		self:SetHookedPos(data.HitPos)
		self.HookTime = CurTime()
		self.IsDescending = true

		self:SetMoveType(MOVETYPE_NONE)
	end
end

function ENT:Think()
	if SERVER then
		if self:IsHookedPosValid() then
			local diff = (self:GetHookedPos() - self:GetOwner():GetPos())
			if (not self.IsDescending and diff:Length() < 50 and diff.z < 0) or (CurTime() - self.HookTime) > 10 then
				self:Remove()
				return
			end
			local mul = self:GetOwner():KeyDown(IN_JUMP) and 11 or 8
			self:GetOwner():SetVelocity(diff:GetNormalized() * mul)
		else
			local tr = util.TraceLine{start = self:GetOwner():GetShootPos(), endpos = self:GetPos(), filter=function()return false end}
			if tr.Hit then
				self:SetHookedPos(tr.HitPos)
				self.HookTime = CurTime()
				self.IsDescending = false
			end
		end

		self:NextThink(CurTime())
		return true
	end
end

if CLIENT then
	local rope = Material( "cable/rope" )
	function ENT:Draw()
		self:DrawModel()

		render.SetMaterial( rope )
		if self:IsHookedPosValid() then
			render.DrawBeam( self:GetOwner():GetShootPos() + Vector(0, 0, -20), self:GetHookedPos(), 5, 1, 1, Color( 255, 255, 255, 255 ) ) 
			render.DrawBeam( self:GetHookedPos(), self:GetPos(), 5, 1, 1, Color( 255, 255, 255, 255 ) ) 
		else
			render.DrawBeam( self:GetOwner():GetShootPos() + Vector(0, 0, -20), self:GetPos(), 5, 1, 1, Color( 255, 255, 255, 255 ) ) 
		end
	end
end