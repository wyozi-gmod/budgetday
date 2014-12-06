AddCSLuaFile()

if CLIENT then
    SWEP.DrawCrosshair   = false
    SWEP.ViewModelFOV    = 82
    SWEP.ViewModelFlip   = true
    SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "weapon_base"

SWEP.Primary.Sound          = Sound( "Weapon_Pistol.Empty" )
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

-- crosshair
if CLIENT then
    local sights_opacity = CreateConVar("ttt_ironsights_crosshair_opacity", "0.8", FCVAR_ARCHIVE)
    local crosshair_brightness = CreateConVar("ttt_crosshair_brightness", "1.0", FCVAR_ARCHIVE)
    local crosshair_size = CreateConVar("ttt_crosshair_size", "1.0", FCVAR_ARCHIVE)
    local disable_crosshair = CreateConVar("ttt_disable_crosshair", "0", FCVAR_ARCHIVE)


    function SWEP:DrawHUD()
        local sights = false

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        local scale = math.max(0.2,  10 * self:GetPrimaryCone())

        surface.SetDrawColor(255, 255, 255)

        local gap = 20 * scale * (sights and 0.8 or 1)
        local length = gap + (25 * crosshair_size:GetFloat()) * scale
        surface.DrawLine( x - length, y, x - gap, y )
        surface.DrawLine( x + length, y, x + gap, y )
        surface.DrawLine( x, y - length, x, y - gap )
        surface.DrawLine( x, y + length, x, y + gap )
    end
end

function SWEP:PrimaryAttack(worldsnd)

    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

    if not self:CanPrimaryAttack() then return end

    self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )

    self:ShootBullet( self.Primary.Damage, self.Primary.NumShots, self:GetPrimaryCone() )

    self:TakePrimaryAmmo( 1 )

    local owner = self.Owner
    if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end

    owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
end

function SWEP:DryFire(setnext)
    if CLIENT and LocalPlayer() == self.Owner then
        self:EmitSound( "Weapon_Pistol.Empty" )
    end

    setnext(self, CurTime() + 0.2)

    self:Reload()
end

function SWEP:CanPrimaryAttack()
    if not IsValid(self.Owner) then return end

    if self:Clip1() <= 0 then
        self:DryFire(self.SetNextPrimaryFire)
        return false
    end
    return true
end

function SWEP:CanSecondaryAttack()
    if not IsValid(self.Owner) then return end

    if self:Clip2() <= 0 then
        self:DryFire(self.SetNextSecondaryFire)
        return false
    end
    return true
end

function SWEP:GetPrimaryCone()
    local cone = self.Primary.Cone or 0.2
    -- 10% accuracy bonus when sighting
    return self:GetIronsights() and (cone * 0.85) or cone
end

function SWEP:DrawWeaponSelection() end

function SWEP:SecondaryAttack()
    if self.NoSights or (not self.IronSightsPos) then return end
    --if self:GetNextSecondaryFire() > CurTime() then return end

    self:SetIronsights(not self:GetIronsights())

    self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Deploy()
    self:SetIronsights(false)
    return true
end

function SWEP:Reload()
    if ( self:Clip1() == self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then return end
    self:DefaultReload(self.ReloadAnim)
    self:SetIronsights( false )
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

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 3, "Ironsights")
end

function SWEP:Initialize()
    if CLIENT and self:Clip1() == -1 then
        self:SetClip1(self.Primary.DefaultClip)
    elseif SERVER then
        self:SetIronsights(false)
    end

    local kek = function() end

    self:SetDeploySpeed(self.DeploySpeed)

    self:SetWeaponHoldType(self.HoldType or "pistol")
end

function SWEP:Think()
end

local IRONSIGHT_TIME = 0.25
function SWEP:GetViewModelPosition( pos, ang )
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

    local fIronTime = self.fIronTime or 0
    if (not bIron) and fIronTime < CurTime() - IRONSIGHT_TIME then
        return pos, ang
    end

    local mul = 1.0

    if fIronTime > CurTime() - IRONSIGHT_TIME then

        mul = math.Clamp( (CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1 )

        if not bIron then mul = 1 - mul end
    end

    local offset = self.IronSightsPos

    if self.IronSightsAng then
        ang = ang * 1
        ang:RotateAroundAxis( ang:Right(),    self.IronSightsAng.x * mul )
        ang:RotateAroundAxis( ang:Up(),       self.IronSightsAng.y * mul )
        ang:RotateAroundAxis( ang:Forward(),  self.IronSightsAng.z * mul )
    end

    pos = pos + offset.x * ang:Right() * mul
    pos = pos + offset.y * ang:Forward() * mul
    pos = pos + offset.z * ang:Up() * mul

    return pos, ang
end
