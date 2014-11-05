-- Interactions with non-SENTs
local additional_interactions = {
	["bd_ai_base"] = {
		filter = function(ply, ent) return false end,
		help_text = function(ply, ent) return "{press} to knock out" end,
		length = function(ply, ent) return 0.5 end,
		action = function(ply, ent)
			MsgN(ply, " knocked down ", ent)
		end,
		cancel = function(ply, ent, progress_fraction)
			MsgN(ply, " canceled knock down of ", ent, " at ", progress_fraction)
		end
	}
}

local entmeta = FindMetaTable("Entity")

function entmeta:BD_IsInteractable(ply)
	if additional_interactions[self:GetClass()] then
		return additional_interactions[self:GetClass()].filter(ply, self)
	end
	return false
end
function entmeta:BD_GetInteractHelpText(ply)
	if additional_interactions[self:GetClass()] then
		return additional_interactions[self:GetClass()].help_text(ply, self)
	end
end
function entmeta:BD_GetInteractLength(ply)
	if additional_interactions[self:GetClass()] then
		return additional_interactions[self:GetClass()].length(ply, self)
	end
end
function entmeta:BD_OnInteract(ply)
	if additional_interactions[self:GetClass()] then
		additional_interactions[self:GetClass()].action(ply, self)
	end
end
function entmeta:BD_OnInteractCancel(ply, progress_fraction)
	if additional_interactions[self:GetClass()] then
		additional_interactions[self:GetClass()].cancel(ply, self, progress_fraction)
	end
end

if CLIENT then
	hook.Add("HUDPaint", "BD_InteractHelp", function()
		local tr = LocalPlayer():GetEyeTrace()
		if IsValid(tr.Entity) then
			local is_interactable = tr.Entity:BD_IsInteractable(LocalPlayer())
			
			if is_interactable then
				draw.SimpleText(tr.Entity:BD_GetInteractHelpText(LocalPlayer()), "Trebuchet18", ScrW()/2, ScrH()/2)
			end
		end
	end)
end