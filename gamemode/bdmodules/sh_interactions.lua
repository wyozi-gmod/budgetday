module("interactions", package.seeall)

Interactions = {}

function Get(name)
	return Interactions[name]
end

function Register(name, tbl)
	Interactions[name] = tbl
end

--[[interactions.Register("debug", {
	filter = function(ent, ply) return true end,
	help = function(ent, ply) return "DebugDebugDebug" end,
	finish = function(ent, ply) end,
	cancel = function(ent, ply) end,
	length = function() return 5 end
})]]

interactions.Register("door_lockpick", {
	filter = function(ent, ply)
		return
			ent:GetClass() == "prop_door_rotating" and
			not ent:GetNWBool("lockpicked")
	end,
	help = function(ent, ply) return "Lockpick" end,
	finish = function(ent, ply)
		ent:Fire("unlock", "", 0)
		ent:Fire("open", "", 0)
		ent:Fire("lock", "", 0)
		ent:SetNWBool("lockpicked", true) end,
	cancel = function(ent, ply) end,
	length = function() return 5 end
})
interactions.Register("vent_breakin", {
	filter = function(ent, ply)
		return ent:GetClass() == "func_breakable"
	end,
	help = function(ent, ply) return "Break in" end,
	finish = function(ent, ply)
		ent:Fire("Break", "", 0)
	end,
	cancel = function(ent, ply) end,
	length = function() return 5 end
})
interactions.Register("body_drag", {
	filter = function(ent, ply)
		return ent:GetClass() == "prop_ragdoll"
	end,
	help = function(ent, ply) return "Start dragging" end,
	finish = function(ent, ply)
		local tr = ply:GetEyeTrace()
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
			bd.DragBody(ply, tr.Entity, tr.PhysicsBone)
		else
			ply:ChatPrint("point at ragdoll while channeling")
		end
	end,
	cancel = function(ent, ply) end,
	length = function() return 0.5 end
})

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

local max_dist = 128

if SERVER then
	util.AddNetworkString("bd_startinteract")
	net.Receive("bd_startinteract", function(len, ply)
		local ent = net.ReadEntity()
		local ia_name = net.ReadString()

		if not IsValid(ent) then return ply:ChatPrint("invalid ent") end
		if ent:GetPos():Distance(ply:EyePos()) > max_dist then return ply:ChatPrint("too far") end

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
					if targ:GetPos():Distance(ply:EyePos()) > max_dist then
						meta.cancel(targ, ply, frac)
						ply:BD_ClearInteraction()
					elseif frac >= 1 then
						meta.finish(targ, ply)
						ply:BD_ClearInteraction()
					end
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
		if bind == "+use" and pressed and tr.Entity ~= iact_menu_ent then
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
			if IsValid(tr.Entity) and tr.Entity:GetPos():Distance(LocalPlayer():EyePos()) <= max_dist then
				local ias = tr.Entity:BD_GetValidInteractions(LocalPlayer())

				local x = ScrW()/2 - 100
				local y = ScrH()/2 + 25
				local w, h = 200, 20
				local function text_rect(text, bgclr, keytext, keybgclr)
					bgclr = bgclr or Color(255, 0, 0, 50)
					keybgclr = keybgclr or Color(255, 127, 0, 50)

					surface.SetDrawColor(0, 0, 0, 150)
					surface.DrawRect(x, y, w, h)

					surface.SetDrawColor(keybgclr)
					surface.DrawRect(x+2, y+2, 16, h-4)
					draw.SimpleText(keytext or "", "Trebuchet18", x+10, y+1, _, TEXT_ALIGN_CENTER)

					surface.SetDrawColor(bgclr)
					surface.DrawRect(x+20, y+2, w-22, h-4)
					draw.SimpleText(text, "Trebuchet18", x+22, y+1, _, TEXT_ALIGN_LEFT)

					y = y + 20
				end

				if #ias == 1 then
					text_rect(Get(ias[1]).help(tr.Entity, LocalPlayer()), _, "e")
				elseif #ias > 0 then
					if iact_menu_ent == tr.Entity then
						text_rect("Interactions", Color(100, 255, 100, 50))
						for idx,ianame in pairs(ias) do
							local interaction = Get(ianame)

							text_rect(interaction.help(tr.Entity, LocalPlayer()), _, tostring(idx))
						end
					else
						text_rect("Open interactions menu", Color(100, 255, 100, 50), "e")
					end
				end
			end
		end

	end)
end