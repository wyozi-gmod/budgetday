local MODULE = bd.module("interactions")

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
	local x = ScrW()/2 - 100
	local y = ScrH()/2 + 25
	local w, h = 200, 20
	local function text_rect(text, bgclr, keytext, keybgclr, bgprogress)
		bgclr = bgclr or Color(255, 0, 0, 50)
		keybgclr = keybgclr or Color(255, 127, 0, 50)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(x, y, w, h)

		surface.SetDrawColor(keybgclr)
		surface.DrawRect(x+2, y+2, 16, h-4)
		draw.SimpleText(keytext or "", "Trebuchet18", x+10, y+1, _, TEXT_ALIGN_CENTER)

		local prog = bgprogress or 1

		surface.SetDrawColor(bgclr)
		surface.DrawRect(x+20, y+2, (w-22) * prog, h-4)
		draw.SimpleText(text, "Trebuchet18", x+22, y+1, _, TEXT_ALIGN_LEFT)

		y = y + 20
	end

	if LocalPlayer():BD_GetInteraction() then
		local meta = LocalPlayer():BD_GetInteractionMeta()
		local targ = LocalPlayer():BD_GetInteractionTarget()

		if IsValid(targ) then
			text_rect(LocalPlayer():BD_GetInteractionMeta().help(targ, LocalPlayer()), _, "", Color(255, 0, 0, 50), LocalPlayer():BD_GetInteractionProgress())
		end
	else
		local tr = LocalPlayer():GetEyeTrace()
		if IsValid(tr.Entity) and tr.Entity:GetPos():Distance(LocalPlayer():EyePos()) <= MODULE.MaxInteractDistance then
			local ias = tr.Entity:BD_GetValidInteractions(LocalPlayer())

			if #ias == 1 then
				text_rect(MODULE.Get(ias[1]).help(tr.Entity, LocalPlayer()), _, "e")
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