hook.Add("HUDPaint", "BDDrawObjective", function()
	local obj = GetGlobalEntity("Objective")

	draw.SimpleText(IsValid(obj) and obj:GetDescription() or "No Objective", "DermaLarge", ScrW()/2, ScrH()-200, Color(255, 255, 255), TEXT_ALIGN_CENTER)

	for i=1,3 do
		local sec_obj = GetGlobalEntity("SecondaryObjective" .. i)
		draw.SimpleText(IsValid(sec_obj) and sec_obj:GetDescription() or "No Secondary Objective", "DermaDefaultBold", ScrW()/2, ScrH()-185 + i*25, Color(200, 200, 200), TEXT_ALIGN_CENTER)
	end
end)