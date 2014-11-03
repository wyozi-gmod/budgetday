-- Helper functions to load files
local function server(file)
	if SERVER then include(file) end
end
local function client(file)
	if SERVER then AddCSLuaFile(file) end
	if CLIENT then include(file) end
end
local function shared(file)
	server(file)
	client(file)
end