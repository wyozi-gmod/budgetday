-- Handles construction audio messages from hl2 sound files (npc/overwatch/radiovoice/x.wav)

local keys = {
	report = "npc/overwatch/radiovoice/reportplease.wav",
	allunitsat = "npc/overwatch/radiovoice/allunitsat.wav",
	investandreport = "npc/overwatch/radiovoice/investigateandreport.wav",
	localteamsreporton = "npc/overwatch/radiovoice/reporton.wav",
	sector = "npc/overwatch/radiovoice/sector.wav",
	comma = "npc/overwatch/radiovoice/_comma.wav",

	["1"] = "npc/overwatch/radiovoice/one.wav",
	["2"] = "npc/overwatch/radiovoice/two.wav",
	["3"] = "npc/overwatch/radiovoice/three.wav",
	["4"] = "npc/overwatch/radiovoice/four.wav",
	["5"] = "npc/overwatch/radiovoice/five.wav",
	["6"] = "npc/overwatch/radiovoice/six.wav",
	["7"] = "npc/overwatch/radiovoice/seven.wav",
	["8"] = "npc/overwatch/radiovoice/eight.wav",
	["9"] = "npc/overwatch/radiovoice/nine.wav",
}

function bd.EmitRadioMessage(ply, message)
	local message_parts = message:Split(" ")

	local time_elapsed = 0
	for _,split in pairs(message_parts) do
		local sound = keys[split]
		if not sound then MsgN("Unknown radio message split ", split) return end

		timer.Simple(time_elapsed, function()
			ply:EmitSound(sound)
		end)
		time_elapsed = time_elapsed + SoundDuration(sound)
	end
end