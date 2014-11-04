-- This file is a bunch of dirty work that eventually results in following methods in plymeta

-- ply:BD_GetInt()
-- ply:BD_GetString()
-- ply:BD_GetVector()
-- ply:BD_GetEntity()

local plymeta = FindMetaTable("Player")

local bdvar_types = {"Double", "Int", "Float", "String", "Vector", "Entity", "Bool"}

if SERVER then
	function plymeta:BD_RegisterVar(name, type, default, validator)
		if not table.HasValue(bdvar_types, type) then
			ErrorNoHalt("Attempting to register BDVar " .. name .. " of unknown type ".. type)
			return false, "Type not a bdvar_type!"
		end

		self.BD_Vars = self.BD_Vars or {}
		self.BD_Vars[name] = {default = default, type = type, validator = validator}
		
		if default then self:BD_SetVar(name, default) end
	end
end

-- Create getters
for _,bdvt in pairs(bdvar_types) do
	plymeta["BD_Get" .. bdvt] = function(p, n, def)
		local func = p["GetNW" .. bdvt]
		return func(p, "bdvar_" .. n) or def
	end
end

-- Create setters
for _,bdvt in pairs(bdvar_types) do
	if SERVER then
		plymeta["BD_Set" .. bdvt] = function(p, n, val)
			local func = p["SetNW" .. bdvt]
			func(p, "bdvar_" .. n, val)
		end
	else
		plymeta["BD_Set" .. bdvt] = function(p, n, val)
			net.Start("bd_plyvarset")
			net.WriteEntity(p)
			net.WriteString(n)
			net.WriteType(val)
			net.SendToServer()
		end
	end
end

-- Create a generic setter for server
if SERVER then

	util.AddNetworkString("bd_plyvarset")
	function plymeta:BD_SetVar(name, val)
		local bdvar = self.BD_Vars and self.BD_Vars[name]
		if not bdvar then return false, "inexistent ".. name end

		if bdvar.validator and not bdvar.validator(val) then
			return false, "invalidated"
		end

		if not self["SetNW" .. bdvar.type] then
			return false, "no setter for " .. bdvar.type
		end

		self["SetNW" .. bdvar.type](self, "bdvar_" .. name, val)

		return true
	end

	net.Receive("bd_plyvarset", function(len, ply)
		local targply = net.ReadEntity()
		local varkey = net.ReadString()
		local typeid = net.ReadUInt(8)
		local obj = net.ReadType(typeid)

		if ply ~= targply then ply:ChatPrint("ur not targply") return end

		local stat, err = targply:BD_SetVar(varkey, obj)
		if not stat then ply:ChatPrint("err: " .. err) end
	end)
end