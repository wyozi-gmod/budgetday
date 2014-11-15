
-- We handle falldamage in the following function
function GM:GetFallDamage(ply, speed)
	return 1
end

function GM:OnPlayerHitGround(ply, in_water, on_floater, speed)
	if in_water or speed < 350 or not IsValid(ply) then return end

	-- thanks TTT
	local damage = math.pow(0.05 * (speed - 320), 1.9)

	if math.floor(damage) > 0 then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_FALL)
		dmg:SetAttacker(game.GetWorld())
		dmg:SetInflictor(game.GetWorld())
		dmg:SetDamageForce(Vector(0,0,1))
		dmg:SetDamage(damage)
		ply:TakeDamageInfo(dmg)

		ply:EmitSound("physics/body/body_medium_impact_soft1.wav", _, _, math.Clamp(damage/100, 0, 1))
	end
end
local plymeta = FindMetaTable("Player")
function plymeta:SetSprintEnabled(b)
	if self.SprintEnabled == b then return end

	if b then
		self:SetRunSpeed(self.OldRunSpeed)
	else
		self.OldRunSpeed = self:GetRunSpeed()
		self:SetRunSpeed(self:GetWalkSpeed())
	end

	self.SprintEnabled = b
end

hook.Add("PlayerHurt", "BD_PlayerRegenReset", function(ply)
	ply.LastDamageTaken = CurTime()
end)
local time_per_healtick = 0.2
hook.Add("Think", "BD_PlayerRegen", function()
	for _,ply in pairs(player.GetAll()) do
		local heal_for = 0

		if ply.LastDamageTaken then
			local elapsed = (CurTime() - ply.LastDamageTaken)
			heal_for = (2^(elapsed*0.2)) * time_per_healtick
		end
		if ply:Health() < ply:GetMaxHealth() and (not ply.NextHeal or ply.NextHeal <= CurTime()) then
			ply:SetHealth(math.Clamp(ply:Health() + heal_for, 0, ply:GetMaxHealth()))
			ply.NextHeal = CurTime() + time_per_healtick
		end

		local staminadelta = (0.1 * FrameTime())
		if ply:KeyDown(IN_SPEED) then
			staminadelta = -(0.2 * FrameTime())
		end
		ply:SetNWFloat("stamina", math.Clamp((ply:GetNWFloat("stamina") or 0) + staminadelta, 0, 1))
		ply:SetSprintEnabled(ply:GetNWFloat("stamina") >= 0.1)
	end
end)
