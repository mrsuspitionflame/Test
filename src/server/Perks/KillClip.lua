local KillClip = {}

function KillClip.AfterReload(weapon)
    weapon.Damage = weapon.Damage * 1.2
end

return KillClip
