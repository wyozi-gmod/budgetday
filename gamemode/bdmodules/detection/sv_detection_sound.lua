local soundfile_detection = {
    {
        match = function(soundname)
            return soundname:find("footstep") or soundname:find("glass_sheet_step")
        end,

        suspicion = 0.15,
        falloff_exp = 2,
        cause = "heard_footstep"
    },
    {
        match = function(soundname) return soundname:match("physics/metal/metal_box_break%d%.wav") end,

        suspicion = 0.3,
        cause = "heard_vent_break",
        falloff = 128,
        pos = function(data) return data.Entity:GetPos() end
    },
    {
        match = function(soundname) return soundname:match("physics/body/body_medium_scrape_smooth_loop1%.wav") end,

        -- Body fall raises a lot of suspicion but falls off really quickly
        --  -> killing people close to other guards is no good
        suspicion = 0.5,
        falloff = 64,
        falloff_exp = 1.75,
        cause = "heard_body",
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
        local cause
        local pos = data.Pos

        local falloff = 64 -- How quickly suspicion falls off over distance.
        local falloff_exp = 1

        if data.Channel == 1 then -- weapon
            local wep_detection = weapon_soundfile_detection[data.SoundName]

            local is_silenced = wep_detection and wep_detection.silenced or false

            suspicion = is_silenced and 0.2 or 1
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
            local sound_data = bd.util.Find(soundfile_detection, function(tbl)
                return tbl.match(data.SoundName)
            end)

            --MsgN(data.SoundName, " matched against ", sound_data and sound_data.cause or nil)

            if sound_data then
                suspicion = sound_data.suspicion
                cause = sound_data.cause

                if sound_data.pos then pos = sound_data.pos(data) end
                if sound_data.falloff then falloff = sound_data.falloff end
                if sound_data.falloff_exp then falloff_exp = sound_data.falloff_exp end
            end
        end

        if suspicion > 0 and pos and cause then
            for _,npc in pairs(ents.FindByClass("bd_nextbot*")) do
                local dist = npc:GetPos():Distance(pos)

                local suspicionmul = math.Clamp(1 / math.pow(dist/falloff, falloff_exp), 0, 1)

                local level = suspicionmul * suspicion
                if level > 0.001 then
                    npc:NotifyDistraction({
                        level = suspicionmul*suspicion,
                        pos = pos,
                        cause = cause,
                        debug_data = {
                            suspmul = suspicionmul,
                            falloff = falloff,
                            falloff_exp = falloff_exp
                        }
                    })
                end
            end
        end
    end
end)
