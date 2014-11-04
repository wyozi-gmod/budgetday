-- Artificially Improved Sight And HUD

module("aisah", package.seeall)

-- Load modules

Modules = {}

local module_meta = {
	RegisterInput = function(self, numkey, fn)
		self.RegisteredInputs = self.RegisteredInputs or {}
		self.RegisteredInputs[numkey] = fn
	end
}
module_meta.__index = module_meta

function RegisterModule(name, mod)
	setmetatable(mod, module_meta)
	Modules[name] = mod

	mod:Setup()
end

function FindModule(filter)
	for _,mod in pairs(Modules) do
		if filter(mod) then return mod end
	end
end

-- HUD Draw

local hud_colors = {
	default = Color(200, 200, 200, 160),
	info = Color(200, 200, 200, 120),

	state_on = Color(0, 170, 0, 120),
	state_off = Color(170, 0, 0, 120)
}

function DrawHUDComponent(data)
	local state_clr = hud_colors.default
	if data.state ~= nil then
		state_clr = data.state and hud_colors.state_on or hud_colors.state_off
	end

	local x, y = data.x, data.y
	local w, h = 350, 50

	surface.SetDrawColor(state_clr)
	surface.DrawRect(x, y, 4, h)

	surface.SetDrawColor(80, 80, 80, 15)
	surface.DrawRect(x+4, y, w-4, h)

	local tw, th = draw.SimpleText(data.title, "Trebuchet24", x + 10, y+13, hud_colors.default, _, TEXT_ALIGN_CENTER)
	if data.statekey then
		draw.SimpleText(data.statekey, "Trebuchet18", x + w - 10, y+13+1, hud_colors.info, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	if data.indicators then
		local ind_x = x + 10
		local ind_y = y + 28

		for i=1,#data.indicators do
			local ind = data.indicators[i]

			if ind.icon then
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(ind.icon)
				surface.DrawTexturedRect(ind_x, ind_y+1, 16, 16)

				ind_x = ind_x + 20
			end

			if ind.slider_frac then
				local slider_w = ind.slider_width or 100

				surface.SetDrawColorAlpha(LerpColor(ind.slider_frac, hud_colors.state_off, hud_colors.state_on), 170)
				surface.DrawRect(ind_x, ind_y, slider_w * ind.slider_frac, 17)

				surface.SetDrawColorAlpha(hud_colors.default, 30)
				surface.DrawOutlinedRect(ind_x, ind_y, slider_w, 17)

				ind_x = ind_x + slider_w + 10
			end
		end
	end
end

function DrawHUD()
	if not LocalPlayer():BD_GetBool("wear_aisah") then return end

	local x,y = 20, 100

	for _,mod in pairs(Modules) do
		if mod:Has(LocalPlayer()) then
			local data = {x = x, y = y}
			mod:HUDData(data)

			DrawHUDComponent(data)
			y = y + 60
		end
	end
end

hook.Add("HUDPaint", "BD_AISAH", DrawHUD)

-- Handle input
hook.Add("PlayerBindPress", "BD_AISAH", function(ply, bind, pressed)
	if not input.IsShiftDown() then return end
	if not LocalPlayer():BD_GetBool("wear_aisah") then return end

	if bind:sub(1, 4) == "slot" and pressed then
		local slot_idx = tonumber(bind:sub(5))
		local mod = FindModule(function(mod)
			return mod.RegisteredInputs and mod.RegisteredInputs[slot_idx] and mod:Has(LocalPlayer())
		end)
		if mod then
			mod.RegisteredInputs[slot_idx]()
			return true
		end
	end
end)

-- Draw binoculars for every player who's wearing AISAH. Kindof hacky but meh
hook.Add("PostPlayerDraw", "BD_AISAH_DrawModel", function(ply)
	--[[local wearing = ply:Alive() and ply:BD_GetBool("wear_aisah")
	if not wearing and IsValid(ply.BD_AISAH_Model) then
		ply.BD_AISAH_Model:Remove()
	elseif wearing and not IsValid(ply.BD_AISAH_Model) then
		local m = ClientsideModel("models/weapons/w_binoculars.mdl", RENDERGROUP_OPAQUE)
		ply.BD_AISAH_Model = m
	end

	if IsValid(ply.BD_AISAH_Model) then
		local m = ply.BD_AISAH_Model

		local BoneIndx = ply:LookupBone("ValveBiped.Bip01_Head1")
	    local BonePos , BoneAng = ply:GetBonePosition( BoneIndx )

	    BoneAng:RotateAroundAxis(BoneAng:Right(), 90)
	    BoneAng:RotateAroundAxis(BoneAng:Up(), -90)

	    BonePos = BonePos + BoneAng:Forward() * 8 + BoneAng:Up() * -3

		m:SetRenderOrigin(BonePos)
		m:SetRenderAngles(BoneAng)
	end]]
end)