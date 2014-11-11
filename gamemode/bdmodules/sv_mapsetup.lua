
local detection_ranges = {
	["bd_camera"] = {dist = 768, dot = 0.65},
	["bd_ai_base"] = {dist = 768, dot = 0.5},
	default = {dist = 512, dot = 0.5}
}

hook.Add("Think", "BDHighlightSight", function()
	-- Only used for debugging
	if true then return end

	local ent = {}
	table.Add(ent, ents.FindByClass("bd_camera"))
	table.Add(ent, ents.FindByClass("bd_ai_base"))

	for _,cam in pairs(ent) do
		local posang = cam.GetCameraPosAng and {cam:GetCameraPosAng()} or {cam:EyePosN(), cam:GetAngles()}
		local pos, ang = posang[1], posang[2]

		local reqval = detection_ranges[cam:GetClass()] or detection_ranges.default
		local dist, dot = reqval.dist, reqval.dot

		debugoverlay.Line(pos, pos+ang:Forward()*dist, 0.1, Color(0, 255, 0))

		-- Dot product into an angle
		local added_ang = math.acos(dot)

		local radius = math.tan(added_ang) * dist

		local points = 32
		local rad_per_point = math.pi*2 / points
		for i=0,points do
			debugoverlay.Line(pos, pos+ang:Forward()*dist +
									ang:Right()*math.cos(rad_per_point*i)*radius +
									ang:Up()*math.sin(rad_per_point*i)*radius, 0.1, Color(100, 255, 100))
		end
	end
end)

