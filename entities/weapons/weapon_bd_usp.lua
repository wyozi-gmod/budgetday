
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

SWEP.ViewModelFlip		= false
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

function SWEP:PostDrawViewModel(vm)
    local pos, ang = vm:GetPos(), vm:GetAngles()

    pos = pos + ang:Forward() * 13 - ang:Right() * 4.2 - ang:Up() * 3

    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 10 * (1 - (self.IronSightFraction or 0)))
    ang:RotateAroundAxis(ang:Up(), 15 * (1 - (self.IronSightFraction or 0)))

    cam.Start3D2D(pos, ang, 0.04)
        surface.SetDrawColor(180, 180, 180, 20)
        surface.DrawOutlinedRect(0, 0, 90, 40)

        draw.SimpleText(string.format("%d / %d", self:Clip1(), self.Owner:GetAmmoCount(self.Primary.Ammo)), "DermaDefaultBold", 5, 5)
    cam.End3D2D()
end
