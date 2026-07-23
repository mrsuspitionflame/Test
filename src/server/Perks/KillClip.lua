local KillClip = {}

function KillClip.AfterReload(Gun)
    Gun.Damage = Gun.Damage * 1.2 
end

return KillClip