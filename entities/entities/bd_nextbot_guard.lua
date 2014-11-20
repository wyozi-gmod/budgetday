AddCSLuaFile()

ENT.Base = "bd_nextbotbase"

ENT.Model = Model("models/Police.mdl")

function ENT:UpdateSightSuspicion(callback)
	local los_ents = self:ComputeLOSEntities({
		filter = function(ent)
			return ent:IsPlayer() or
					ent:GetClass() == "prop_ragdoll" or
					ent:GetClass():StartWith("bd_nextbot*")
		end
	})

	for _,data in pairs(los_ents) do
		data.original_spotter = self

		-- Compute some useful variables that are bound to be computed at some point anyway
		data.distance = bd.util.GetEntPosition(data.original_spotter):Distance(bd.util.GetEntPosition(data.ent))

		hook.Call("BDGuardSpotted", GAMEMODE, data)

		if callback then callback(data) end
	end
end

function ENT:StartMovingTo(move_data)
	if move_data.type == "run" then
		self.loco:SetAcceleration(140)
		self.loco:SetDesiredSpeed(140)
		self:StartActivity(ACT_RUN)
	else
		self.loco:SetAcceleration(100)
		self.loco:SetDesiredSpeed(100)
		self:StartActivity(ACT_WALK)
	end
	self.loco:SetDeathDropHeight(40)

	self:MoveToPos(move_data.pos, {
		terminate_condition = function()
			self:UpdateSightSuspicion()

			if self:GetSuspicionLevel() >= 1 then
				return true
			end
			return false
		end,
		repath = 1
	})
end


function ENT:AlarmedMode(poi)
	-- First we check for valid targets to shoot at

	local shoot_targ
	self:UpdateSightSuspicion(function(data)
		if data.ent:IsPlayer() then shoot_targ = data.ent end
	end)

	local force_rearm = false

	-- If we're in alarmed mode and there is nothing to shoot, we will call for help
	if not self.HasCalledForHelp and not shoot_targ then
		self:SetNWBool("CallingForHelp", CurTime())

		self:SetSequence("harrassidle")

		coroutine.wait(math.random(0.6, 1.3))

		-- Just spout random crap. Rofl
		self:EmitSound("npc/combine_soldier/vo/isfinalteamunitbackup.wav")
		coroutine.wait(2 + math.random(0.1, 1))
		self:EmitSound("npc/combine_soldier/vo/heavyresistance.wav")
		coroutine.wait(1.5 + math.random(0.1, 1.5))

		bd.policeraid.Start()

		self:SetNWFloat("CallingForHelp", 0)

		self.HasCalledForHelp = true

		force_rearm = true
	end

	if not self.IsArmed or force_rearm then
		self:GiveWeapon("weapon_bd_usp")
		self:PlaySequenceAndWait("drawpistol")

		self.IsArmed = true
	end

	if IsValid(shoot_targ) and bd.util.ComputeLos(self, shoot_targ) then
		self.loco:FaceTowards(shoot_targ:GetBonePosition(shoot_targ:LookupBone("ValveBiped.Bip01_Spine")))

		if not self.NextShoot or self.NextShoot <= CurTime() then

			local bullet = {}

			local shootpos = self:GetAttachment(self:LookupAttachment("anim_attachment_LH"))

			local ang = self:GetAngles()
			local pos = shootpos.Pos + ang:Up() * 5

			bullet.Num 	= 1
			bullet.Dir 	= ang:Forward()
			bullet.Src 	= pos
			bullet.Spread 	= Vector( 0.1, 0.1, 0 )	 -- Aim Cone
			bullet.Tracer	= 1 -- Show a tracer on every x bullets
			bullet.Force	= 1 -- Amount of force to give to phys objects
			bullet.Damage	= 25
			bullet.AmmoType = "Pistol"

			--debugoverlay.Line(bullet.Src, bullet.Src + bullet.Dir * 100, 2)

			self:FireBullets( bullet )
			self:EmitSound(Sound( "Weapon_Glock.Single" ))

			local effectdata = EffectData()
			effectdata:SetOrigin(bullet.Src)
			effectdata:SetStart(bullet.Src)
			effectdata:SetAngles(ang)

			util.Effect( "MuzzleEffect", effectdata )

			self.NextShoot = CurTime() + math.random(0.3, 0.6)
		end
	elseif poi and poi.spotted_directly then
		self.loco:FaceTowards(poi.pos)
	end

	return 0
end

function ENT:ComputeDistractionClusters()
	if not self.DistractionHistory then return {} end

	local hist = self.DistractionHistory
	hist = bd.util.FilterSeq(hist, function(v) return (CurTime() - v.happened) < 10 end)
	hist = bd.util.Group(hist, function(v) return v.data.cause end)

	-- TODO divide grouped data into subgroups based on positions

	local flattened = {}
	for cause, data in pairs(hist) do
		local t = {pos = Vector(0, 0, 0), level = 0}

		local spotter

		for _,d in pairs(data) do
			t.pos = t.pos + d.data.pos
			t.level = t.level + d.data.level

			if spotter == nil then spotter = d.data.spotter_ent end
			if spotter and spotter ~= d.data.spotter_ent then spotter = false end
		end

		t.pos = t.pos / #data
		t.cause = cause

		-- If spotter is not nil, all tables in 'data' had the same spotter
		-- if spotter is false, they had differing spotters
		if spotter then t.spotter = spotter end

		flattened[cause] = t
	end

	return flattened
end

function ENT:BehaviourTick()
	local poi
	if self.DistractionHistory then
		local clusters = self:ComputeDistractionClusters()

		for groupname,group in pairs(clusters) do
			if group.level > 0 and (not poi or group.level > poi.level) then
				poi = {pos = group.pos, level = group.level, spotter = group.spotter, cause = group.cause}

				-- Did we see whatever happened with our own eyes
				poi.spotted_directly = not poi.spotter or poi.spotter:GetClass() ~= "bd_camera"
			end
		end
	end

	if self:GetSuspicionLevel() >= 1 then
		return self:AlarmedMode(poi)
	end

	self:UpdateSightSuspicion()

	if self.NPCType == "roaming" and (not self.NextRoam or self.NextRoam < CurTime()) then
		self:StartMovingTo {
			pos = table.Random(ents.FindByClass("bd_npc_poi")):GetPos(),
			run = false,
			spot_callback = spot_callback
		}

		self.NextRoam = CurTime() + math.random(2, 15)
	end

	if poi and poi.level >= 0.25 and poi.spotted_directly then
		self.loco:FaceTowards(poi.pos)
	end

	self:StartActivity(ACT_IDLE)
end
