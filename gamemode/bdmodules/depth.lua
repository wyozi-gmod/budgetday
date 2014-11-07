local matNightVision = Material("effects/nightvision") -- CSS nightvision
matNightVision:SetFloat( "$alpha", 1 )

local tab = {
    [ "$pp_colour_addr" ] = 0,
    [ "$pp_colour_addg" ] = 0.05,
    [ "$pp_colour_addb" ] = 0,
    [ "$pp_colour_brightness" ] = 0,
    [ "$pp_colour_contrast" ] = 1,
    [ "$pp_colour_colour" ] = 1,
    [ "$pp_colour_mulr" ] = 0,
    [ "$pp_colour_mulg" ] = 2,
    [ "$pp_colour_mulb" ] = 0
}


hook.Add("RenderScreenspaceEffects", "Wyozi_NightVision", function()
    --[[for i=1,3 do
        render.UpdateScreenEffectTexture()
        render.SetMaterial( matNightVision )
        render.DrawScreenQuad()
    end

    DrawColorModify(tab)]]
end)


hook.Add("HUDPaint", "BDDepth", function()
	--[[
	mat_ColorMod:SetTexture( "$fbtexture", render.GetResolvedFullFrameDepth( ) )

	local tab = {
		[ "$pp_colour_addr" ] = 0.1, 
		[ "$pp_colour_addg" ] = 0, 
		[ "$pp_colour_addb" ] = 0, 
		[ "$pp_colour_brightness" ] = 0, 
		[ "$pp_colour_contrast" ] = 1, 
		[ "$pp_colour_colour" ] = 0, 
		[ "$pp_colour_mulr" ] = 0, 
		[ "$pp_colour_mulg" ] = 0, 
		[ "$pp_colour_mulb" ] = 0
	}

	for k, v in pairs( tab ) do
		mat_ColorMod:SetFloat( k, v )
	end

	render.SetBlend(0.1)
	render.SetMaterial(mat_ColorMod)
	render.DrawScreenQuad()
	render.SetBlend(1)]]
end)