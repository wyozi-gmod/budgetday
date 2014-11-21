local MODULE = bd.module("interactions")

local iact_menu_ent

hook.Add("PlayerBindPress", "BD_HandleInteraction", function(ply, bind, pressed)
	local tr = LocalPlayer():GetEyeTrace()

	if pressed and IsValid(tr.Entity) and tr.Entity:GetPos():Distance(LocalPlayer():EyePos()) <= MODULE.MaxInteractDistance then
		local ias = tr.Entity:BD_GetValidInteractions(LocalPlayer())

		if bind:sub(1, 4) == "slot" and tr.Entity == iact_menu_ent then
			local slot_idx = tonumber(bind:sub(5))
			local ia_name = ias[slot_idx]

			if ia_name then
				net.Start("bd_startinteract")
					net.WriteEntity(tr.Entity)
					net.WriteString(ia_name)
				net.SendToServer()

				iact_menu_ent = nil
				return true
			end
		elseif bind == "+use" then
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
	local ply = LocalPlayer()

	local x = ScrW()/2 - 100
	local y = ScrH()/2 + 25
	local w, h = 220, 22

	local function text_rect(text, data)

		local bgclr = (data and data.bgclr) or Color(255, 0, 0, 50)
		local keybgclr = (data and data.keybgclr) or Color(255, 127, 0, 50)
		local keytext = (data and data.keytext)
		local bgprogress = (data and data.bgprogress)
		local icon = (data and data.icon)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(x, y, w, h)

		surface.SetDrawColor(keybgclr)
		surface.DrawRect(x+2, y+2, 16, h-4)
		draw.SimpleText(keytext or "", "Trebuchet18", x+10, y+h/2, _, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local prog = bgprogress or 1

		surface.SetDrawColor(bgclr)
		surface.DrawRect(x+20, y+2, (w-22) * prog, h-4)

		local x_off = 22
		if icon then
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(icon)
			local icon_size = 16

			surface.DrawTexturedRect(x+x_off, y+((h-icon_size)/2), icon_size, icon_size)

			x_off = x_off + 20
		end
		draw.SimpleText(text, "Trebuchet18", x+x_off, y+h/2, _, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		y = y + h
	end

	if ply:BD_GetInteraction() then
		local meta = ply:BD_GetInteractionMeta()
		local targ = ply:BD_GetInteractionTarget()

		if IsValid(targ) then
			local progress = ply:BD_GetInteractionProgress()

			local time_left = meta.length(targ, ply) * (1-progress)

			text_rect(ply:BD_GetInteractionMeta().help(targ, ply, true), {
				bgclr=Color(255, 0, 0, 50),
				bgprogress=progress,
				keytext=tostring(math.abs(math.ceil(time_left))),
				icon = meta.menu_icon
			})
		end
	else
		local tr = ply:GetEyeTrace()
		if IsValid(tr.Entity) and tr.Entity:GetPos():Distance(ply:EyePos()) <= MODULE.MaxInteractDistance then
			local ias = tr.Entity:BD_GetValidInteractions(ply)

			if #ias == 1 then
				local interaction = MODULE.Get(ias[1])
				text_rect(interaction.help(tr.Entity, ply), {keytext="e", icon=interaction.menu_icon})
			elseif #ias > 0 then
				if iact_menu_ent == tr.Entity then
					text_rect("Interactions", Color(100, 255, 100, 50))
					for idx,ianame in pairs(ias) do
						local interaction = MODULE.Get(ianame)

						text_rect(interaction.help(tr.Entity, ply), {keytext=tostring(idx), icon=interaction.menu_icon})
					end
				else
					text_rect("Open interactions menu", {bgclr=Color(100, 255, 100, 50), keytext="e"})
				end
			end
		end
	end

end)
