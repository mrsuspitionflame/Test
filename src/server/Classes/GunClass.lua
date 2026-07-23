local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))


local GunClass = {}
GunClass.__index = GunClass

function GunClass.CreateGun(player, gunType)
    print("Created gun")
    local self = setmetatable({}, GunClass)
    self.player = player
    self.gunType = gunType
    self.damage = GunDefinitions.GunTypes[gunType].Damage
    self.range = GunDefinitions.GunTypes[gunType].Range
    self.fireRate = GunDefinitions.GunTypes[gunType].FireRate
    self.ammo = GunDefinitions.GunTypes[gunType].Ammo
    self.perks = GunDefinitions.GunTypes[gunType].PerkList
    return self
end

function GunClass:ActivatePerk(HookName)
    for _, perk in ipairs(self.perks) do
        local hook = perk[HookName]
        if typeof(hook) == "function" then
            hook(self)
        end
    end
end

function GunClass:Reload()
end

function GunClass:Fire()
end

function GunClass:Destroy()
    -- Cleanup code for the gun instance
end

return GunClass