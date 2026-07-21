local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GunStats = require(Shared:WaitForChild("BaseGunStats"))

local WeaponRuntime = {}
WeaponRuntime.__index = WeaponRuntime

function WeaponRuntime.new(player, weaponName, perks)
	local baseStats = GunStats[weaponName]

	if not baseStats then
		return nil
	end

	local self = setmetatable({}, WeaponRuntime)

	self.player = player
	self.name = weaponName

	-- Copy the stats so perks don't modify the shared GunStats table.
	self.stats = table.clone(baseStats)

	-- Perk modules should already have been validated by GunSystemServer.
	self.perks = perks or {}
	self.perkState = {}

	self.ammo = self.stats.MagazineSize
	self.isReloading = false
	self.lastFireTime = 0
	self.destroyed = false
	self.reloadId = 0

	-- Temporary context used only during runtime creation.
	local context = {
		stats = self.stats,
	}

	self:_runPerkHook("ApplyStats", context)
	self:_validateStats()

	return self
end

function WeaponRuntime:RunPerkHook() end

return WeaponRuntime
