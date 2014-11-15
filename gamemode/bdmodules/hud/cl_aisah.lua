-- Artificially Improved Sight And HUD
local MODULE = bd.module("aisah")

MODULE.AISAHModules = {}

MODULE.Meta = {}
MODULE.Meta.__index = MODULE.Meta

function MODULE.RegisterModule(name, mod)
	setmetatable(mod, MODULE.Meta)
	MODULE.AISAHModules[name] = mod

	mod:Setup()
end

function bd.FindModule(filter)
	for _,mod in pairs(MODULE.AISAHModules) do
		if filter(mod) then return mod end
	end
end