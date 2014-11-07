bd.Skills = {}

function bd.RegisterSkill(name, mod)
	bd.Skills[name] = mod
end

function bd.GetSkill(skill)
	return bd.Skills[skill]
end

function bd.LoadSkills()
	bd.Skills = {}

	for _,fil in pairs(loader.luafiles("skills")) do
		loader.shared("skills/" .. fil)
	end
end

bd.LoadSkills()