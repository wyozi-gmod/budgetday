
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
SWEP.ViewModelFlip		= true
SWEP.ViewModelFOV		= 80
SWEP.ViewModel			= "models/weapons/v_snip_sg550.mdl"
SWEP.WorldModel			= "models/weapons/w_snip_sg550.mdl"

SWEP.Primary.Sound = Sound("weapons/usp/usp1.wav")
SWEP.Primary.SoundLevel = 50

SWEP.IronSightsPos = Vector(-5.91, -4, 2.84)
SWEP.IronSightsAng = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim = ACT_VM_RELOAD_SILENCED

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:EmitSound("weapons/grenade_launcher1.wav")

	if SERVER then
		local ply = self.Owner

		local physrope = ents.Create("bd_physrope")
		physrope:SetPos(ply:GetShootPos() + ply:GetAimVector()*50)
		self.PhysRope = physrope

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

function SWEP:SecondaryAttack()
	if SERVER and IsValid(self.PhysRope) then
		self.PhysRope:Remove()
		self:SetNextPrimaryFire(CurTime() + 1)
	end
end
