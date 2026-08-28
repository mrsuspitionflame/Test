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

<<<<<<< HEAD
function AbilityClass.new(player, AbilityInfo, stateManager, animationController)
	local self = setmetatable({
		Trove = Trove.new(),

		Player = player,
		StateManager = stateManager,
		AnimationController = animationController,
=======
function AbilityClass.new(player, AbilityInfo, stateManager)
	local self = setmetatable({
		Trove = Trove.new(),

		Player = player,
		StateManager = stateManager,
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669
	}, AbilityClass)

	self.AbilityInfo = {
		GrenadeInfo = table.clone(AbilitySettings.Grenade[AbilityInfo.Grenade]),
	}

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

<<<<<<< HEAD
	self:Init()
	return self
=======
	return self
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669
end

function AbilityClass:Destroy()
	self.Trove:Destroy()
<<<<<<< HEAD
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
=======
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669
end

return AbilityClass
