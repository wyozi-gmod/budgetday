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
    		table.insert(highlight_objs, {clr=Color(0, 0, 255), ent=obj, ignore_z = (hlt == 2)})
    	end
    end

    local activeobj = GetGlobalEntity("Objective")
    if IsValid(activeobj) then
        local hlent = activeobj:GetHighlightEntity()

        if IsValid(hlent) then
            table.insert(highlight_objs, {clr=Color(0, 127, 0), ent=hlent, ignore_z = true})
        end

        local pos = activeobj:GetPos()
        local txt = activeobj:GetOverlayText()

        if txt and txt ~= "" then

            txt = txt:Replace("{objectiveitems}", tostring(activeobj:GetObjectiveItemsPicked()))
            txt = txt:Replace("{objectiveitemsreq}", tostring(activeobj:GetObjectiveItemRequirement()))

            local ang = LocalPlayer():EyeAngles()
            ang:RotateAroundAxis(ang:Forward(), 90)
            ang:RotateAroundAxis(ang:Right(), 90)
            cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.2)
                draw.DrawText(txt, "DermaLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end

    if #highlight_objs > 0 then
        render.SuppressEngineLighting(true)

        for _,obj in pairs(highlight_objs) do
        	cam.IgnoreZ(obj.ignore_z)
        	render.SetColorModulation(obj.clr.r/255, obj.clr.g/255, obj.clr.b/255)
        	obj.ent:DrawModel()
        end

        render.SuppressEngineLighting(false)
        cam.IgnoreZ(false)
        render.SetColorModulation(1, 1, 1)
    end
end)