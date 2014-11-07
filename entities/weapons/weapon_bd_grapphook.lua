
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
	if CLIENT then
		MsgN("?")
		local ply = self.Owner

		local c_Model = ents.CreateClientProp()
		c_Model:SetPos( ply:GetPos() + Vector(0, 0, 100))
		c_Model:SetModel( "models/props_borealis/bluebarrel001.mdl" )
		c_Model:Spawn()
	end
end