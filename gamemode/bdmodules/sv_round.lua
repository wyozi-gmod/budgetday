
local default_round_lengths = {
	["pre"] = 5,
	["active"] = 60 * 7,
	["post"] = 3
}

local round_actions = {
	["pre"] = function()
		game.CleanUpMap()
		for _,ply in pairs(player.GetAll()) do
			ply:Spawn()
		end
	end,
	["active"] = function()
		for _,ply in pairs(player.GetAll()) do
			if not ply:Alive() then
				ply:Spawn()
			end
		end
	end
}

local function SetRoundState(state)
	MsgN("Round state changing to ", state)

	SetGlobalFloat("roundstart", CurTime())

	local ract = round_actions[state]
	if ract then
		local stat, err = pcall(ract)
		if not stat then
			MsgN("Roundstate action failed: ", err)
		end
	end

	BroadcastLua("chat.AddText('round state: " .. state .. "')")
	local old_state = GetGlobalString("roundstate")
	SetGlobalString("roundstate", state)

	hook.Call("BDRoundStateChanged", GAMEMODE, old_state, state)
end

function bd.GetRoundState()
	return GetGlobalString("roundstate")
end

local function RoundTick()
	local state = bd.GetRoundState()

	local round_elapsed = CurTime() - GetGlobalFloat("roundstart", 0)
	if state == "pre" then
		if round_elapsed > default_round_lengths.pre and #player.GetAll() > 0 then
			SetRoundState("active")
		end
	elseif state == "active" then
		local alive = false
		for _,ply in pairs(player.GetAll()) do
			if ply:Alive() then alive = true end
		end

		if not alive then
			SetRoundState("post")
		end
	elseif state == "post" then
		if round_elapsed > default_round_lengths.pre then
			SetRoundState("pre")
		end
	else
		SetRoundState("pre")
	end
end

timer.Create("roundticker", 0.5, 0, RoundTick)