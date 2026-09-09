local Animations = script.Parent.Parent:WaitForChild("Animations")
local ViewModelController = require(Animations:WaitForChild("ViewModelController"))
local AnimationLoader = require(Animations:WaitForChild("AnimationLoader"))
local CameraController = require(Animations:WaitForChild("CameraController"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(StateManager)
	local self = setmetatable({}, AnimationController)

	self.StateManager = StateManager
	self.Trove = Trove.new()
	self.AbilityTrove = self.Trove:Extend()
	self.WeaponTrove = self.Trove:Extend()

	self.AbilityAnimations = {}
	self.WeaponAnimations = {}

	self.AnimationLoader = AnimationLoader.new(self)
	self.CameraController = CameraController.new(self)
	self.ViewModelController = ViewModelController.new(self)

	return self
end

function AnimationController:GetAnimation(animationType)
	if animationType == "Weapon" then
		return self.WeaponAnimations
	elseif animationType == "Ability" then
		return self.AbilityAnimations
	elseif animationType == "Movement" then
		return self.MovementAnimations
	end

	return nil
end

function AnimationController:OnEquip(WeaponInfo)
	self.ViewModelController:OnEquip(WeaponInfo)
end

function AnimationController:OnUnequip()
	self.ViewModelController:OnUnequip()
end

function AnimationController:CreateAbilityViewModel(data)
	self.ViewModelController:CreateAbilityViewModel(data)
end

return AnimationController
