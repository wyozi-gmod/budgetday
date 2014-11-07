
AddCSLuaFile()

SWEP.HoldType			= "pistol"

SWEP.PrintName = "Grappling Hook"

SWEP.Base = "weapon_bdbase"
SWEP.Primary.Recoil	= 1.35
SWEP.Primary.Damage = 28
SWEP.Primary.Delay = 0.38
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 20
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 20
SWEP.Primary.ClipMax = 80
SWEP.Primary.Ammo = "Pistol"

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel			= "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.WorldModel			= "models/weapons/w_pist_usp.mdl"

SWEP.Primary.Sound = Sound( "weapons/usp/usp1.wav" )
SWEP.Primary.SoundLevel = 50

SWEP.IronSightsPos = Vector( -5.91, -4, 2.84 )
SWEP.IronSightsAng = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim = ACT_VM_RELOAD_SILENCED

function SWEP:PrimaryAttack()
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

		self:SetNextPrimaryFire(CurTime() + 10)
	end
end