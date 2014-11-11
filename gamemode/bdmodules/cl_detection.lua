hook.Add("HUDPaint", "BDTrackDetectionStatus", function()
	for _,guard in pairs(ents.FindByClass("bd_ai_base")) do
		local det = guard:GetNWFloat("Detection")
		local lastdet = guard.LastDetection

		local ts = (guard:GetPos() + Vector(0, 0, 80)):ToScreen()
	    draw.SimpleText(tostring(math.Round(det, 3)), "DermaDefaultBold", ts.x, ts.y, Color(255, 255, 255), TEXT_ALIGN_CENTER)

	    guard.LastDetection = det
	end
end)