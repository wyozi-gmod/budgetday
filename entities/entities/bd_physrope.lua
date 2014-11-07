AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/weapons/w_bugbait.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "StartSegment")
	self:NetworkVar("Entity", 1, "EndSegment")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:SetNoDraw(true)
		self:DrawShadow(false)
		self:SetSolid(SOLID_NONE)
		self:SetMoveType(MOVETYPE_NONE)

		local start_seg = ents.Create("bd_physrope_segment")
		local end_seg = ents.Create("bd_physrope_segment")

		start_seg:SetNextSegment(end_seg)
		end_seg:SetPrevSegment(start_seg)

		self:SetStartSegment(start_seg)
		self:SetEndSegment(end_seg)

		start_seg:SetParent(self)

		start_seg.BallId = "start"
		end_seg.BallId = "end"

		start_seg:Spawn()
		end_seg:Spawn()
	end
end

function ENT:Think()
	if SERVER and IsValid(self.FollowEnt) then
		self:SetPos(self.FollowEnt:GetShootPos())
	end
	if CLIENT then
		--debugoverlay.Sphere(self:GetPos(), 16, 0.1, Color(255, 0, 0), true)
	end
end

if SERVER then

	function ENT:AttachToEntity(ent)
		self:GetEndSegment():SetParent(ent)
		self:GetEndSegment():SetLocalPos(Vector(0, 0, 0))
	end
	function ENT:OnRemove()
		local seg = self:GetStartSegment()
		while IsValid(seg) do
			local nxt = seg:GetNextSegment()
			seg:Remove()
			seg = nxt
		end
	end
end

local SEGMENT_ENT = {}

SEGMENT_ENT.Type = "anim"

function SEGMENT_ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "PrevSegment")
	self:NetworkVar("Entity", 1, "NextSegment")
end

function SEGMENT_ENT:Initialize()
	if SERVER then
		self:SetModel(Model("models/weapons/w_bugbait.mdl"))
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
end

local balls_added = 0

function SEGMENT_ENT:Think()
	debugoverlay.Sphere(self:GetPos(), 4, 0.1, Color(255, 255, 255), true)
	if IsValid(self:GetNextSegment()) then
		if SERVER then
			local prev_dist = IsValid(self:GetPrevSegment()) and self:GetPos():Distance(self:GetPrevSegment():GetPos()) or 9999

			local dist = self:GetPos():Distance(self:GetNextSegment():GetPos())
			local normdiff = (self:GetNextSegment():GetPos()-self:GetPos()):GetNormalized()

			local qtr = util.QuickTrace(self:GetPos(), normdiff*dist, function(e) return false end)

			if qtr.Hit and prev_dist > 32 and dist > 32 and balls_added < 15 then
				MsgN(qtr.Entity)
				--local mid_pos = (self:GetNextSegment():GetPos() + self:GetPos())
				--mid_pos:Mul(0.5)
				local mid_pos = qtr.HitPos

				local next_seg = ents.Create("bd_physrope_segment")
				next_seg.BallId = "newball" .. (balls_added)

				next_seg:SetPrevSegment(self)
				next_seg:SetNextSegment(self:GetNextSegment())

				self:GetNextSegment():SetPrevSegment(next_seg)
				self:SetNextSegment(next_seg)

				next_seg:SetPos(mid_pos)

				next_seg:Spawn()
				next_seg:SetMoveType(MOVETYPE_NONE)

				MsgN("Spawned ", next_seg.BallId, " between ", self.BallId, " and ", self:GetNextSegment().BallId)

				local phys = next_seg:GetPhysicsObject()
				if IsValid(phys) then phys:Wake() end

				debugoverlay.Sphere(mid_pos, 8, 0.1, Color(255, 127, 0), true)
				balls_added = balls_added + 1
				MsgN(balls_added, " balls added")
			end

			self:NextThink(CurTime())
			return true
		end
		--debugoverlay.Line(self:GetPos(), self:GetNextSegment():GetPos(), 0.1)
	end
end

scripted_ents.Register(SEGMENT_ENT, "bd_physrope_segment")

concommand.Add("testphysrope", function(ply)
	if ply.LastPhysRope then
		if IsValid(ply.LastPhysRope[1]) then ply.LastPhysRope[1]:Remove() end
		if IsValid(ply.LastPhysRope[2]) then ply.LastPhysRope[2]:Remove() end
		ply.LastPhysRope = nil
	end
	balls_added = 0

	local phys = ents.Create("prop_physics")
	phys:SetModel("models/props_lab/cactus.mdl")
	phys:SetPos(ply:EyePos() + ply:GetAimVector()*50)
	phys:Spawn()

	local physrope = ents.Create("bd_physrope")
	physrope:Spawn()

	physrope.FollowEnt = (ply)
	physrope:AttachToEntity(phys)

	phys:GetPhysicsObject():AddVelocity(ply:GetAimVector() * 1500)

	ply.LastPhysRope = {phys, physrope}
end)