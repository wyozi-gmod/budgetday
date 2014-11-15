--- Handles drawing exclamation/question marks, that signify their suspicion level, on top of guards' heads.

surface.CreateFont("BDDetectionFont", {
	font = "Roboto",
	size = 120
})

hook.Add("PostDrawOpaqueRenderables", "BDDrawDetectionStatus", function()
	for _,guard in pairs(ents.FindByClass("bd_ai_base")) do
		local det = guard:GetNWFloat("Detection")
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