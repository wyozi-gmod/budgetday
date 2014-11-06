module("interactions", package.seeall)

Interactions = {}

function Get(name)
	return Interactions[name]
end

function Register(name, tbl)
	Interactions[name] = tbl
end

local entmeta = FindMetaTable("Entity")
function entmeta:BD_GetValidInteractions(interacting_ply)
	local ia = {}
	for name,tbl in pairs(Interactions) do
		if tbl.filter(self, interacting_ply) then
			table.insert(ia, name)
		end
	end
	return ia
end

local plymeta = FindMetaTable("Player")
function plymeta:BD_GetInteraction()
	local str = self:GetNWString("BD_InteractionName")
	if str == "" then return nil end
	return str
end
function plymeta:BD_GetInteractionMeta()
	return Get(self:GetNWString("BD_InteractionName"))
end
function plymeta:BD_ClearInteraction()
	self:SetNWString("BD_InteractionName", "")
end
function plymeta:BD_GetInteractionTarget()
	if self:BD_GetInteraction() then
		return self:GetNWEntity("BD_InteractTarget")
	end
end
function plymeta:BD_GetInteractionProgress()
	local meta = self:BD_GetInteractionMeta()
	if meta then
		local start = self:GetNWFloat("BD_InteractStart", 0)
		local elapsed = CurTime() - start

		return elapsed / meta.length(self:BD_GetInteractionTarget(), self)
	end
	return 0
end

if SERVER then
	util.AddNetworkString("bd_startinteract")
	net.Receive("bd_startinteract", function(len, ply)
		local ent = net.ReadEntity()
		local ia_name = net.ReadString()

		-- TODO verify distance to ent etc
		local interaction = Get(ia_name)
		if not interaction then return ply:ChatPrint("Invalid interaction") end

		if not interaction.filter(ent, ply) then return ply:ChatPrint("Invalid ent") end

		if ply:BD_GetInteraction() then return ply:ChatPrint("Already interacting") end

		ply:SetNWEntity("BD_InteractTarget", ent)
		ply:SetNWFloat("BD_InteractStart", CurTime())
		ply:SetNWString("BD_InteractionName", ia_name)
	end)
	hook.Add("Think", "BD_InteractThink", function()
		for _,ply in pairs(player.GetAll()) do
			local meta = ply:BD_GetInteractionMeta()
			if meta then
				local targ = ply:BD_GetInteractionTarget()

				if IsValid(targ) then
					local frac = ply:BD_GetInteractionProgress()
					if frac >= 1 then
						meta.finish(targ, ply)
						ply:BD_ClearInteraction()
					end
					--[[
					if not ply:KeyDown(IN_USE) then
						meta.cancel(targ, ply, frac)
						ply:BD_ClearInteraction()
					end
					]]
				else
					ply:BD_ClearInteraction()
				end
			end
		end
	end)
end

if CLIENT then
	local iact_menu_ent

	hook.Add("PlayerBindPress", "BD_HandleInteraction", function(ply, bind, pressed)
		local tr = LocalPlayer():GetEyeTrace()

		if bind:sub(1, 4) == "slot" and pressed and tr.Entity == iact_menu_ent then
			local slot_idx = tonumber(bind:sub(5))

			if IsValid(tr.Entity) then
				local ias = tr.Entity:BD_GetValidInteractions(LocalPlayer())

				local ia_name = ias[slot_idx]

				if ia_name then
					net.Start("bd_startinteract")
						net.WriteEntity(tr.Entity)
						net.WriteString(ia_name)
					net.SendToServer()
					
					iact_menu_ent = nil
					return true
				end
			end
		end
		if bind == "+use" and pressed then
			if IsValid(tr.Entity) then
				local ias = tr.Entity:BD_GetValidInteractions(LocalPlayer())

				if #ias == 1 then
					net.Start("bd_startinteract")
						net.WriteEntity(tr.Entity)
						net.WriteString(ias[1])
					net.SendToServer()
					
					return true
				elseif #ias > 0 then
					iact_menu_ent = tr.Entity

					return true
				end
			end
		end
	end)
	hook.Add("HUDPaint", "BD_InteractHelp", function()

		if LocalPlayer():BD_GetInteraction() then
			local meta = LocalPlayer():BD_GetInteractionMeta()
			local targ = LocalPlayer():BD_GetInteractionTarget()

			if IsValid(targ) then
				draw.SimpleText(string.format("%d %f", targ:EntIndex(), LocalPlayer():BD_GetInteractionProgress()), "Trebuchet24", ScrW()/2, ScrH()/2)
			end
		else
			local tr = LocalPlayer():GetEyeTrace()
			if IsValid(tr.Entity) then
				local ias = tr.Entity:BD_GetValidInteractions(LocalPlayer())

				local y = ScrH()/2
				local function text(d)
					draw.SimpleText(d, "Trebuchet18", ScrW()/2, y)
					y = y + 20
				end

				if #ias == 1 then
					text(string.format("do '%s' on %s by pressing '+use'", Get(ias[1]).help(tr.Entity, LocalPlayer()), tr.Entity:GetClass()))
				elseif #ias > 0 then
					if iact_menu_ent == tr.Entity then
						text(string.format("interactions for %s:", tr.Entity:GetClass()))
						for idx,ianame in pairs(ias) do
							local interaction = Get(ianame)

							text(string.format("%d: %s", idx, interaction.help(tr.Entity, LocalPlayer())))
						end
					else
						text(string.format("open interact menu for %s with '+use' (%d interactions)", tr.Entity:GetClass(), #ias))
					end
				end
			end
		end

	end)
end