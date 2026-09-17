local Handlers = script.Parent
local ViewModelHandler = require(Handlers:WaitForChild("ViewModelHandler"))
local AnimationLoader = require(Handlers.Parent:WaitForChild("AnimationLoader"))
local CameraHandler = require(Handlers:WaitForChild("CameraHandler"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

function AnimationHandler.new(StateManager)
	local self = setmetatable({}, AnimationHandler)

	self.StateManager = StateManager
	self.Trove = Trove.new()
	self.AbilityTrove = self.Trove:Extend()
	self.WeaponTrove = self.Trove:Extend()

	self.AbilityAnimations = {}
	self.WeaponAnimations = {}

	self.AnimationLoader = AnimationLoader.new(self)
	self.CameraHandler = CameraHandler.new(self)
	self.ViewModelHandler = ViewModelHandler.new(self)

	return self
end

function AnimationHandler:GetAnimation(animationType)
	if animationType == "Weapon" then
		return self.WeaponAnimations
	elseif animationType == "Ability" then
		return self.AbilityAnimations
	elseif animationType == "Movement" then
		return self.MovementAnimations
	end

	return nil
end

function AnimationHandler:OnEquip(WeaponInfo)
	self.ViewModelHandler:OnEquip(WeaponInfo)
end

function AnimationHandler:OnUnequip()
	self.ViewModelHandler:OnUnequip()
end

function AnimationHandler:CreateAbilityViewModel(data)
	self.ViewModelHandler:CreateAbilityViewModel(data)
end

return AnimationHandler
