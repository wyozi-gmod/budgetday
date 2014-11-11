hook.Add("HUDPaint", "BDDrawObjective", function()
	local obj = GetGlobalEntity("Objective")

	draw.SimpleText(IsValid(obj) and obj:GetDescription() or "No Objective", "DermaLarge", ScrW()/2, ScrH()-200, Color(255, 255, 255), TEXT_ALIGN_CENTER)

	for i=1,3 do
		local sec_obj = GetGlobalEntity("SecondaryObjective" .. i)
		draw.SimpleText(IsValid(sec_obj) and sec_obj:GetDescription() or "No Secondary Objective", "DermaDefaultBold", ScrW()/2, ScrH()-185 + i*25, Color(200, 200, 200), TEXT_ALIGN_CENTER)
	end
end)

hook.Add("PostDrawOpaqueRenderables", "BDHighlightObjectives", function()
	local ply = LocalPlayer()

	local highlight_objs = {}
    for _,obj in pairs(ents.FindByClass("bd_objective_item")) do
    	local hlt = obj:GetHighlightItemType()
    	if hlt > 0 then
    		table.insert(highlight_objs, {ent=obj, ignore_z = hlt == 2})
    	end
    end

    if #highlight_objs == 0 then return end

    render.SuppressEngineLighting(true)

    for _,obj in pairs(highlight_objs) do
    	cam.IgnoreZ(obj.ignore_z)
    	render.SetColorModulation(0, 0, 1)
    	obj.ent:DrawModel()
    end

    render.SuppressEngineLighting(false)
    cam.IgnoreZ(false)
    render.SetColorModulation(1, 1, 1)
end)