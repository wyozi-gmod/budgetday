AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

-- NextBot related variables
ENT.Model = Model("models/Kleiner.mdl")

-- This is where things get dirty. NextBots have no concept of "hitgroups" like players and npcs do
-- That is why we have to use hitboxes and dmginfo:GetDamagePosition() to approximate the hitgroup.
--
-- This table should contain mappings from hitbox IDs to HITGROUP enums.
-- To keep things simple, it is assumed that hitbox group 0 is the correct group.
ENT.HitBoxToHitGroup = {
	[0] = HITGROUP_HEAD,
	[16] = HITGROUP_CHEST,
	[15] = HITGROUP_STOMACH,
	[5] = HITGROUP_RIGHTARM,
	[2] = HITGROUP_LEFTARM,
	[12] = HITGROUP_RIGHTLEG,
	[8] = HITGROUP_LEFTLEG
}

--- The activity to use for walking
ENT.WalkActivity = ACT_WALK

--- The activity to use for running
ENT.RunActivity = ACT_RUN

ENT.StartingHealth = 100
ENT.StartingArmor = {
	[HITGROUP_HEAD] = 0,
	[HITGROUP_CHEST] = 20,
	[HITGROUP_STOMACH] = 10,
	[HITGROUP_LEFTARM] = 5,
	[HITGROUP_RIGHTARM] = 5,
	[HITGROUP_LEFTLEG] = 5,
	[HITGROUP_RIGHTLEG] = 5,
	[HITGROUP_GEAR] = 0, --?
}

--- NextBot line of sight.
-- The line of sight forms a cone, where the apex is NextBot's head.
ENT.Sight = {
	distance = 768,
	angle = 60
}

