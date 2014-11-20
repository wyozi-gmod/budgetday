local MODULE = bd.module("aisah")

surface.CreateFont("BD_AISAH_Header", {
	font = "Consolas",
	size = 22,
	weight = 800
})
surface.CreateFont("BD_AISAH_Text", {
	font = "Roboto",
	size = 17
})
surface.CreateFont("BD_AISAH_Help", {
	font = "Trebuchet MS",
	size = 18
})

local hud_colors = {
	default = Color(200, 200, 200, 160),
	info = Color(200, 200, 200, 120),

	bar = Color(255, 255, 0),

	state_on = Color(30, 130, 76, 255),
	state_off = Color(217, 30, 24, 120)
}

function MODULE.Meta:DrawComponent(data)
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

	local tw, th = draw.SimpleText(data.title, "BD_AISAH_Header", x + 10, y+13, hud_colors.default, _, TEXT_ALIGN_CENTER)

	local helpstr = ""

	if self.RegisteredBindInputs then
		for bind,data in pairs(self.RegisteredBindInputs) do
			helpstr = helpstr .. string.format("(%s to %s)", (input.LookupBinding(bind) or ""):upper(), data.desc)
		end
	end

	draw.SimpleText(helpstr, "BD_AISAH_Help", x + w - 6, y+12, hud_colors.info, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	local ind_x = x + 10
	local ind_y = y + 28

	for i=1,#data.components do
		local ind = data.components[i]

		if ind.type == "text" then
			local tw, th = draw.SimpleText(ind.text, "BD_AISAH_Text", ind_x, ind_y, hud_colors.info)
			ind_x = ind_x + tw + 5
		elseif ind.type == "icon" then
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(ind.icon)
			surface.DrawTexturedRect(ind_x, ind_y+1, 16, 16)

			ind_x = ind_x + 20
		elseif ind.type == "slider" then
			local slider_w = ind.width or 100

			surface.SetDrawColorAlpha(LerpColor(ind.value, hud_colors.state_off, hud_colors.state_on), 170)
			surface.DrawRect(ind_x, ind_y, slider_w * ind.value, 17)

			surface.SetDrawColorAlpha(hud_colors.default, 30)
			surface.DrawOutlinedRect(ind_x, ind_y, slider_w, 17)

			ind_x = ind_x + slider_w + 10
		elseif ind.type == "bars" then
			for i=0,ind.max do

				if ind.value > i then
					surface.SetDrawColorAlpha(hud_colors.bar, 140)
					surface.DrawRect(ind_x, ind_y, 4, 17)
				end

				surface.SetDrawColorAlpha(hud_colors.default, 30)
				surface.DrawOutlinedRect(ind_x, ind_y, 4, 17)

				ind_x = ind_x + 5
			end

			ind_x = ind_x + 8
		end
	end
end

local comp_meta = {}
comp_meta.__index = comp_meta

comp_meta.text = function(self, text)
	table.insert(self, {type = "text", text = text})
end
comp_meta.icon = function(self, icon)
	table.insert(self, {type = "icon", icon = icon})
end
comp_meta.slider = function(self, value)
	table.insert(self, {type = "slider", value = value})
end
comp_meta.bars = function(self, value, max)
	table.insert(self, {type = "slider", value = value, max = max})
end

hook.Add("HUDPaint", "BD_AISAH", function()
	if not LocalPlayer():BD_GetBool("wear_aisah") then return end

	local x,y = 20, 100

	for _,mod in pairs(MODULE.AISAHModules) do
		if mod:Has(LocalPlayer()) then
			local data = {x = x, y = y, components = {}}
			setmetatable(data.components, comp_meta)

			mod:HUDData(data)
			mod:DrawComponent(data)

			y = y + 60
		end
	end
end)
