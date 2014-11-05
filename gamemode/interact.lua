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

local function BD_IsInteractable(ent, ply)
	if ent.BD_IsInteractable then return ent:BD_IsInteractable(ply) end

	if additional_interactions[ent:GetClass()] then
		return additional_interactions[ent:GetClass()].filter(ply, ent)
	end
	return false
end
local function BD_GetInteractHelpText(ent, ply)
	if ent.BD_GetInteractHelpText then return ent:BD_GetInteractHelpText(ent, ply) end

	if additional_interactions[ent:GetClass()] then
		return additional_interactions[ent:GetClass()].help_text(ply, ent)
	end
end
local function BD_GetInteractLength(ent, ply)
	if ent.BD_GetInteractLength then return ent:BD_GetInteractLength(ent, ply) end

	if additional_interactions[ent:GetClass()] then
		return additional_interactions[ent:GetClass()].length(ply, ent)
	end
end
local function BD_OnInteract(ent, ply)
	if ent.BD_OnInteract then return ent:BD_OnInteract(ent, ply) end

	if additional_interactions[ent:GetClass()] then
		additional_interactions[ent:GetClass()].action(ply, ent)
	end
end
local function BD_OnInteractCancel(ent, ply, progress_fraction)
	if ent.BD_OnInteractCancel then return ent:BD_OnInteractCancel(ent, ply, progress_fraction) end

	if additional_interactions[ent:GetClass()] then
		additional_interactions[ent:GetClass()].cancel(ply, ent, progress_fraction)
	end
end

if SERVER then
	hook.Add("PlayerUse", "BD_InteractSetup", function(ply, ent)
		local is_interactable = BD_IsInteractable(ent, ply)
		if is_interactable and not ply:GetNWBool("BD_Interacting") then
			ply:SetNWBool("BD_Interacting", true)
			ply:SetNWEntity("BD_InteractTarget", ent)
			ply:SetNWFloat("BD_InteractStart", CurTime())
		end
	end)
	hook.Add("Think", "BD_InteractThink", function()
		for _,ply in pairs(player.GetAll()) do
			if ply:GetNWBool("BD_Interacting") then
				local targ = ply:GetNWEntity("BD_InteractTarget")
				if IsValid(targ) then
					local elapsed = CurTime() - ply:GetNWFloat("BD_InteractStart", 0)
					if elapsed >= BD_GetInteractLength(targ, ply) then
						BD_OnInteract(targ, ply)
						ply:SetNWBool("BD_Interacting", false)
					elseif not ply:KeyDown(IN_USE) then
						BD_OnInteractCancel(targ, ply, elapsed / BD_GetInteractLength(targ, ply))
						ply:SetNWBool("BD_Interacting", false)
					end
				else
					ply:SetNWBool("BD_Interacting", false)
				end
			end
		end
	end)
end

if CLIENT then
	hook.Add("HUDPaint", "BD_InteractHelp", function()
		local tr = LocalPlayer():GetEyeTrace()
		if IsValid(tr.Entity) then
			local is_interactable, failmsg = BD_IsInteractable(tr.Entity, LocalPlayer())
			
			if is_interactable then
				local txt = BD_GetInteractHelpText(tr.Entity, LocalPlayer())

				local use_bind = tostring(input.LookupBinding("+use"))
				txt = txt:Replace("{press}", "Press '" .. use_bind .. "'")
				txt = txt:Replace("{hold}", "Hold '" .. use_bind .. "'")
				draw.SimpleText(txt, "Trebuchet18", ScrW()/2, ScrH()/2)
			elseif failmsg then
				draw.SimpleText(failmsg, "Trebuchet18", ScrW()/2, ScrH()/2, Color(255, 0, 0))
			end
		end

		if LocalPlayer():GetNWBool("BD_Interacting") then
			local targ = LocalPlayer():GetNWEntity("BD_InteractTarget")
			if IsValid(targ) then
				local elapsed = CurTime() - LocalPlayer():GetNWFloat("BD_InteractStart", 0)
				draw.SimpleText(string.format("%d %f", targ:EntIndex(), elapsed/BD_GetInteractLength(targ, LocalPlayer())), "Trebuchet24", ScrW()/2, ScrH()/2+50)
			end
		end
	end)
end