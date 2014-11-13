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

function MODULE.ComputeLos(obj1, obj2)
	local pos1 = MODULE.GetEntPosition(obj1)
	local pos2 = MODULE.GetEntPosition(obj2, true)

	local tr = util.TraceLine {
		start = pos1,
		endpos = pos2,
		filter = function(ent) return not (ent == obj1 or ent == obj2) end,
		mask = MASK_OPAQUE + CONTENTS_IGNORE_NODRAW_OPAQUE
	}

	local res = not tr.Hit

	--debugoverlay.Line(pos1, pos2, 0.1, Color(0, res and 255 or 0, 0))

	return res
end