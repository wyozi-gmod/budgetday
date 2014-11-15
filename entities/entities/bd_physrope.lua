AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/props_junk/meathook001a.mdl")

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

function ENT:HookPos(pos, descending)
	self:SetHookedPos(pos)
	self.HookTime = CurTime()
	self.IsDescending = descending

	self:EmitSound("physics/metal/metal_computer_impact_bullet1.wav")
end

function ENT:PhysicsCollide(data, phys)
	-- Dont allow hooking to skybox
	if data.HitEntity == game.GetWorld() then
		local tr = util.QuickTrace(data.HitPos, data.HitNormal, function() return false end)
		if tr.HitSky then
			phys:SetVelocity(Vector(0, 0, 0))
			return
		end
	end

	if not self:IsHookedPosValid() then
		self:HookPos(data.HitPos, true)

		self:SetMoveType(MOVETYPE_NONE)
	end
end

function ENT:Think()
	if SERVER then
		if self:IsHookedPosValid() then
			-- We add a Vec(0, 0, 20) if we're ascensing to make it easier to eg. get up a vent
			local diff = ((self:GetHookedPos() + (self.IsDescending and vector_origin or Vector(0, 0, 20))) - self:GetOwner():GetPos())
			if (not self.IsDescending and diff:Length() < 50 and diff.z < 0) or (CurTime() - self.HookTime) > 10 then
				self:Remove()
				return
			end
			local mul = self:GetOwner():KeyDown(IN_JUMP) and 11 or 8

			-- Compute a value that increases exponentially (or something like that) the further away
			--  we are from the rope _horizontally_. This makes moving across the map using grappling hook harder
			local diff_horizontal = Vector(diff.x, diff.y, 0)
			local mul_weakener = math.Clamp(1 / (diff_horizontal:Length() / 256), 0, 1)

			mul = mul * mul_weakener

			self:GetOwner():SetVelocity(diff:GetNormalized() * mul)
		else
			local tr = util.TraceLine{start = self:GetOwner():GetShootPos(), endpos = self:GetPos(), filter=function()return false end}
			if tr.Hit then
				self:HookPos(tr.HitPos, false)
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
			render.DrawBeam( self:GetOwner():GetShootPos() + Vector(0, 0, -5), self:GetHookedPos(), 5, 1, 1, Color( 255, 255, 255, 255 ) ) 
			render.DrawBeam( self:GetHookedPos(), self:GetPos(), 5, 1, 1, Color( 255, 255, 255, 255 ) ) 
		else
			render.DrawBeam( self:GetOwner():GetShootPos() + Vector(0, 0, -5), self:GetPos(), 5, 1, 1, Color( 255, 255, 255, 255 ) ) 
		end
	end
end