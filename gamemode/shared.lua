DeriveGamemode("sandbox")

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
	-- file.Find returns gamemode files only if the gamemode name is explicitly specified here
	local gm_fils, gm_fols = file.Find(GM.FolderName .. "/gamemode/" .. folder .. "/" .. (filfilter or "*"), "LUA")
	local addon_fils, addon_fols = file.Find(folder .. "/" .. (filfilter or "*"), "LUA")

	local fils, fols = {}, {}

	table.Add(fils, gm_fils)
	table.Add(fils, addon_fils)
	table.Add(fols, gm_fols)
	table.Add(fols, addon_fols)

	return fils, fols
end

-- Global table for all storage needs
bd = bd or {}

-- Load module support
loader.shared("modules.lua")

-- Extend GMod libraries with our own functions
loader.client("libext/surface.lua")
loader.shared("libext/misc.lua")

-- Traverses through all folders and files in given folder and loads lua files from them
local function LoadFromFolder(folder)
	local _, folders = loader.luafiles(folder)
	for _,fold in pairs(folders) do
		LoadFromFolder(string.format("%s/%s", folder, fold))
	end

	for _,fil in pairs(loader.luafiles(folder, "sh_*.lua")) do
		loader.shared(string.format("%s/%s", folder, fil))
	end
	for _,fil in pairs(loader.luafiles(folder, "cl_*.lua")) do
		loader.client(string.format("%s/%s", folder, fil))
	end
	for _,fil in pairs(loader.luafiles(folder, "sv_*.lua")) do
		loader.server(string.format("%s/%s", folder, fil))
	end
end
LoadFromFolder("bdmodules")

-- Load skills from "skills/" folder
loader.shared("skills.lua")
