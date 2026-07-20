local WeaponRuntime = {}
WeaponRuntime.__index = WeaponRuntime

function WeaponRuntime.new(weapon)
    local self = setmetatable({}, WeaponRuntime)
    self.weapon = weapon
    return self
end

return WeaponRuntime