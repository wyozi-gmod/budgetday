--- Adds line-of-sight check related functions to "util" module
local MODULE = bd.module("util")

function MODULE.GetEntPosition(obj, is_second_obj)
	if type(obj) == "Vector" then return obj end

	if obj.IsValid and IsValid(obj) then
		if obj:IsPlayer() and obj.EyePos then return obj:EyePos() end

		if is_second_obj then
			if obj.WorldSpaceCenter then return obj:WorldSpaceCenter() end
			if obj.OBBCenter then return obj:LocalToWorld(obj:OBBCenter()) end
			if obj.EyePosN then return obj:EyePosN() end -- Used in bd_ai_base
		else
			if obj.GetCameraPosAng then return obj:GetCameraPosAng() end
			if obj.EyePosN then return obj:EyePosN() end -- Used in bd_ai_base
			if obj.WorldSpaceCenter then return obj:WorldSpaceCenter() end
			if obj.OBBCenter then return obj:LocalToWorld(obj:OBBCenter()) end
		end

		return obj:GetPos()
	end

	ErrorNoHalt("Cant turn " .. tostring(obj) .. " into a vector")
end

-- ComputeLos is gonna be called from a single thread, so these are some nice optimizations
--  to prevent A LOT of memory allocation
local tr_output = {}

local tr_input = {}
tr_input.output = tr_output
tr_input.filter = function(ent)
	if ent:IsWeapon() then return true end

	return not (ent == tr_input.obj1 or ent == tr_input.obj2)
end

local mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_OPAQUE, CONTENTS_BLOCKLOS, CONTENTS_MONSTER)

function MODULE.ComputeLos(obj1, obj2, debug)
	local pos1 = MODULE.GetEntPosition(obj1)
	local pos2 = MODULE.GetEntPosition(obj2, true)

	tr_input.start = pos1
	tr_input.endpos = pos2

	tr_input.obj1 = obj1
	tr_input.obj2 = obj2

	tr_input.mask = mask

	util.TraceLine(tr_input)

	local res = not tr_output.Hit

	if debug then
		debugoverlay.Line(pos1, pos2, 0.1, Color(0, res and 255 or 0, 0))
	end

	return res, tr_output.Entity
end