local function Map(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		t[k] = fn(v, k)
	end
	return t
end

-- Filter for sequential tables
local function FilterSeq(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		if fn(v, k) then t[#t+1] = v end
	end
	return t
end

local function GroupSeq(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		local group = fn(v, k)

		t[group] = t[group] or {}
		table.insert(t[group], v)
	end
	return t
end

local function FlattenAverage(tbl)
	local t = {}
	for k,v in pairs(tbl) do
		local res = {}

		local amount = 0
		for k2,v2 in pairs(v) do
			local meta = getmetatable(v2)
			if res[k2] and meta and meta.__plus then
				res[k2] = res[k2] + v2
			else
				res[k2] = v2
			end 

			amount = amount + 1
		end

		for k2,v2 in pairs(res) do
			local meta = getmetatable(res[k2])
			if meta and meta.__div then
				res[k2] = v2 / amount
			end
		end

		t[k] = res
	end
	return t
end

local brain_generic = {
	CheckForCameras = function(self, pos, dir, spotter_ent, callback, checked_cameras)
		checked_cameras = checked_cameras or {}

		callback(pos, dir, spotter_ent)

		local check_ents = ents.FindByClass("bd_camera_monitor")

		for _,ce in pairs(check_ents) do
			if table.HasValue(checked_cameras, ce) then continue end

			local pos_diff = (ce:GetPos() - pos)
			local pos_diff_normal = pos_diff:GetNormalized()
			local dot = dir:Dot(pos_diff_normal)
			local dist = pos_diff:Length()

			local reqval = detection_ranges[spotter_ent:GetClass()] or detection_ranges.default
			if dist < reqval.dist and dot > reqval.dot and bd.ComputeLos(spotter_ent, ce) then
				local acam = ce:GetActiveCamera()
				if IsValid(acam) and not table.HasValue(checked_cameras, acam) then
					table.insert(checked_cameras, acam)
					local cpos, cang = acam:GetCameraPosAng()
					self:CheckForCameras(cpos, cang:Forward(), acam, callback, checked_cameras)
				end
			end

		end
	end,
	SpotEntities = function(self, pos, dir, spot_callback, spotter_ent)
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

			local is_los_clear = bd.ComputeLos(spotter_ent, ce)

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
	end,
	SpotPosition = function(self, ent, spot_callback)
		self:CheckForCameras(ent:GetPos() + Vector(0,0,60), ent:GetAngles():Forward(), ent, function(pos, dir, spotter_ent)
			self:SpotEntities(pos, dir, spot_callback, spotter_ent)
		end)
	end,
	StartMovingTo = function(self, data, ent, move_data)
		if move_data.type == "run" then
			ent.loco:SetAcceleration(140)
			ent.loco:SetDesiredSpeed(140)
			ent:StartActivity(ACT_RUN)
		else
			ent.loco:SetAcceleration(100)
			ent.loco:SetDesiredSpeed(100)
			ent:StartActivity(ACT_WALK)
		end
		ent.loco:SetDeathDropHeight(40)

		ent:MoveToPos(move_data.pos, {
			terminate_condition = function()
				if move_data.spot_callback then
					self:SpotPosition(ent, move_data.spot_callback)
					if ent:GetDistractionLevel() >= 1 then
						return true
					end
				end
				return false
			end,
			repath = 1
		})
	end,
	AlarmedMode = function(self, data, ent, poi)
		if not data.IsAlarmed then
			ent:PlaySequenceAndWait("drawpistol")
			ent:AddFakeWeapon("models/weapons/w_pist_glock18.mdl")
			--ent:PlaySequenceAndWait("Stand_to_crouchpistol")
			--ent:SetSequence("Crouch_idle_pistol")
			data.IsAlarmed = true
		end

		local shoot_targ
		self:SpotPosition(ent, function(data)
			if data.ent:IsPlayer() then shoot_targ = data.ent end
		end)

		if IsValid(shoot_targ) and bd.ComputeLos(ent, shoot_targ) then
			ent.loco:FaceTowards(shoot_targ:GetBonePosition(shoot_targ:LookupBone("ValveBiped.Bip01_Spine")))

			if not data.NextShoot or data.NextShoot <= CurTime() then

				local bullet = {}

				local shootpos = ent:GetAttachment(ent:LookupAttachment("anim_attachment_LH"))

				local ang = ent:GetAngles()
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
				
				ent:FireBullets( bullet )
				ent:EmitSound(Sound( "Weapon_Glock.Single" ))

				local effectdata = EffectData()
				effectdata:SetOrigin(bullet.Src)
				effectdata:SetStart(bullet.Src)
				effectdata:SetAngles(ang)

				util.Effect( "MuzzleEffect", effectdata )

				data.NextShoot = CurTime() + math.random(0.3, 0.6)
			end
		elseif poi then
			ent.loco:FaceTowards(poi.pos)
		--[[elseif poi and poi.level >= 0.2 and poi.pos:Distance(ent:GetPos()) > 400 then
			self:StartMovingTo(data, ent, {
				pos = poi.pos,
				run = true
			})]]
		end

		return 0
	end,
	Think = function(self, data, ent)
		local stat, err = pcall(function()
			local poi
			if ent.DistractionHistory then
				local hist = ent.DistractionHistory
				hist = FilterSeq(hist, function(v) return (CurTime() - v.happened) < 10 end)
				hist = GroupSeq(hist, function(v) return v.data.cause end)

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

				for groupname,group in pairs(flattened) do
					if group.level > 0 and (not poi or group.level > poi.level) then
						poi = {pos = group.pos, level = group.level}
					end
				end
			end

			if ent:GetDistractionLevel() >= 1 then
				return self:AlarmedMode(data, ent, poi)
			end
			local spot_callback = function(data)
				data.guard = ent
				hook.Call("BDGuardSpotted", GAMEMODE, data)
			end

			self:SpotPosition(ent, spot_callback)

			if data.type == "roaming" and (not data.NextRoam or data.NextRoam < CurTime()) then
				self:StartMovingTo(data, ent, {
					pos = table.Random(ents.FindByClass("bd_npc_poi")):GetPos(),
					run = false,
					spot_callback = spot_callback
				})

				data.NextRoam = CurTime() + math.random(2, 15)
			end

			if poi and poi.level >= 0.25 then
				ent.loco:FaceTowards(poi.pos)
				--debugoverlay.Sphere(poi.pos, 16, 1)
			end

			--data.IdleSequence = data.IdleSequence or ("LineIdle0" .. math.random(1, 2))
			--ent:SetSequence(data.IdleSequence)

			ent:StartActivity(ACT_IDLE)

			return 0
		end)
		if not stat then MsgN(err) end
		return CurTime() + (stat and err or 0)
	end
}

for _,npc in pairs(ents.FindByClass("bd_ai_base")) do
	npc.Brain = brain_generic
end

local function SpawnMapNPCs()
	local spawner_ents = ents.FindByClass("bd_npc_spawn")

	for _,spawner in pairs(spawner_ents) do
		local t = spawner:GetGuardType()

		local npc = ents.Create("bd_ai_base")
		npc:SetPos(spawner:GetPos())
		npc:SetAngles(spawner:GetAngles())

		npc:SetBrain(brain_generic)
		npc.BrainData.type = t

		npc:Activate()
		npc:Spawn()

		npc:AddFlashlight()
	end
end

hook.Add("BDRoundStateChanged", "SpawnMapNPCs", function(old_state, state)
	if state == "active" then
		SpawnMapNPCs()
	end
end)