local SKILL = {}

function SKILL:RegisterVariables(ply)
	ply:BD_RegisterVar("nv_level", "Int", 0, function(x) return x >= 0 and x <= 4 end)
end

function SKILL:UnRegisterVariables(ply)
end

skills.RegisterModule("aisah_nightvision", SKILL)

if CLIENT then
	-- CSS nightvision
	local mat_nightVision = Material("effects/nightvision")
	mat_nightVision:SetFloat( "$alpha", 1 )

	local colormod = {
	    ["$pp_colour_addr"] = 0,
	    ["$pp_colour_addg"] = 0.05,
	    ["$pp_colour_addb"] = 0,
	    ["$pp_colour_brightness"] = 0,
	    ["$pp_colour_contrast"] = 1,
	    ["$pp_colour_colour"] = 1,
	    ["$pp_colour_mulr"] = 0,
	    ["$pp_colour_mulg"] = 1,
	    ["$pp_colour_mulb"] = 0
	}

	local function DrawNightVision(strength)
	    if strength and strength <= 0 then return end
	    if BD_RENDERING_RTWORLD then return end

		strength = math.Clamp(strength or 3, 1, 3)
		for i=1,strength do
	        render.UpdateScreenEffectTexture()
	        render.SetMaterial( mat_nightVision )
	        render.DrawScreenQuad()
	    end

	    colormod["$pp_colour_addg"] = 0.02 + 0.01 * strength
	    colormod["$pp_colour_mulg"] = strength

	    DrawColorModify(colormod)
	end

	hook.Add("RenderScreenspaceEffects", "BD_AISAH_NightVision", function()
	    if not LocalPlayer():BD_GetBool("wear_aisah") or not LocalPlayer():HasSkill("aisah_nightvision") then return end

	    local lvl = LocalPlayer():BD_GetInt("nv_level", 0)
	    DrawNightVision(lvl)
	end)

	local MOD = {}

	local icon_contrast = Material("icon16/contrast.png")

	function MOD:Has(ply)
	    return ply:HasSkill("aisah_nightvision")
	end

	function MOD:Setup()
	    self:RegisterInput(1, function()
	        LocalPlayer():BD_SetInt("nv_level", (LocalPlayer():BD_GetInt("nv_level", 0) + 1) % 4)
	    end)
	end

	function MOD:HUDData(data)
	    data.title = "Nightvision"
	    data.state = LocalPlayer():BD_GetInt("nv_level", 0) > 0
	    data.statekey = "(Shift + 1 to modify)"
	    data.indicators = {
	        {icon = icon_contrast, slider_frac = LocalPlayer():BD_GetInt("nv_level", 0)*0.33}
	    }
	end

	aisah.RegisterModule("nightvision", MOD)
end