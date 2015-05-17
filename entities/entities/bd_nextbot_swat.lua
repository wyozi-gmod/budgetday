AddCSLuaFile()

ENT.Base = "bd_nextbotbase"

ENT.Model = Model("models/Combine_Soldier.mdl")

function ENT:GetEnemyOnSight()
	local los_ents = self:ComputeLOSEntities({
		filter = function(ent)
			return ent:IsPlayer()
		end
	})
	if #los_ents >= 1 then return los_ents[1].ent end
end

function ENT:StartMovingTo(pos)
	self.loco:SetAcceleration(200)
	self.loco:SetDesiredSpeed(200)
	self:StartActivity(ACT_RUN)
	self.loco:SetDeathDropHeight(40)

	return self:MoveToPos(pos, {
		terminate_condition = function()
			return IsValid(self:GetEnemyOnSight())
		end,
		repath = 1
	})
end

function ENT:BehaviourTick()
	if not self.IsArmed then
		self:GiveWeapon("weapon_ak47")
		self.IsArmed = true
	end

	local shoot_targ = self:GetEnemyOnSight()

	if IsValid(shoot_targ) then
		self:StartActivity(ACT_IDLE)

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
			bullet.Damage	= 15
			bullet.AmmoType = "Pistol"

			--debugoverlay.Line(bullet.Src, bullet.Src + bullet.Dir * 100, 2)

			self:FireBullets( bullet )
			self:EmitSound(Sound( "Weapon_AK47.Single" ))

			local effectdata = EffectData()
			effectdata:SetOrigin(bullet.Src)
			effectdata:SetStart(bullet.Src)
			effectdata:SetAngles(ang)

			util.Effect( "MuzzleEffect", effectdata )

			self.NextShoot = CurTime() + math.random(0.05, 0.1)
			self.Shots = (self.Shots or 0) + 1

			if self.Shots % 30 == 0 then
				self:PlaySequenceAndWait("Shoot_to_crouchsmg1")
				self:PlaySequenceAndWait("crouch_reload_smg1")
				self:PlaySequenceAndWait("crouch_to_shootsmg1")
			end
		end
	else
		local targ
		for _,p in pairs(player.GetAll()) do
			if p:Alive() then targ = p end
		end
		
		if IsValid(targ) then
			local x = self:StartMovingTo(targ:GetPos())
		end
	end
end
