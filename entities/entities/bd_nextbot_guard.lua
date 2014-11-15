AddCSLuaFile()

ENT.Base = "bd_nextbotbase"

ENT.Model = Model("models/Police.mdl")

local detection_ranges = {
	["bd_camera"] = {dist = 768, dot = 0.65},
	["bd_nextbot_guard"] = {dist = 768, dot = 0.5},
	default = {dist = 512, dot = 0.5}
}

function ENT:CheckForCameras(pos, dir, spotter_ent, callback, checked_cameras)
	checked_cameras = checked_cameras or {}

	callback(pos, dir, spotter_ent)

	local check_ents = ents.FindByClass("bd_camera_monitor")

	for _,ce in pairs(check_ents) do
		if not table.HasValue(checked_cameras, ce) then

			local pos_diff = (ce:GetPos() - pos)
			local pos_diff_normal = pos_diff:GetNormalized()
			local dot = dir:Dot(pos_diff_normal)
			local dist = pos_diff:Length()

			local reqval = detection_ranges[spotter_ent:GetClass()] or detection_ranges.default
			if dist < reqval.dist and dot > reqval.dot and bd.util.ComputeLos(spotter_ent, ce) then
				local acam = ce:GetActiveCamera()
				if IsValid(acam) and not table.HasValue(checked_cameras, acam) then
					table.insert(checked_cameras, acam)
					local cpos, cang = acam:GetCameraPosAng()
					self:CheckForCameras(cpos, cang:Forward(), acam, callback, checked_cameras)
				end
			end
		end
		
	end
end
function ENT:SpotEntities(pos, dir, spot_callback, spotter_ent)
	local check_ents = {}
	table.Add(check_ents, player.GetAll())
	table.Add(check_ents, ents.FindByClass("prop_ragdoll"))

	for _,ce in pairs(check_ents) do
		local targpos = ce:GetPos()
		if ce:IsPlayer() then
			targpos = ce:EyePos()
		end

		local pos_diff = (targpos - pos)
		local pos_diff_normal = pos_diff:GetNormalized()
		local dot = dir:Dot(pos_diff_normal)
		local dist = pos_diff:Length()

		local is_los_clear = bd.util.ComputeLos(spotter_ent, ce)

		local reqval = detection_ranges[spotter_ent:GetClass()] or detection_ranges.default

		if dist < reqval.dist and dot > reqval.dot and is_los_clear then
			spot_callback({
				ent = ce,
				spotter_ent = spotter_ent,
				pos = pos,
				targpos = targpos,
				dot = dot,
				dist = dist
			})
		end
	end
end
function ENT:SpotPosition(spot_callback)
	self:CheckForCameras(self:GetPos() + Vector(0,0,60), self:GetAngles():Forward(), self, function(pos, dir, spotter_ent)
		self:SpotEntities(pos, dir, spot_callback, spotter_ent)
	end)
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
			if move_data.spot_callback then
				self:SpotPosition(move_data.spot_callback)
				if self:GetSuspicionLevel() >= 1 then
					return true
				end
			end
			return false
		end,
		repath = 1
	})
end


function ENT:AlarmedMode(poi)
	if not self.IsAlarmed then
		if poi then
			self.loco:FaceTowards(poi.pos)
		end

		self:AddFakeWeapon("models/weapons/w_pist_glock18.mdl")
		self:PlaySequenceAndWait("drawpistol")
		--ent:PlaySequenceAndWait("Stand_to_crouchpistol")
		--ent:SetSequence("Crouch_idle_pistol")
		self.IsAlarmed = true
	end

	local shoot_targ
	self:SpotPosition(function(data)
		if data.ent:IsPlayer() then shoot_targ = data.ent end
	end)

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
	elseif poi then
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

		for _,d in pairs(data) do
			t.pos = t.pos + d.data.pos
			t.level = t.level + d.data.level
		end

		t.pos = t.pos / #data

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
				poi = {pos = group.pos, level = group.level}
			end
		end
	end

	if self:GetSuspicionLevel() >= 1 then
		return self:AlarmedMode(poi)
	end
	local spot_callback = function(data)
		data.guard = self
		hook.Call("BDGuardSpotted", GAMEMODE, data)
	end

	self:SpotPosition(spot_callback)

	if self.NPCType == "roaming" and (not self.NextRoam or self.NextRoam < CurTime()) then
		self:StartMovingTo {
			pos = table.Random(ents.FindByClass("bd_npc_poi")):GetPos(),
			run = false,
			spot_callback = spot_callback
		}

		self.NextRoam = CurTime() + math.random(2, 15)
	end

	if poi and poi.level >= 0.25 then
		self.loco:FaceTowards(poi.pos)
	end

	self:StartActivity(ACT_IDLE)
end