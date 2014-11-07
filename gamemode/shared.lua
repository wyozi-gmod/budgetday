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

function loader.luafiles(folder, filfilter)
	return file.Find("budgetday/gamemode/" .. folder .. "/" .. (filfilter or "*") .. ".lua", "LUA")
end

DeriveGamemode("sandbox")

-- Global table for all storage needs
bd = bd or {}

-- Extend GMod libraries with our own functions
loader.client("libext/surface.lua")
loader.shared("libext/misc.lua")

-- Load module files in bdmodules folder
for _,fil in pairs(loader.luafiles("bdmodules", "sh_*")) do
	loader.shared("bdmodules/" .. fil)
end
for _,fil in pairs(loader.luafiles("bdmodules", "cl_*")) do
	loader.client("bdmodules/" .. fil)
end
for _,fil in pairs(loader.luafiles("bdmodules", "sv_*")) do
	loader.server("bdmodules/" .. fil)
end

-- Load skills from "skills/" folder
loader.shared("skills.lua")