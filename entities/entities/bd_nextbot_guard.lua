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
		data.distance = bd.util.GetEntPosition(data.spotter):Distance(bd.util.GetEntPosition(data.ent))

		hook.Call("BDGuardSpotted", GAMEMODE, data)

		if callback then callback(data) end
	end

	return self:ShouldBeAlarmed()
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

	local upd_seen
	local upd_pos
	return self:MoveToPos(move_data.pos, {
		terminate_condition = function()
			if upd_seen and upd_seen < CurTime()-2 then upd_pos = nil end
			
			if self:UpdateSightSuspicion(function(data)
				local e = data.ent
				if IsValid(e) then
					self.loco:FaceTowards(e:GetPos())
					upd_pos = e:GetPos()
					upd_seen = CurTime()
				end
			end) then
				return true
			end

			if not upd_pos and move_data.susp_pos then
				self.loco:FaceTowards(move_data.susp_pos)
			end
			return false
		end,
		repath = 1,
		repath_pos = function() return upd_pos end
	})
end

local cvar_preventalarm = SERVER and CreateConVar("bd_debug_preventalarm", "0", FCVAR_CHEAT + FCVAR_NOTIFY)
function ENT:ShouldBeAlarmed()
	return self:GetSuspicionLevel() >= 1 and not cvar_preventalarm:GetBool()
end

function ENT:AlarmedMode(poi)

	-- Before calling for help lets turn towards POI position to see if theres some to shoot at there
	if not self.HasCalledForHelp and poi and poi.spotted_directly and poi.pos then
		self.loco:FaceTowards(poi.pos)
	end

	local shoot_targ
	self:UpdateSightSuspicion(function(data)
		if data.ent:IsPlayer() then shoot_targ = data.ent end
	end)

	local is_hurt = self:Health() < 35

	local force_rearm = false

	-- If we're in alarmed mode and there is nothing to shoot, we will call for help
	if not self.HasCalledForHelp and (not shoot_targ or is_hurt) then
		self:SetNWBool("CallingForHelp", CurTime())

		self:PlaySequenceAndWait("Shoot_to_crouchpistol")
		--self:SetSequence("harrassidle")

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
		self:GiveWeapon(bd.weaponcfg.GuardWeapon)
		self:PlaySequenceAndWait("drawpistol")

		self.IsArmed = true
	end

	if IsValid(shoot_targ) and bd.util.ComputeLos(self, shoot_targ) then
		local shootposang = self:GetAttachment(self:LookupAttachment("anim_attachment_RH"))
		local shootpos = shootposang.Pos
		local tpos = shoot_targ:GetBonePosition(shoot_targ:LookupBone("ValveBiped.Bip01_Spine"))
		self:AimAt(tpos)

		if not self.NextShoot or self.NextShoot <= CurTime() then
			local bullet = {}

			local ang = (tpos - shootpos):Angle()
			local pos = shootpos + ang:Up() * 5

			bullet.Num 	= 1
			bullet.Dir 	= ang:Forward()
			bullet.Src 	= pos
			bullet.Spread 	= Vector( 0.07, 0.07, 0 )	 -- Aim Cone
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

			self.NextShoot = CurTime() + math.random(0.3, 0.4)
			self.Shots = (self.Shots or 0) + 1

			if self.Shots % 12 == 0 then
				self:PlaySequenceAndWait("Shoot_to_crouchpistol")
				self:PlaySequenceAndWait("crouch_reload_pistol")
				self:PlaySequenceAndWait("crouch_to_shootpistol")
			end
		end
	elseif poi and poi.spotted_directly and poi.pos then
		local seesSomethingInteresting = true

		-- Only check if we're looking at something interesting if we're already looking at POI pos
		if self:EyeDirN():DotProduct((poi.pos - self:EyePosN()):GetNormalized()) > 0.8 then
			local losEnts = self:ComputeLOSEntities {
				filter = function(ent)
					return ent:IsPlayer() or
							ent:GetClass() == "prop_ragdoll"
				end
			}

			seesSomethingInteresting = #losEnts > 0

			-- Note:
			-- We're in alarmed mode, so if we see a ragdoll we should acknowledge it, but it is definitely
			-- not more important than eg. ongoing gunfight. That's why we prioritize everything else with
			-- IgnoreDistractionsAt function over this specific ragdoll
			for _,edata in pairs(losEnts) do
				if edata.ent:GetClass() == "prop_ragdoll" then
					self:IgnoreDistractionsAt(edata.ent:GetPos(), "spotted_ragdoll", 3)
				end
			end
		end

		if not seesSomethingInteresting then
			self:IgnoreDistractionsAt(poi.pos, poi.cause, 3)
			return 0
		end

		local tpos = poi.pos
		self:LookAt(tpos)
	end

	return 0
