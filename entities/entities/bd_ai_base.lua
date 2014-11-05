AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

function ENT:SetupDataTables()
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/alyx.mdl")
	end
end

-- So confusing
function ENT:EyePosN()
	return self:EyePos() + (SERVER and Vector(0, 0, 32) or Vector(0, 0, 64))
end

function ENT:IsPointOnSight(p)
	--http://stackoverflow.com/questions/12826117/how-can-i-detect-if-a-point-is-inside-of-a-cone-or-not-in-3d-space

	local cone_tip = self:EyePosN()
	local cone_dir = self:EyeAngles():Forward()
	local cone_height = 1024

	local cone_base_radius = 512

	local p_tip_diff = p - cone_tip

	local cone_dist = p_tip_diff:Dot(cone_dir)
	if cone_dist < 0 or cone_dist > cone_height then return false end

	local cone_radius_at_point = (cone_dist / cone_height) * cone_base_radius
	local orth_dist =  (p_tip_diff - cone_dist * cone_dir):Length()

	return orth_dist < cone_radius_at_point
end

if SERVER then
	function ENT:AddFlashlight()
		local shootpos = self:GetAttachment(self:LookupAttachment("anim_attachment_LH"))

		local wep = ents.Create("gmod_lamp")
		wep:SetModel(Model("models/maxofs2d/lamp_flashlight.mdl"))
		wep:SetOwner(self)

		wep:SetFlashlightTexture("effects/flashlight001")
		wep:SetColor(Color(255, 255, 255))
		wep:SetDistance(512)
		wep:SetBrightness(1)
		wep:SetLightFOV(80)
	    wep:Switch(true)

	    wep:Spawn()

	    wep:SetModelScale(0.5, 0)
	    
	    wep:SetSolid(SOLID_NONE)
	    wep:SetParent(self)

	    wep:Fire("setparentattachment", "anim_attachment_LH")

	    self.Flashlight = wep
	end

	function ENT:AddFakeWeapon(model)
		local shootpos = self:GetAttachment(self:LookupAttachment("anim_attachment_RH"))

		local wep = ents.Create("prop_physics")
		wep:SetModel(model)
		wep:SetOwner(self)
		wep:SetPos(shootpos.Pos)
	    --wep:SetAngles(ang)
	    wep:Spawn()
	    
	    wep:SetSolid(SOLID_NONE)
	    wep:SetParent(self)

	    wep:Fire("setparentattachment", "anim_attachment_RH")
	    wep:AddEffects(EF_BONEMERGE)
	    wep:SetAngles(self:GetForward():Angle())
	end

	function ENT:BehaveAct()

	end
	function ENT:MoveToPos( pos, options )
		local options = options or {}

		local path = Path( "Follow" )
		path:SetMinLookAheadDistance( options.lookahead or 300 )
		path:SetGoalTolerance( options.tolerance or 20 )
		path:Compute( self, pos )

		if ( !path:IsValid() ) then return "failed" end

		while ( path:IsValid() ) do
			if options.terminate_condition and options.terminate_condition() then
				return "terminated"
			end

			path:Update( self )

			-- Draw the path (only visible on listen servers or single player)
			if ( options.draw ) then
				path:Draw()
			end

			-- If we're stuck then call the HandleStuck function and abandon
			if ( self.loco:IsStuck() ) then
				self:HandleStuck()
				return "stuck"
			end

			--
			-- If they set maxage on options then make sure the path is younger than it
			--
			if ( options.maxage ) then
				if ( path:GetAge() > options.maxage ) then return "timeout" end
			end

			--
			-- If they set repath then rebuild the path every x seconds
			--
			if ( options.repath ) then
				if ( path:GetAge() > options.repath ) then
					local newpos = (options.repath_pos and options.repath_pos() or pos)
					path:Compute( self, newpos )
				end
			end

			coroutine.yield()
		end
		return "ok"
	end

	function ENT:SetBrain(brain)
		self.Brain = brain

		self.BrainData = {}
		setmetatable(self.BrainData, {__index = self.Brain})

		if self.Brain.Initialize then
			self.Brain.Initialize(self.BrainData, self)
		end
	end

	function ENT:RunBehaviorTick()
		local brain = self.Brain
		local braindata = self.BrainData

		if not brain then
			self:StartActivity(ACT_IDLE)
		else
			local nextthink = braindata.NextThink
			if not nextthink or nextthink <= CurTime() then
				local nt = brain.Think(braindata, self)
				braindata.NextThink = nt
			end
		end
		--[[
		self.loco:SetAcceleration(100)
		self:MoveToPos(player.GetByID(1):GetPos(), {draw = true})
		self:SetEyeAngles((player.GetByID(1):EyePos() - self:EyePosN()):Angle())
		]]
	end

	function ENT:RunBehaviour()

		while ( true ) do
			local stat, err = pcall(function() self:RunBehaviorTick() end)

			coroutine.yield()
		end
	end

	function ENT:Think()
		if IsValid(self.Flashlight) then
			local shootpos = self:GetAttachment(self:LookupAttachment("anim_attachment_LH"))
			local pos, ang = shootpos.Pos, shootpos.Ang
			ang:RotateAroundAxis(ang:Right(), 180)
			self.Flashlight:SetAngles(ang)
		end
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end
end

if CLIENT then
	local matBeam = Material( "effects/lamp_beam" )
	function ENT:DrawSight(points)
		points = points or 32

		local cone_tip = self:EyePosN()
		local cone_dir_ang = self:EyeAngles()
		local cone_dir = cone_dir_ang:Forward()

		local cone_dir_right = cone_dir_ang:Right()
		local cone_dir_up = cone_dir_ang:Up()

		local cone_height = 650

		local cone_base_radius = 350

		--[[local rad_per_point = (math.pi*2) / points
		for p=0,points do
			local rad = rad_per_point * p

			local tr = util.QuickTrace (
				cone_tip,
				cone_dir * cone_height + cone_dir_right*math.cos(rad)*cone_base_radius + cone_dir_up*math.sin(rad)*cone_base_radius,
				self
			)

			debugoverlay.Line(tr.StartPos, tr.HitPos, 0.1, Color(255, 255, 255))
		end]]

		render.SetMaterial( matBeam )
		render.StartBeam( 2 )
		render.AddBeam( cone_tip, 128, 0.0, Color( 255, 255, 255, 64) )
		render.AddBeam( cone_tip + cone_dir*cone_height, cone_base_radius, 1, Color( 255, 255, 255, 100) )
		render.EndBeam()
	end
end