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

function AbilityClass.new(player, AbilityInfo, stateManager)
	local self = setmetatable({
		Trove = Trove.new(),

		Player = player,
		StateManager = stateManager,
	}, AbilityClass)

	self.AbilityInfo = {
		GrenadeInfo = table.clone(AbilitySettings.Grenade[AbilityInfo.Grenade]),
	}

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	return self
end

function AbilityClass:Destroy()
	self.Trove:Destroy()
end

return AbilityClass