end

-- Call this to ignore distractions at some point for x time
function ENT:IgnoreDistractionsAt(pos, cause, time, radius)
	radius = radius or 256

	self.IgnoringDistractions = self.IgnoringDistractions or {}
	table.insert(self.IgnoringDistractions, {pos = pos, cause = cause, ends = CurTime() + time, time = time, radius = radius})
end

function ENT:ShouldIgnoreDistraction(pos, cause)
	if not pos then return false end
	if not self.IgnoringDistractions then return false end

	for _,id in pairs(self.IgnoringDistractions) do
		local isWithinTime = id.time == 0 or id.ends > CurTime()
		local isWithin = id.pos:Distance(pos) < id.radius
		local isCause = not cause or id.cause == cause
		if isWithinTime and isWithin and isCause then
			return true
		end
	end

	return false
end

function ENT:ComputeDistractionClusters()
	if not self.DistractionHistory then return {} end

	local hist = self.DistractionHistory

	-- Get distractions that happened <10s ago and group them based on cause
	hist = bd.util.FilterSeq(hist, function(v) return (CurTime() - v.happened) < 10 end)
	hist = bd.util.Group(hist, function(v) return v.data.cause end)

	-- TODO divide grouped data into subgroups based on positions

	local flattened = {}
	for cause, data in pairs(hist) do
		local t = {level = 0}

		local spotter

		local datacount = 0
		for _,d in pairs(data) do
			if d.data.pos then
				if not t.pos then t.pos = Vector(0, 0, 0) end

				t.pos = t.pos + d.data.pos
				datacount = datacount+1
			end

			t.level = t.level + d.data.level

			if spotter == nil then spotter = d.data.spotter_ent end
			if spotter and spotter ~= d.data.spotter_ent then spotter = false end
		end

		if t.pos then t.pos = t.pos / datacount end

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
			if group.level > 0 and (not poi or group.level > poi.level) and (not self:ShouldIgnoreDistraction(group.pos, group.cause)) then
				poi = {pos = group.pos, level = group.level, spotter = group.spotter, cause = group.cause}

				-- Is the POI caused by something we saw with our own ears or heard nearby
				poi.spotted_directly = (poi.cause:StartWith("spotted_") and
											(not poi.spotter or
												poi.spotter:GetClass() ~= "bd_camera")) or
									   (poi.cause:StartWith("heard_") and
											poi.pos and
											poi.pos:Distance(self:GetPos()) < 512)
			end
		end
	end

	if self:ShouldBeAlarmed() then
		return self:AlarmedMode(poi)
	end

	self:UpdateSightSuspicion()

	if self.NPCType == "roaming" and ( (poi and poi.cause == "monitoring_asked") or (not self.NextRoam or self.NextRoam < CurTime()) ) then
		local pos = table.Random(ents.FindByClass("bd_npc_poi")):GetPos()
		if poi and poi.cause == "monitoring_asked" then
			pos = poi.pos

			-- Look at the spot first
			self.loco:FaceTowards(poi.pos)
			--MsgN("Going to spot that monitoring asked us to check")
		end

		self:StartMovingTo {
			pos = pos,
			run = false,
			susp_pos = poi and poi.pos
		}

		self.NextRoam = CurTime() + math.Rand(2, 15)
	end

	if self.NPCType == "monitoring" and poi and not poi.spotted_directly and poi.level >= 0.1 and (not self.NextMonAsk or self.NextMonAsk < CurTime()) then
		local alarmTriggered = false

		self:SetSequence("stopwoman")
		if self:DynamicWait(math.random(0.6, 1.3), function()
			return self:UpdateSightSuspicion()
		end) then return end

		self:EmitSound("npc/combine_soldier/vo/callcontacttarget1.wav")
		if self:DynamicWait(1.5 + math.random(1.0, 1.5), function()
			return self:UpdateSightSuspicion()
		end) then return end

		local randomGuard = table.Random(ents.FindByClass("bd_nextbot_guard"))
		if IsValid(randomGuard) then
			randomGuard:NotifyDistraction({
				level = 0.3,
				pos = poi.pos,
				cause = "monitoring_asked"
			})
		end

		self.NextMonAsk = CurTime() + math.Rand(3, 8)
	end

	if poi and poi.level >= 0.25 and poi.spotted_directly then
		self.loco:FaceTowards(poi.pos)
	end

	self:StartActivity(ACT_IDLE)
	coroutine.wait(0.1)
end
