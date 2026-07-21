local WeaponRuntime = {}
WeaponRuntime.__index = WeaponRuntime

function WeaponRuntime.new(weapon)
    local self = setmetatable({}, WeaponRuntime)
    local GunStats = require(game.ServerScriptService.Classes.GunStats)
    self.stats = GunStats[weapon]
    self.name = weapon
    return self
end



return WeaponRuntime