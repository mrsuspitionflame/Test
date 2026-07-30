local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GunClass = {}
GunClass.__index = GunClass

function GunClass.CreateGun(player, LoadoutSlot)
	print("Created gun")
	local self = {
		player = player,
		Slot = LoadoutSlot,	
		gunType = LoadoutSlot:GetAttribute("GunType"),
		damage = LoadoutSlot:GetAttribute("Damage"),
		range = LoadoutSlot:GetAttribute("Range"),
		fireRate = LoadoutSlot:GetAttribute("FireRate"),
		ammo = LoadoutSlot:GetAttribute("Ammo"),
		perks = LoadoutSlot:GetAttribute("Perks"),
	}
	setmetatable(self, GunClass)
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

function GunClass:Reload() end

function GunClass:Fire() end

function GunClass:Destroy()
	-- Cleanup code for the gun instance
end

return GunClass
