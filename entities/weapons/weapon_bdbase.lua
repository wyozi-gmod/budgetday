AddCSLuaFile()

if CLIENT then
    SWEP.DrawCrosshair   = false
    SWEP.ViewModelFOV    = 82
    SWEP.ViewModelFlip   = true
    SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "weapon_base"

SWEP.Primary.Sound          = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Recoil         = 1.5
SWEP.Primary.Damage         = 1
SWEP.Primary.NumShots       = 1
SWEP.Primary.Cone           = 0.02
SWEP.Primary.Delay          = 0.15

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.ClipMax        = -1

SWEP.Secondary.ClipSize     = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.ClipMax      = -1

SWEP.DeploySpeed = 1.4

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.ReloadAnim = ACT_VM_RELOAD

SWEP.HoldType = "pistol"

-- crosshair
if CLIENT then
    function SWEP:DrawHUD()
        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        local scale = 10 * self:GetPrimaryCone()

        surface.SetDrawColor(255, 255, 255)

        local gap = 20 * scale
        local length = gap + (25 * 1.0) * 0.2
        surface.DrawLine(x - length, y, x - gap, y)
        surface.DrawLine(x + length, y, x + gap, y)
        surface.DrawLine(x, y - length, x, y - gap)
        surface.DrawLine(x, y + length, x, y + gap)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 3, "Ironsights")
end

function SWEP:Initialize()
    if CLIENT and self:Clip1() == -1 then
        self:SetClip1(self.Primary.DefaultClip)
    elseif SERVER then
        self:SetIronsights(false)
    end

    self:SetDeploySpeed(self.DeploySpeed)
end

function SWEP:Deploy()
    self:SetIronsights(false)
    return true
end

function SWEP:CanPrimaryAttack()
    if not IsValid(self.Owner) then return end

    if self:Clip1() <= 0 then
        self:DryFire(self.SetNextPrimaryFire)
        return false
    end
    return true
end

function SWEP:PrimaryAttack(worldsnd)

    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not self:CanPrimaryAttack() then return end

    self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)

    self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self:GetPrimaryCone())
    self:TakePrimaryAmmo(1)

    self.LastShot = CurTime()

    local owner = self.Owner
    if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end

    owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self:GetPrimaryRecoil(), math.Rand(-0.1,0.1) * self:GetPrimaryRecoil(), 0))
end

function SWEP:CanSecondaryAttack()
    if not IsValid(self.Owner) then return end

    if self:Clip2() <= 0 then
        self:DryFire(self.SetNextSecondaryFire)
        return false
    end
    return true
end

function SWEP:SecondaryAttack()
end

function SWEP:GetPrimaryCone()
    local cone = self.Primary.Cone or 0.2
    return cone * self:GetHoldTypeBasedAccuracy()
end
function SWEP:GetPrimaryRecoil()
    local recoil = self.Primary.Recoil or 0.15
    return recoil * self:GetHoldTypeBasedAccuracy()
end

function SWEP:DrawWeaponSelection() end

function SWEP:Reload()
    if (self:Clip1() == self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo) <= 0 ) then return end
    self:DefaultReload(self.ReloadAnim)
    self:SetIronsights(false)
end

function SWEP:DampenDrop()
    -- For some reason gmod drops guns on death at a speed of 400 units, which
    -- catapults them away from the body. Here we want people to actually be able
    -- to find a given corpse's weapon, so we override the velocity here and call
    -- this when dropping guns on death.
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocityInstantaneous(Vector(0,0,-75) + phys:GetVelocity() * 0.001)
        phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
    end
end

function SWEP:GetHoldTypeKey()
    -- If aiming w/ ironsights, use sightholdtype
    if self:GetIronsights() then
        return "sight"
    end

    -- If we just shot, use the normal hold type
    if self.LastShot and self.LastShot > CurTime() - 1 then
        return "normal"
    end

    return "casual"
end

function SWEP:GetHoldTypeBasedAccuracy()
    local ht_key = self:GetHoldTypeKey()
    if ht_key == "sight" then
        return 0.6
    elseif ht_key == "normal" then
        return 0.8
    end
    return 1.0
end

function SWEP:Think()
    if SERVER then
        -- Set ironsight
        if not self.NoSights and self.IronSightsPos then
            self:SetIronsights(self.Owner:KeyDown(IN_ATTACK2))
        end

        -- Figure out what holdtype we should use
        local ht_key = self:GetHoldTypeKey()

        local ht
        if ht_key == "sight" then
            ht = self.SightHoldType
        elseif ht_key == "casual" then
            ht = self.CasualHoldType
        end

        ht = ht or self.HoldType
        self:SetHoldType(ht)
    end
end

hook.Add("BDSetPlayerSpeed", "BD.ModSpeedBasedOnWeapon", function(ply, mod)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    local ht_key = wep:GetHoldTypeKey()
    if ht_key == "sight" then
        mod:Scale(0.6)
    elseif ht_key == "normal" then
        mod:Scale(0.8)
    end
end)

function SWEP:ShootBullet(damage, num_bullets, aimcone)
    local bullet = {}

    bullet.Num 	= num_bullets
    bullet.Src 	= self.Owner:GetShootPos() -- Source
    bullet.Dir 	= self.Owner:GetAimVector() -- Dir of bullet
    bullet.Spread 	= Vector(aimcone, aimcone, 0)	 -- Aim Cone
    bullet.Tracer	= 1 -- Show a tracer on every x bullets
    bullet.Force	= 1 -- Amount of force to give to phys objects
    bullet.Damage	= damage
    bullet.AmmoType = "Pistol"

    self.Owner:FireBullets(bullet)

    -- Shoot effects
    self:SendWeaponAnim(self.PrimaryAnim)
    self.Owner:MuzzleFlash()
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    -- Recoil
    if CLIENT then
        local recoil = self:GetPrimaryRecoil()

        local eyeang = self.Owner:EyeAngles()
        eyeang.pitch = eyeang.pitch - recoil
        self.Owner:SetEyeAngles(eyeang)
    end
end

function SWEP:DryFire(setnext)
    if CLIENT and LocalPlayer() == self.Owner then
        self:EmitSound("Weapon_Pistol.Empty")
    end

    setnext(self, CurTime() + 0.2)

    self:Reload()
end

local IRONSIGHT_TIME = 0.25
function SWEP:GetViewModelPosition(pos, ang)
    if not self.IronSightsPos then return pos, ang end

    local bIron = self:GetIronsights()

    if bIron ~= self.bLastIron then
        self.bLastIron = bIron
        self.fIronTime = CurTime()

        if bIron then
            self.SwayScale = 0.3
            self.BobScale = 0.1
        else
            self.SwayScale = 1.0
            self.BobScale = 1.0
        end
    end

    local target_fraction = bIron and 1.0 or 0.0
    self.IronSightFraction = math.Approach(self.IronSightFraction or 0, target_fraction, 4 * FrameTime())

    if self.IronSightFraction <= 0 then
        return pos, ang
    end

    local mul = self.IronSightFraction

    local offset = self.IronSightsPos

    if self.IronSightsAng then
        ang = ang * 1
        ang:RotateAroundAxis(ang:Right(),    self.IronSightsAng.x * mul)
        ang:RotateAroundAxis(ang:Up(),       self.IronSightsAng.y * mul)
        ang:RotateAroundAxis(ang:Forward(),  self.IronSightsAng.z * mul)
    end

    pos = pos + offset.x * ang:Right() * mul
    pos = pos + offset.y * ang:Forward() * mul
    pos = pos + offset.z * ang:Up() * mul

    return pos, ang
end
