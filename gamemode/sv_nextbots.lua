-- Scale headshot damage
hook.Add("BDScaleNextbotDamage", "BD.ScaleHeadshots", function(nextbot, hitgroup, dmginfo)
    if hitgroup == HITGROUP_HEAD and dmginfo:IsBulletDamage() then
        dmginfo:ScaleDamage(4)
    end
end)
