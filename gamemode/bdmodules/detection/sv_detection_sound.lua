local soundfile_detection = {
    ["physics/metal/metal_box_break1.wav"] = {
        suspicion = 0.3,
        cause = "heard_vent_break",
        falloff = 128,
        pos = function(data) return data.Entity:GetPos() end
    },
    ["physics/metal/metal_box_break2.wav"] = {
        suspicion = 0.3,
        cause = "heard_vent_break",
        falloff = 128,
        pos = function(data) return data.Entity:GetPos() end
    }
}

local weapon_soundfile_detection = {
    ["weapons/usp/usp1.wav"] = {silenced = true}
}

hook.Add("EntityEmitSound", "BDDetectSounds", function(data)
    local ent = data.Entity

    if IsValid(ent) then
        local suspicion = 0.01
        local cause = "heard_unknown"
        local pos = data.Pos

        local falloff = 64 -- How quickly suspicion falls off over distance.

        if data.SoundName:find("footstep") then -- Footsteps etc..
            suspicion = 0.02
            cause = "heard_footstep"
        elseif data.Channel == 1 then -- weapon
            local wep_detection = weapon_soundfile_detection[data.SoundName]

            local is_silenced = wep_detection and wep_detection.silenced or false

            suspicion = is_silenced and 0.1 or 1
            cause = "heard_weapon_shot"
            if data.Entity:IsPlayer() then
                pos = data.Entity:GetShootPos()
            elseif data.Entity.EyePosN then
                pos = data.Entity:EyePosN()
            else
                pos = data.Entity:GetPos()
            end

            -- Nonsilenced weapons are audible from really far away
            if not is_silenced then falloff = 600 end
        else
            local sound_data = soundfile_detection[data.SoundName]
            if sound_data then
                suspicion = sound_data.suspicion
                cause = sound_data.cause

                if sound_data.pos then pos = sound_data.pos(data) end
                if sound_data.falloff then falloff = sound_data.falloff end
            end
        end

        if suspicion > 0 and pos then
            for _,npc in pairs(ents.FindByClass("bd_nextbot*")) do
                local dist = npc:GetPos():Distance(pos)
                local suspicionmul = math.Clamp(1 / (dist / falloff), 0, 1)

                local level = suspicionmul * suspicion
                if level > 0.001 then
                    npc:NotifyDistraction({level = suspicionmul*suspicion, pos = pos, cause = cause})
                end
            end
        end
    end
end)
