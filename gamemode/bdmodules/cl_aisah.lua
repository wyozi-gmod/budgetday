-- Artificially Improved Sight And HUD

bd.AISAHModules = {}

local module_meta = {
	RegisterInput = function(self, numkey, fn)
		self.RegisteredInputs = self.RegisteredInputs or {}
		self.RegisteredInputs[numkey] = fn
	end
}
module_meta.__index = module_meta

function bd.RegisterAISAHModule(name, mod)
	setmetatable(mod, module_meta)
	bd.AISAHModules[name] = mod

	mod:Setup()
end

function bd.FindAISAHModule(filter)
	for _,mod in pairs(bd.AISAHModules) do
		if filter(mod) then return mod end
	end
end

-- HUD Draw

local hud_colors = {
	default = Color(200, 200, 200, 160),
	info = Color(200, 200, 200, 120),

	bar = Color(255, 255, 0),

	state_on = Color(0, 170, 0, 120),
	state_off = Color(170, 0, 0, 120)
}

local function DrawHUDComponent(data)
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

			if ind.title then
				local tw, th = draw.SimpleText(ind.title, "Trebuchet18", ind_x, ind_y, hud_colors.info)

				ind_x = ind_x + tw + 5
			end

			if ind.slider_frac then
				local slider_w = ind.slider_width or 100

				surface.SetDrawColorAlpha(LerpColor(ind.slider_frac, hud_colors.state_off, hud_colors.state_on), 170)
				surface.DrawRect(ind_x, ind_y, slider_w * ind.slider_frac, 17)

				surface.SetDrawColorAlpha(hud_colors.default, 30)
				surface.DrawOutlinedRect(ind_x, ind_y, slider_w, 17)

				ind_x = ind_x + slider_w + 10
			end

			if ind.bars then
				for i=0,ind.bars.max do

					if ind.bars.count > i then
						surface.SetDrawColorAlpha(hud_colors.bar, 140)
						surface.DrawRect(ind_x, ind_y, 4, 17)
					end

					surface.SetDrawColorAlpha(hud_colors.default, 30)
					surface.DrawOutlinedRect(ind_x, ind_y, 4, 17)

					ind_x = ind_x + 5
				end

				ind_x = ind_x + 8
			end

			if ind.text then
				local tw, th = draw.SimpleText(ind.text, "Trebuchet18", ind_x, ind_y, ind.textcolor or hud_colors.info)

				ind_x = ind_x + tw + 5
			end
		end
	end
end

local function DrawHUD()
	if not LocalPlayer():BD_GetBool("wear_aisah") then return end

	local x,y = 20, 100

	for _,mod in pairs(bd.AISAHModules) do
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
		local mod = bd.FindAISAHModule(function(mod)
			return mod.RegisteredInputs and mod.RegisteredInputs[slot_idx] and mod:Has(LocalPlayer())
		end)
		if mod then
			mod.RegisteredInputs[slot_idx]()
			return true
		end
	end
end)