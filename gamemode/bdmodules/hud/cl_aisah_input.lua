local MODULE = bd.module("aisah")

function MODULE.Meta:RegisterInput(key, desc, fn)
	self.RegisteredInputs = self.RegisteredInputs or {}
	self.RegisteredInputs[key] = {fn=fn, desc=desc}
end
function MODULE.Meta:RegisterBind(bind, desc, fn)
	self.RegisteredBindInputs = self.RegisteredBindInputs or {}
	self.RegisteredBindInputs[bind] = {fn=fn, desc=desc}
end

local keymap = {}
for name,val in pairs(_G) do
	if name:StartWith("KEY_") then
		local nname = name:sub(5)
		keymap[nname] = val
	end
end

local keyhistory = {}

hook.Add("Think", "BD_HandleAISAHInput", function()
	if not LocalPlayer():BD_GetBool("wear_aisah") then return end

	local keys = {}
	if input.IsControlDown() then table.insert(keys, "CTRL") end
	if input.IsShiftDown() then table.insert(keys, "SHIFT") end

	for keyname,keyval in pairs(keymap) do
		local isdown = input.IsKeyDown(keyval)
		if isdown and not keyhistory[keyval] then
			table.insert(keys, keyname)
		end
		keyhistory[keyval] = isdown
	end

	local inputstr = table.concat(keys, " ")

	local mod = bd.aisah.FindModule(function(mod)
		return mod.RegisteredInputs and mod.RegisteredInputs[inputstr] and mod:Has(LocalPlayer())
	end)
	if mod then
		mod.RegisteredInputs[inputstr].fn()
	end
end)

-- Handle input
hook.Add("PlayerBindPress", "BD_AISAH", function(ply, bind, pressed)
	if not LocalPlayer():BD_GetBool("wear_aisah") then return end

	if pressed then
		local mod = bd.aisah.FindModule(function(mod)
			return mod.RegisteredBindInputs and mod.RegisteredBindInputs[bind] and mod:Has(LocalPlayer())
		end)
		if mod then
			mod.RegisteredBindInputs[bind].fn()
			return true
		end
	end
end)