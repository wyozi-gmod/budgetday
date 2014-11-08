AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/computer_monitor.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "ActiveCamera")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model)
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end
end

function ENT:Think()
	if SERVER then
		if not self.NextCameraSwap or self.NextCameraSwap <= CurTime() then
			local cam_cycle = ents.FindByClass("bd_camera")

			local nextcam = table.FindNext(cam_cycle, self:GetActiveCamera())
			self:SetActiveCamera(nextcam)
			self.NextCameraSwap = CurTime() + 4
		end
	end
end

-- We want access to active camera information from all around the map..
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

interactions.Register("cameramonitor_bug", {
	filter = function(ent, ply) return ent:GetClass() == "bd_camera_monitor" end,
	help = function(ent, ply) return "Bug" end,
	finish = function(ent, ply) end,
	cancel = function(ent, ply) end,
	length = function() return 5 end
})

if CLIENT then
	surface.CreateFont("BDCamMonospace", {
		font = "Consolas",
		size = 20,
		weight = 800
	})

	local mat_camRT = Material( "models/weapons/v_toolgun/screen_bg" )

	function ENT:Draw()
		self:DrawModel()

		local pos = self:GetPos()
		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		pos = pos + ang:Up() * 3.3
		pos = pos + ang:Right() * -24.6
		pos = pos + ang:Forward() * -10.4

		local hacker_color = Color(0, 255, 0)

		local w, h = 207, 158

		local active_cam = self:GetActiveCamera()

		local function DrawRT(cam, x, y, w, h)
			if IsValid(cam) and cam.rt then
				mat_camRT:SetTexture("$basetexture", cam.rt)

				surface.SetMaterial(mat_camRT)
				surface.SetDrawColor(255, 255, 255)
				surface.DrawTexturedRect(x, y, w, h)
			else
				surface.SetDrawColor(255, 255, 255)
				surface.DrawRect(x, y, w, h)
			end
		end

		local camstr = ""
		if IsValid(active_cam) then
			camstr = string.format("#%d: %s", active_cam:EntIndex(), active_cam:GetCameraName())
		end

		cam.Start3D2D(pos, ang, 0.1)

			surface.SetDrawColor(hacker_color)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(2, 2, w-4, h-4)

			DrawRT(active_cam, 6, 6, w-12, 90)

			draw.SimpleText(camstr, "BDCamMonospace", 6, 95, Color(0, 255, 0))

			surface.SetDrawColor(0, 0, 0)

			for i=1,4 do
				surface.DrawRect(6+((i-1)*50), 117, 45, 34)
			end

		cam.End3D2D()
	end
end