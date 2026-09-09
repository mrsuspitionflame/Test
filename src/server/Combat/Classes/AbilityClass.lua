local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Combat = script:FindFirstAncestor("Combat")
local Abilities = Combat:WaitForChild("Abilities")
local Grenades = Abilities:WaitForChild("Grenades")

local AbilityClass = {}

AbilityClass.__index = AbilityClass

function AbilityClass.new(player, AbilityInfo, stateManager, combatClasses)
	local self = setmetatable({
		Trove = Trove.new(),

		Player = player,
		StateManager = stateManager,
		CombatClasses = combatClasses,
	}, AbilityClass)

	self.AbilityInfo = {
		GrenadeInfo = table.clone(AbilitySettings.Grenade[AbilityInfo.Grenade]),
	}

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	return self
end

function AbilityClass:OnCharacterRemoved()
	self.Grenade:Reset()
end

function AbilityClass:Destroy()
	self:OnCharacterRemoved()
	self.Trove:Destroy()
end

return AbilityClass
