
module("skills", package.seeall)

Modules = {}

function RegisterModule(name, mod)
	Modules[name] = mod
end

function GetSkill(skill)
	return Modules[skill]
end

function LoadModules()
	Modules = {}

	for _,fil in pairs(loader.luafiles("skills")) do
		loader.shared("skills/" .. fil)
	end
end

LoadModules()