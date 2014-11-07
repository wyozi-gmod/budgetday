
AddCSLuaFile()

SWEP.HoldType			= "pistol"

SWEP.PrintName = "Grappling Hook"

SWEP.Base = "weapon_bdbase"
SWEP.Primary.Recoil	= 0
SWEP.Primary.Damage = 0
SWEP.Primary.Delay = 10
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 3
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = 3
SWEP.Primary.ClipMax = 3
SWEP.Primary.Ammo = "Grapp Hook"

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel			= "models/freeman/harpoongun.mdl"
SWEP.WorldModel			= "models/freeman/harpoongun.mdl"

SWEP.Primary.Sound = Sound( "weapons/usp/usp1.wav" )
SWEP.Primary.SoundLevel = 50

SWEP.IronSightsPos = Vector( -5.91, -4, 2.84 )
SWEP.IronSightsAng = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim = ACT_VM_RELOAD_SILENCED

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	if SERVER then
		local ply = self.Owner

		local physrope = ents.Create("bd_physrope")
		physrope:SetPos(ply:GetShootPos() + ply:GetAimVector()*50)

		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		physrope:SetAngles(ang)
		physrope:SetOwner(ply)
		physrope:Spawn()

		physrope:GetPhysicsObject():AddVelocity(ply:GetAimVector() * 1500)

		self:TakePrimaryAmmo(1)
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	end
end


if CLIENT then
	function SWEP:GetWorldPos()
		if not IsValid(self.Owner) then return end

		local BoneIndx = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
	    local BonePos , BoneAng = self.Owner:GetBonePosition( BoneIndx )

		local pos = BonePos
		local ang = BoneAng

		pos = pos + ang:Forward() * 21.5 + ang:Right() * 1.5

		ang:RotateAroundAxis(ang:Forward(), 180)

		return pos, ang
	end

	function SWEP:DrawWorldModel()
		--if self.Owner == LocalPlayer() then return end -- We don't want two detonators in viewmodel. TODO breaks thirdperson (matters?)

	    local pos, ang = self:GetWorldPos()
	    if not pos or not ang then self:DrawModel() return end

		self:SetRenderOrigin(pos)
		self:SetRenderAngles(ang)
		self:SetModelScale(1.2, 0)
		self:SetupBones()
		self:DrawModel()
	end

	function SWEP:GetViewModelPosition( pos, ang )
		pos = pos + ang:Up() * -4 + ang:Forward() * 25 + ang:Right() * 5
		return pos, ang
	end 
end