--- Calls 'callback' parameter with ALL entities found inside the cone that can be constructed from parameters.
-- This method is also known as "this is what happens when you have to re-code Source engine functions that
-- are supposed to work"
function ENT:SpotEntities(pos, dir, sight_data, callback, ent)
	local required_dot = math.cos(math.rad(sight_data.angle))

	-- Okay, so ents.FindInCone is basically the most useless function in all Garry's Mod
	-- I don't even know what it does, but it definitely does not find entities in a cone
	-- (see https://github.com/Facepunch/garrysmod-issues/issues/1271)
	--
	-- A workaround:
	-- We turn the cone into an AABB, get all the entities inside it using the relatively fast
	-- ents.FindInBox function and only then do more sophisticated "isInsideCone" checks using
	-- dot product

	local dir_right = dir:Cross(Vector(0, 0, 1))
	local dir_up = dir_right:Cross(dir)

	--debugoverlay.Line(pos, pos+dir*100, 0.2, Color(255, 0, 0))
	--debugoverlay.Line(pos, pos+dir_right*100, 0.2, Color(0, 255, 0))
	--debugoverlay.Line(pos, pos+dir_up*100, 0.2, Color(0, 0, 255))

	local cone_radius = math.tan(math.rad(sight_data.angle)) * sight_data.distance

	-- I am terrible at math so this is the best I could come up with to turn a cone into an AABB
	-- Basically it approximates points in the base of the cone and keeps expanding box_mins and box_maxs
	-- to fit all of them inside it. This is not the most efficient way to do it (TODO?), but is pretty simple.

	local box_mins = Vector(9999999, 9999999, 9999999)
	local box_maxs = Vector(-9999999, -9999999, -9999999)

	local function CheckMinMax(v)
		box_mins.x = math.min(box_mins.x, v.x)
		box_mins.y = math.min(box_mins.y, v.y)
		box_mins.z = math.min(box_mins.z, v.z)

		box_maxs.x = math.max(box_maxs.x, v.x)
		box_maxs.y = math.max(box_maxs.y, v.y)
		box_maxs.z = math.max(box_maxs.z, v.z)
	end

	CheckMinMax(pos)

	local points = 16
	local rad_per_point = math.pi*2 / points
	for i=0,points do
		local endpos = pos + dir * sight_data.distance
		+ dir_right * math.cos(rad_per_point * i) * cone_radius
		+ dir_up * math.sin(rad_per_point * i) * cone_radius

		CheckMinMax(endpos)
	end

	--debugoverlay.Box(pos, box_mins-pos, box_maxs-pos, 0.2, Color(255, 255, 255, 1), false)

	for _,ent in pairs(ents.FindInBox(box_mins, box_maxs)) do
		if not ent:IsWorld() then
			local pos_diff = (bd.util.GetEntPosition(ent) - pos)
			local pos_diff_normal = pos_diff:GetNormalized()
			local dot = dir:Dot(pos_diff_normal)
			local dist = pos_diff:Length()

			if bd.util.ComputeLos(pos, ent) and dot >= required_dot and dist <= sight_data.distance then
				callback(ent)
			end
		end
	end
end

--- Returns a table containing entities that the NextBot is able to see.
-- Uses values from ENT.Sight to determine sight.
--
-- Also returns entities spotted in camera monitors etc
function ENT:ComputeLOSEntities(opts)
	local spotted_ents = {}

	-- Adds entity to the table that is returned from this method
	local function AddEntity(ent, data)
		if (opts and opts.filter and not opts.filter(ent, data)) then
			-- If entity has SightLink, it is only filtered if opts.filter_sightlinks is set
			if not ent.SightLink or (opts and opts.filter_sightlinks) then
				if opts and opts.debug then
					MsgN("[NextBot-Sight] Filtering out ", ent)
				end
				return
			end
		end
		if bd.util.Find(spotted_ents, function(tbl) return tbl.ent == ent end) then
			if opts and opts.debug then
				MsgN("[NextBot-Sight] Filtering out ", ent, " because it is already in spotted_ents")
			end
			return
		end

		table.insert(spotted_ents, {
			ent = ent,
			spotter = data.spotter
		})
	end

	local eyepos = self:EyePosN()
	local eyedir = self:GetAngles():Forward()

	-- First we list the entities that this NextBot is able to see
	self:SpotEntities(eyepos, eyedir, self.Sight, function(ent)
		AddEntity(ent, {spotter = self})
	end, self)

	-- Then we filter through entities and get the ones that have a SightLink variable
	local linked_ents = bd.util.FilterSeq(spotted_ents, function(tbl)
		return tbl.ent.SightLink ~= nil
	end)

	if opts and opts.debug then
		MsgN("[NextBot-Sight] Linked ents: ", table.ToString(linked_ents))
	end

	for _,linked in pairs(linked_ents) do
		-- Get the entities (eg. security cameras) we should check vision of
		local linked_vision_sources = linked.ent.SightLink.GetLinkedEntities(linked.ent, eyepos, eyedir)

		-- Go through vision source tables
		for _,source in pairs(linked_vision_sources or {}) do
			local ent = source.ent

			if not IsValid(ent) then
				ErrorNoHalt(string.format("Linked vision source for entity '%s' has invalid entity", linked.ent:GetClass()))
			elseif not ent.Sight then
				ErrorNoHalt(string.format("Linked vision source '%s' has no 'Sight'", ent:GetClass()))
			else
				self:SpotEntities(source.pos, source.ang:Forward(), ent.Sight, function(spotted_ent)
					AddEntity(spotted_ent, {spotter = ent})
				end, ent)
			end
		end
	end

	return spotted_ents
end

function ENT:GetSuspicionLevel()
	return self:GetNWFloat("Suspicion", 0) or 0
end
function ENT:SetSuspicionLevel(lvl)
	return self:SetNWFloat("Suspicion", lvl)
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)

		self:SetHealth(self.StartingHealth)
		self.Armor = table.Copy(self.StartingArmor)

		-- List of callbacks to call when equipping a pistol
		self.OnArm = {}
	end
end

-- So confusing
function ENT:EyePosN()
	local headbone = self:LookupBone("ValveBiped.Bip01_Head1")
	local headpos = self:GetBonePosition(headbone)
	return headpos
end

function ENT:AddFlashlight()
	local shootpos = self:GetAttachment(self:LookupAttachment("anim_attachment_LH"))

	local wep = ents.Create("bd_lamp")
	wep:SetModel(Model("models/maxofs2d/lamp_flashlight.mdl"))
	wep:SetOwner(self)

	wep:SetFlashlightTexture("effects/flashlight/soft")
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

	table.insert(self.OnArm, function() if IsValid(self.Flashlight) then self.Flashlight:Remove() end end)
end


-- hashtag coding priorities
function ENT:AddCoffeeCup()
	local shootpos = self:GetAttachment(self:LookupAttachment("anim_attachment_LH"))

	local prop = ents.Create("prop_physics")
	prop:SetModel(Model("models/props/cs_office/coffee_mug.mdl"))
	prop:SetOwner(self)

	prop:Spawn()

	prop:SetSolid(SOLID_NONE)
	prop:SetParent(self)

	prop:Fire("setparentattachment", "anim_attachment_LH")
	prop:SetLocalAngles(Angle(0, 90, 0))

	self.CoffeeCup = prop

	table.insert(self.OnArm, function()
		if IsValid(prop) then
			prop:SetParent(nil)

			prop:SetMoveType(MOVETYPE_VPHYSICS)
			prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			prop:SetSolid(SOLID_VPHYSICS)

			prop:SetPos(self:GetAttachment(self:LookupAttachment("anim_attachment_LH")).Pos)
		end
	end)
