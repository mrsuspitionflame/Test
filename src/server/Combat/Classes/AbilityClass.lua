local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Combat = script:FindFirstAncestor("Combat")
local Abilities = Combat:WaitForChild("Abilities")
local Grenades = Abilities:WaitForChild("Grenades")

local AbilityClass = {}

AbilityClass.__index = AbilityClass

function AbilityClass.new(player, AbilityInfo, stateManager, animationController)
	local self = setmetatable({}, AbilityClass)

	self.Player = player
	self.StateManager = stateManager
	self.AnimationController = animationController

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade))

	self.Trove = Trove.new()
	return self
end

function AbilityClass:GrenadeHeld(data)
	print("AbilityClass:GrenadeHeld called for player:", self.Player.Name)
	self.Grenade:Held(data, self.Player)
end

function AbilityClass:GrenadeReleased(data)
	print("AbilityClass:GrenadeReleased called for player:", self.Player.Name)
	self.Grenade:Released(data, self.Player)
end

return AbilityClass
