local MODULE = bd.module("skills")

function MODULE.Register(name, mod)
	MODULE.Skills[name] = mod
end

function MODULE.Get(skill)
	return MODULE.Skills[skill]
end

function MODULE.Load()
	MODULE.Skills = {}

	for _,fil in pairs(loader.luafiles("skills")) do
		loader.shared("skills/" .. fil)
	end
end

MODULE.Load()