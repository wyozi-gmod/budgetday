local MODULE = bd.module("debugdraw")

MODULE.FnTypes = MODULE.FnTypes or {}

local function netWriteColor(x)
	-- Eg. HSVToColor returns a table instead of a color, which breaks WriteColor
	if type(x) == "table" then
		x = Color(x.r, x.g, x.b)
	end

	net.WriteColor(x)
end

local TypeMap = {
	[TYPE_VECTOR] = { read = net.ReadVector, write = net.WriteVector },
	[TYPE_NUMBER] = { read = net.ReadDouble, write = net.WriteDouble },
	[TYPE_COLOR] = { read = net.ReadColor, write = netWriteColor },
	[TYPE_STRING] = { read = net.ReadString, write = net.WriteString },
}

local function RegisterFunc(name, types, fn)
	MODULE.FnTypes[name] = types

	if SERVER then
		util.AddNetworkString(name)

		MODULE[name] = function(...)
			net.Start("bd_debugdraw", true)
			net.WriteUInt(util.NetworkStringToID(name), 32)

			local at = {...}
			for i,t in ipairs(types) do
				local val = at[i]
				local isNil = val == nil

				net.WriteBool(isNil)
				if not isNil then
					TypeMap[t].write(val)
				end
			end
			net.Broadcast()
		end
	elseif CLIENT then
		MODULE[name] = fn
	end
end

if SERVER then
	util.AddNetworkString("bd_debugdraw")
elseif CLIENT then
	net.Receive("bd_debugdraw", function(len)
		local str = util.NetworkIDToString(net.ReadUInt(32))
		local fn = MODULE[str]

		if not fn then print("unknown debugdraw func ", str) return end

		local args = {}
		for i,t in ipairs(MODULE.FnTypes[str]) do
			local isNil = net.ReadBool()
			if not isNil then
				args[i] = TypeMap[t].read()
			end
		end

		fn(unpack(args))
	end)
end

RegisterFunc("Point", {TYPE_VECTOR, TYPE_NUMBER}, function(point, duration)
	debugoverlay.Sphere(point, 16, duration or 2)
end)
RegisterFunc("Line", {TYPE_VECTOR, TYPE_VECTOR, TYPE_NUMBER, TYPE_COLOR}, function(point1, point2, duration, clr)
	debugoverlay.Line(point1, point2, duration or 2, clr or Color(255, 255, 255))
end)
RegisterFunc("Text", {TYPE_VECTOR, TYPE_STRING, TYPE_NUMBER}, function(point, text, duration)
	debugoverlay.Text(point, text, duration or 2)
end)

local sw_id = 0
RegisterFunc("SoundWave", {TYPE_VECTOR, TYPE_NUMBER, TYPE_NUMBER, TYPE_NUMBER}, function(point, falloff, falloff_exp, duration)
	local hookId = "BD.DebugDraw.SoundWave#" .. sw_id
	sw_id = sw_id+1

	local start = CurTime()

	hook.Add("PostDrawTranslucentRenderables", hookId, function()
		local elapsed = CurTime() - start
		local frac = elapsed / (duration or 2)
		if frac >= 1 then hook.Remove("PostDrawTranslucentRenderables", hookId) return end

		for p=1, 4 do
			local suspmul = math.pow(0.5, p)
			local dist = falloff * math.pow(1/suspmul, 1/falloff_exp)


			--debugoverlay.Sphere(data.pos, dist, 1, Color(255, 255, 255, 64*suspmul), true)
			render.DrawSphere(point, dist, 16, 16, Color(255, 255, 255, 64*suspmul))
		end
	end)
end)

RegisterFunc("Sight", {TYPE_VECTOR, TYPE_VECTOR, TYPE_NUMBER, TYPE_NUMBER}, function(point, dir, height, angle)
	local cone_apex = point
	local cone_dir = dir

	local cone_height = height
	local cone_angle = angle

	bd.debugdraw.Line(cone_apex, cone_apex + cone_dir*cone_height, 0.15, Color(0, 255, 0))

	-- Let's compute right and up vectors from the forward vector using cross products
	local right_vec = cone_dir:Cross(Vector(0, 0, 1))
	local up_vec = -cone_dir:Cross(right_vec)

	local radius = math.tan(math.rad(cone_angle)) * cone_height

	local points = 32
	local rad_per_point = math.pi*2 / points
	for i=0,points do
		local point1 = cone_apex
		local point2 = cone_apex + cone_dir * cone_height
							+ right_vec * math.cos(rad_per_point * i) * radius
							+ up_vec * math.sin(rad_per_point * i) * radius

		bd.debugdraw.Line(point1, point2, 0.15, Color(255, 127, 0))
	end
	--bd.debugdraw.Text(point, text, duration or 2)
end)