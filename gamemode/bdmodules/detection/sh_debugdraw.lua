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
			net.Start("bd_debugdraw")
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