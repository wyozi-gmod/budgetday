
AddCSLuaFile()

SWEP.PrintName = "Silenced USP"

SWEP.Base = "weapon_bdbase"
SWEP.Primary.Recoil	= 0.7
SWEP.Primary.Damage = 28
SWEP.Primary.Delay = 0.38
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 20
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 20
SWEP.Primary.ClipMax = 80
SWEP.Primary.Ammo = "Pistol"

SWEP.ViewModelFlip		= true
SWEP.ViewModelFOV		= 70
SWEP.ViewModel			= "models/weapons/v_pist_usp.mdl"
SWEP.WorldModel			= "models/weapons/w_pist_usp.mdl"

SWEP.Primary.Sound = Sound("weapons/usp/usp1.wav")
SWEP.Primary.SoundLevel = 50

SWEP.IronSightsPos = Vector(4.1, -4, 2.8 )
SWEP.IronSightsAng = Vector(-1.2, -3.4, 0)

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim = ACT_VM_RELOAD_SILENCED

SWEP.CasualHoldType = "normal"
SWEP.HoldType = "pistol"
SWEP.SightHoldType = "revolver"

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
    return true
end
