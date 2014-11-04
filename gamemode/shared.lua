-- Helper functions to load files
loader = {}

function loader.server(file)
	if SERVER then include(file) end
end
function loader.client(file)
	if SERVER then AddCSLuaFile(file) end
	if CLIENT then include(file) end
end
function loader.shared(file)
	loader.server(file)
	loader.client(file)
end

function loader.luafiles(folder)
	return file.Find("budgetday/gamemode/" .. folder .. "/*.lua", "LUA")
end

DeriveGamemode("sandbox")

-- Extend GMod libraries with our own functions
loader.client("libext/surface.lua")
loader.client("libext/misc.lua")

-- Set sensible defaults (hide hud, set physicsvars, disable flashlight etc)
loader.shared("gmod_setdefaults.lua")

-- Load extensions to player meta table
loader.shared("player_skills.lua")
loader.shared("player_vars.lua")

-- Load HUD system
loader.client("aisah.lua")

-- Load skill system
loader.shared("skills.lua")

-- Handle player spawning related things (giving weapons, positioning etc)
loader.server("spawn.lua")