local Animations = script.Parent.Parent:WaitForChild("Animations")
local ViewModelAnimation = require(Animations:WaitForChild("ViewModelAnimation"))
local CharacterAnimation = require(Animations:WaitForChild("CharacterAnimation"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local AnimationController = {}

function AnimationController.new()
	local self = setmetatable({}, { __index = AnimationController })

	self.Trove = Trove.new()

	self.ViewModelAnimations = {
		AbilityAnimations = {},
		WeaponAnimations = {},
		MovementAnimations = {},
	}

	self.CharacterAnimations = {
		AbilityAnimations = {},
		CharacterAnimations = {},
		MovementAnimations = {},
	}

	self.ViewModelAnimation = ViewModelAnimation.new(self)
	--self.CharacterAnimation = CharacterAnimation.new(self)

	return self
end

function AnimationController:GetController(controllerName)
	if controllerName == "ViewModel" then
		return self.ViewModelAnimation
	end
	return
end

function AnimationController:GetAnimation(data)
	if data.AnimationType == "ViewModel" then
		if data.AnimationLocation == "AbilityAnimations" then
			return self.ViewModelAnimations.AbilityAnimations[data.AbilityName][string.upper(data.AnimationName)]
		elseif data.AnimationLocation == "WeaponAnimations" then
			return self.ViewModelAnimations.WeaponAnimations[string.upper(data.AnimationName)]
		end
	end
	return
end

function AnimationController:OnEquip(WeaponInfo)
	self.ViewModelAnimation:OnEquip(WeaponInfo)
end

function AnimationController:OnUnequip()
	self.ViewModelAnimation:OnUnequip()
end

function AnimationController:StartSprint() end

function AnimationController:StopSprint() end

function AnimationController:CreateAbilityViewModel(data)
	self.ViewModelAnimation:CreateAbilityViewModel(data)
end

return AnimationController
