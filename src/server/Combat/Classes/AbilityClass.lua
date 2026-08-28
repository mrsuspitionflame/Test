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

function AbilityClass.new(player, AbilityInfo, stateManager, animationController)
	local self = setmetatable({
		Trove = Trove.new(),

		Player = player,
		StateManager = stateManager,
		AnimationController = animationController,
	}, AbilityClass)

	self.AbilityInfo = {
		GrenadeInfo = table.clone(AbilitySettings.Grenade[AbilityInfo.Grenade]),
	}

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	self:Init()
	return self
end

function AbilityClass:Destroy()
	self.Trove:Destroy()
end

function AbilityClass:GetAnimations()
	self.Animations = {
		Grenade = {
			Held = self.AnimationController:GetAnimation({
				AnimationType = "ViewModel",
				AnimationLocation = "AbilityAnimations",
				AnimationName = "Held",
				AbilityName = "Grenade",
			}),
			Released = self.AnimationController:GetAnimation({
				AnimationType = "ViewModel",
				AnimationLocation = "AbilityAnimations",
				AnimationName = "Released",
				AbilityName = "Grenade",
			}),
		},
	}
end

function AbilityClass:Init()
	self:GetAnimations()
end

return AbilityClass
