AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/weapons/w_bugbait.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Priority", {KeyName = "priority"})
end

function ENT:KeyValue( key, value )
	if (self:SetNetworkKeyValue(key, value)) then
		return
	end
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:SetNoDraw(true)
		self:DrawShadow(false)
		self:SetSolid(SOLID_NONE)
		self:SetMoveType(MOVETYPE_NONE)
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
		local camera_monitors = ents.FindByClass("bd_camera_monitor")
		for _,monitor in pairs(camera_monitors) do
			local dist = monitor:GetPos():Distance(LocalPlayer():EyePos())
			if dist > 256 then continue end

			local acam = monitor:GetActiveCamera()
			if IsValid(acam) then
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
							BD_RENDERING_RTWORLD = true
							render.RenderView(CamData)
							BD_RENDERING_RTWORLD = false
						cam.End2D()

				render.PopRenderTarget()
			end
		end
	end)
end