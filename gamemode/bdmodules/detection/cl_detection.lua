--- Handles drawing exclamation/question marks, that signify their suspicion level, on top of guards' heads.

surface.CreateFont("BDDetectionFont", {
	font = "Roboto",
	size = 120
})

hook.Add("PostDrawOpaqueRenderables", "BDDrawDetectionStatus", function()
	for _,guard in pairs(bd.util.GetGuards()) do
		local det = guard:GetNWFloat("Suspicion")
		local lastdet = guard.LastDetection

		local pos = (guard:GetPos() + Vector(0, 0, 95))

		local detc = math.Clamp(det, 0, 1)

		local clr = HSVToColor((det>=1) and 0 or 60, detc, 1)
		clr.a = detc*255

		local offset = Vector(0, 0, 79)
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.2)
			draw.DrawText((det>=1) and "!" or "?", "BDDetectionFont", 0, 0, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()

	    guard.LastDetection = det
	end
end)

local icon_phone = Material("icon16/phone_sound.png")

hook.Add("HUDPaint", "BD.DrawCallingPoliceStatus", function()
	for _,guard in pairs(bd.util.GetGuards()) do
		local cfh_start = guard:GetNWFloat("CallingForHelp")
		if cfh_start and cfh_start ~= 0 then
			local elapsed = CurTime() - cfh_start
			local ts = (guard:GetPos() + Vector(0, 0, 60)):ToScreen()

			if not guard.NextCallBeep or guard.NextCallBeep <= CurTime() then
				guard:EmitSound("npc/combine_gunship/ping_search.wav", 120)

				guard.NextCallBeep = CurTime() + 1
			end

			if ts.visible then
				surface.SetMaterial(icon_phone)
				surface.SetDrawColor(255, 127, 0)

				local size = 20 + math.cos(elapsed * 7)*6

				surface.DrawTexturedRect(ts.x-size/2, ts.y-size/2, size, size)
			end
		end
	end
end)
