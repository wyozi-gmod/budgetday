
local default_round_lengths = {
	["pre"] = 5,
	["active"] = 60 * 7,
	["post"] = 5
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
	SetGlobalFloat("roundend", CurTime() + default_round_lengths[state])

	local ract = round_actions[state]
	if ract then
		local stat, err = pcall(ract)
		if not stat then
			MsgN("Roundstate action failed: ", err)
		end
	end

	BroadcastLua("chat.AddText('round state: " .. state .. "')")

	return SetGlobalString("roundstate", state)
end

local function GetRoundState()
	return GetGlobalString("roundstate")
end


local function RoundTick()
	local state = GetRoundState()

	local round_expired = GetGlobalFloat("roundend") < CurTime()
	if round_expired then
		if state == "pre" then
			if #player.GetAll() > 0 then
				SetRoundState("active")
			end
		elseif state == "active" then
			SetRoundState("post")
		elseif state == "post" then
			SetRoundState("pre")
		end
	elseif state == "active" then
		-- TODO ??
		local alive = false
		for _,ply in pairs(player.GetAll()) do
			if ply:Alive() then alive = true end
		end

		if not alive then
			SetRoundState("post")
		end
	end
end

timer.Create("roundticker", 0.5, 0, RoundTick)