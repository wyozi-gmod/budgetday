--- AISAH = Artificially Improved Sight And HUD
-- In other words, AISAH is the system that manages drawing and input of the HUD modules, that are on the left side of the screen
-- Each one of the "boxes" on HUD is its own AISAH module. See gamemode/skills/aisah_vitalstats.lua for an example of how to create an AISAH module.
--
-- If you need help with how input is handled, see gamemode/bdmodules/hud/cl_aisah_input.lua
-- If you need help with how drawing is handled, see gamemode/bdmodules/hud/cl_aisah_draw.lua
--
-- @module aisah
-- @realm client
local MODULE = bd.module("aisah")

--- This is the metatable that every single AISAH module is based on.
-- Adding functions to it makes them available in the module as well.
MODULE.Meta = {} 
MODULE.Meta.__index = MODULE.Meta

MODULE.AISAHModules = {}

--- Registers and sets up module. After registering module is eligible for drawing and input.
-- @param name:string the internal name of this module
-- @param module:table the actual module
function MODULE.RegisterModule(name, mod)
	setmetatable(mod, MODULE.Meta)
	MODULE.AISAHModules[name] = mod

	mod:Setup()
end

--- Executes given 'filter' function once for each registered AISAH module.
-- If 'filter' returns true, returns that module immediately.
-- @param filter:function the callback function
function MODULE.FindModule(filter)
	for _,mod in pairs(MODULE.AISAHModules) do
		if filter(mod) then return mod end
	end
end