end


-- Weapon handling code modified version of
--  https://github.com/PresidentMattDamon/onslaughtgmod/blob/master/entities/entities/snpc_police/shared.lua

hook.Add("PlayerCanPickupWeapon", "BD.DontPickupNextbotWeapon", function(ply, ent)
	return not ent.DontPickUp
end)

function ENT:GiveWeapon(weaponcls)
	if not IsValid(self) then return end
	if self.Weapon then self.Weapon:Remove() end
	local att = "anim_attachment_RH"

	local shootpos = self:GetAttachment(self:LookupAttachment(att))
	local wep = ents.Create(weaponcls)

	wep:SetOwner(self)
	wep:SetPos(shootpos.Pos)
	wep:Spawn()

	wep.DontPickUp = true
	wep:SetSolid(SOLID_NONE)
	wep:SetParent(self)

	wep:Fire("setparentattachment", att)
	wep:AddEffects(EF_BONEMERGE)
	wep:SetAngles(self:GetForward():Angle())

	self.Weapon = wep

	for _,fn in pairs(self.OnArm) do fn() end
end

function ENT:GetActiveWeapon()
	return self.Weapon
end

function ENT:ShootWeapon()

end

function ENT:BehaveAct()

end
function ENT:MoveToPos( pos, options )
	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos )

	if ( not path:IsValid() ) then return "failed" end

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

-- This is the method you need to override
function ENT:BehaviourTick()
	self:StartActivity(ACT_IDLE)
end

function ENT:RunBehaviour()
	while ( true ) do
		local stat, err = pcall(function() self:BehaviourTick() end)

		if not stat then MsgN("NextBot error: ", err) end

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

function ENT:NotifyDistraction(data)
	self:SetSuspicionLevel(self:GetSuspicionLevel() + data.level)

	self.DistractionHistory = self.DistractionHistory or {}

	table.insert(self.DistractionHistory, {
		happened = CurTime(),
		data = data
	})

	hook.Call("BDNextbotDistraction", GAMEMODE, self, data)
end

-- Once again some nice code from TTT..
function ENT:BecomePhysicalRagdoll(dmginfo)

	local rag = ents.Create("prop_ragdoll")
	if not IsValid(rag) then return nil end

	rag:SetPos(self:GetPos())
	rag:SetModel(self:GetModel())
	rag:SetAngles(self:GetAngles())
	rag:Spawn()
	rag:Activate()

	-- nonsolid to players, but can be picked up and shot
	rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	-- position the bones
	local num = rag:GetPhysicsObjectCount()-1
	local v = self:GetVelocity()
	-- bullets have a lot of force, which feels better when shooting props,
	-- but makes bodies fly, so dampen that here
	if dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_SLASH) then
		v = v / 5
	end
	for i=0, num do
		local bone = rag:GetPhysicsObjectNum(i)
		if IsValid(bone) then
			local bp, ba = self:GetBonePosition(rag:TranslatePhysBoneToBone(i))
			if bp and ba then
				bone:SetPos(bp)
				bone:SetAngles(ba)
			end
			-- not sure if this will work:
			bone:SetVelocity(v)
		end
	end

end

function ENT:OnInjured(dmginfo)
	-- There is no good way to figure out hitgroups in nextbots.
	-- The hacky way we're going to do it is get hitbox bones, then get distance from
	--  the position the nextbot was shot at to the position of the bone, then return
	--  the hitgroup that has lowest distance. Not perfect but works

	local pos = dmginfo:GetDamagePosition()
	local hitgroup = 0

	local dist_to_hitgroups = {}
	for hitbox,hitgroup in pairs(self.HitBoxToHitGroup) do
		local bone = self:GetHitBoxBone(hitbox, 0)
		if bone then
			local bonepos, boneang = self:GetBonePosition(bone)

			table.insert(dist_to_hitgroups, {hitgroup = hitgroup, dist = pos:Distance(bonepos)})
		end
	end

	table.SortByMember(dist_to_hitgroups, "dist", true)

	hitgroup = dist_to_hitgroups[1].hitgroup

	hook.Call("BDScaleNextbotDamage", GAMEMODE, self, hitgroup, dmginfo)

	if dmginfo:IsBulletDamage() then
		self:NotifyDistraction({level = 1, pos = pos, cause = "hurt"})
	end
end

function ENT:OnKilled( dmginfo )
	self:BecomePhysicalRagdoll( dmginfo )
	self:Remove()
end
