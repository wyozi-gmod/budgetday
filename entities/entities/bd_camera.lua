AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_assault/camera.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CameraName")
end

function ENT:KeyValue( key, value )
	if (self:SetNetworkKeyValue(key, value)) then
		return
	end
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
	end
end

function ENT:GetCameraPosAng()
	local pos, ang = self:GetPos(), self:GetAngles()
	pos = pos + ang:Forward()*10 - ang:Right()*50
	ang:RotateAroundAxis(ang:Right(), -25)
	ang:RotateAroundAxis(ang:Up(), 15)
	return pos, ang
end

if CLIENT then

	hook.Add("PostRenderVGUI", "WMC_DrawCamRT", function()
		local cameras = ents.FindByClass("bd_camera")
		for _,acam in pairs(cameras) do
			local owner = acam:GetOwner()

			acam.rt = acam.rt or GetRenderTarget("BDCamRT" .. acam:EntIndex(), 256, 256)

			render.PushRenderTarget( acam.rt )

				render.Clear( 0, 0, 0, 255, true )

					local CamData = {}
					local pos, ang = acam:GetCameraPosAng()
					CamData.angles = ang
					CamData.origin = pos
					CamData.x = 0
					CamData.y = 0
					CamData.w = 300
					CamData.h = 256
					CamData.fov = 80
					CamData.drawviewmodel = false
					CamData.drawhud = false

					cam.Start2D()
						render.RenderView(CamData)
					cam.End2D()

			render.PopRenderTarget()
		end
	end)
end