AddCSLuaFile()

SWEP.PrintName = "AISAH"
SWEP.Slot = 0
SWEP.SlotPos = 1

SWEP.ViewModelFOV	= 58

SWEP.ViewModel		= "models/weapons/v_binocular5.mdl"
SWEP.WorldModel		= "models/weapons/w_binoculars.mdl"
SWEP.HoldType			= "normal"

SWEP.Primary.Delay = 2

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	self:SetHoldType("camera")
	self.PlaceStarted = CurTime()

	if SERVER then
		timer.Simple(0.5, function()
			if IsValid(self) and IsValid(self.Owner) then
				self:Remove()
				self.Owner:BD_SetBool("wear_aisah", true)

				self.Owner:SendLua("resource.PlaySound('HL1/fvox/bell.wav')")
			end
		end)
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:Think()
	if CLIENT and self.PlaceStarted then
		local frac = (CurTime() - self.PlaceStarted) / 0.5
		self.ViewModelFOV = 58-(frac^4)*20
	end
end

if CLIENT then


	function SWEP:GetWorldPos()
		if not IsValid(self.Owner) then return end

		local BoneIndx = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
	    local BonePos , BoneAng = self.Owner:GetBonePosition( BoneIndx )

		local pos = BonePos
		local ang = BoneAng

		ang:RotateAroundAxis(ang:Right(), 90)

		pos = pos + ang:Up() * -4.5 + ang:Right() * 4

		return pos, ang
	end

	function SWEP:DrawWorldModel()
		--if self.Owner == LocalPlayer() then return end -- We don't want two detonators in viewmodel. TODO breaks thirdperson (matters?)

	    local pos, ang = self:GetWorldPos()
	    if not pos or not ang then return end

		self:SetRenderOrigin(pos)
		self:SetRenderAngles(ang)
		self:SetModelScale(0.7, 0)
		self:SetupBones()
		self:DrawModel()
	end
end