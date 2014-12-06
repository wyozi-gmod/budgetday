
--[[
FALL DAMAGE
]]
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

--[[
PLAYER MOVE SPEED MODIFIERS
]]

local speed_modifier_meta = {}
speed_modifier_meta.__index = speed_modifier_meta

function speed_modifier_meta:Scale(mul)
	self.Speed = self.Speed * mul
end

hook.Add("Think", "BD.PlyMoveSpeed", function()
	local base_move_speed = 170

	for _,ply in pairs(player.GetAll()) do
		local speed_mod = {Speed = base_move_speed}
		setmetatable(speed_mod, speed_modifier_meta)

		hook.Call("BDSetPlayerSpeed", GAMEMODE, ply, speed_mod)

		ply:SetWalkSpeed(speed_mod.Speed)
		ply:SetRunSpeed(speed_mod.Speed)
	end
end)

--[[
SCALE MOVESPEED BASED ON STAMINA
]]
hook.Add("BDSetPlayerSpeed", "BD.SprintModifier", function(ply, speed)
	if ply:KeyDown(IN_SPEED) then
		local mul = 0.95 + 0.75*math.pow(ply:GetNWFloat("stamina"), 0.3)
		speed:Scale(mul)
	end
end)

--[[
STAMINA AND HEALTH REGEN

Health regen increases exponentially over time, where time is time since we last got hit

Stamina regen also increases linearly
]]
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
	end
end)
