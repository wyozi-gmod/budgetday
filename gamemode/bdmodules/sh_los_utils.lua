--Line of sight related utils

local function ToVector(obj)
	if type(obj) == "Vector" then return obj end

	if obj.IsValid and IsValid(obj) then
		if obj.EyePosN then return obj:EyePosN() end -- Used in bd_ai_base
		if obj.EyePos then return obj:EyePos() end
		if obj.OBBCenter then return obj:LocalToWorld(obj:OBBCenter()) end
		return obj:GetPos()
	end

	ErrorNoHalt("Cant turn " .. tostring(obj) .. " into a vector")
end

function bd.ComputeLos(obj1, obj2)
	local pos1 = ToVector(obj1)
	local pos2 = ToVector(obj2)

	local tr = util.TraceLine {
		start = pos1,
		endpos = pos2,
		filter = function(ent) return not (ent == obj1 or ent == obj2) end,
		mask = MASK_OPAQUE + CONTENTS_IGNORE_NODRAW_OPAQUE
	}

	local res = not tr.Hit

	return res
end