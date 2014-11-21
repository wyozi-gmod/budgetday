local MODULE = bd.module("interactions")

MODULE.Interactions = MODULE.Interactions or {}

function MODULE.Get(name)
	return MODULE.Interactions[name]
end

function MODULE.Register(name, tbl)
	MODULE.Interactions[name] = tbl
end

--[[interactions.Register("debug", {
	filter = function(ent, ply) return true end,
	help = function(ent, ply) return "DebugDebugDebug" end,
	finish = function(ent, ply) end,
	cancel = function(ent, ply) end,
	length = function() return 5 end
})]]

bd.interactions.Register("door_lockpick", {
	filter = function(ent, ply)
		local entcls = ent:GetClass()
		return (entcls == "prop_door_rotating" or entcls == "func_door_rotating") and not ent:GetNWBool("lockpicked")
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
bd.interactions.Register("vent_breakin", {
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
bd.interactions.Register("body_drag", {
	filter = function(ent, ply)
		return ent:GetClass() == "prop_ragdoll" and not ent:GetNWBool("BeingDragged")
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
	length = function() return 0.5 end,
	menu_priority = 10
})

local entmeta = FindMetaTable("Entity")
function entmeta:BD_GetValidInteractions(interacting_ply)
	local ia = {}

	-- If one of the interactions has a priority, we need to sort the interaction table
	local sort_needed = false

	for name,tbl in pairs(MODULE.Interactions) do
		if tbl.filter(self, interacting_ply) then
			if tbl.menu_priority then
				table.insert(ia, {name = name, priority = tbl.menu_priority})
				sort_needed = true
			else
				table.insert(ia, name)
			end
		end
	end

	if sort_needed then
		-- Sort table, biggest priority first
		table.sort(ia, function(a, b)
			local a_prio = type(a) == "table" and a.priority or 0
			local b_prio = type(b) == "table" and b.priority or 0

			return a_prio > b_prio
		end)

		-- Flatten table
		for key,val in pairs(ia) do
			if type(val) == "table" then
				ia[key] = val.name
			end
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
	return MODULE.Get(self:GetNWString("BD_InteractionName"))
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

MODULE.MaxInteractDistance = 128

if SERVER then
	util.AddNetworkString("bd_startinteract")
	net.Receive("bd_startinteract", function(len, ply)
		local ent = net.ReadEntity()
		local ia_name = net.ReadString()

		if not IsValid(ent) then return ply:ChatPrint("invalid ent") end
		if ent:GetPos():Distance(ply:EyePos()) > MODULE.MaxInteractDistance then return ply:ChatPrint("too far") end

		-- TODO verify distance to ent etc
		local interaction = MODULE.Get(ia_name)
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
					if targ:GetPos():Distance(ply:EyePos()) > MODULE.MaxInteractDistance then
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
