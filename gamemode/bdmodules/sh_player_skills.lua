local plymeta = FindMetaTable("Player")

function plymeta:HasSkill(skill)
	return self:GetNWBool("bdskill_" .. skill)
end

if SERVER then
	function plymeta:GiveSkill(skill)
		local skilltbl = bd.skills.Get(skill)
		if skilltbl then
			skilltbl:RegisterVariables(self)
			self:SetNWBool("bdskill_" .. skill, true)
			return true
		end
		return false
	end
	function plymeta:TakeSkill(skill)
		local skilltbl = bd.skills.Get(skill)
		if skilltbl then
			skilltbl:UnRegisterVariables(self)
			self:SetNWBool("bdskill_" .. skill, false)
			return true
		end
		return false
	end
end