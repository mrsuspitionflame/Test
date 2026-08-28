local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))
local MovementSettings = require(Settings:WaitForChild("MovementSettings"))

local AnimationLoader = {}
AnimationLoader.__index = AnimationLoader

local function GetAnimator(Model)
	local Humanoid = Model:WaitForChild("Humanoid")
	return Humanoid:WaitForChild("Animator")
end

-- Lifecycle

function AnimationLoader.new(AnimationController)
	local self = setmetatable({}, AnimationLoader)
	self.AnimationController = AnimationController

	self.WeaponTrove = AnimationController.WeaponTrove
	self.AbilityTrove = AnimationController.AbilityTrove
	self.MovementTrove = AnimationController.MovementTrove

	self.WeaponAnimations = AnimationController.WeaponAnimations
	self.AbilityAnimations = AnimationController.AbilityAnimations
	self.MovementAnimations = AnimationController.MovementAnimations
	return self
end

function AnimationLoader:LoadWeaponAnimations(ViewModel, WeaponInfo)
	local ViewModelAnimator = GetAnimator(ViewModel)
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local CharacterAnimator = GetAnimator(Character)

	for ActionName, AnimationIDs in pairs(WeaponInfo.ANIMATION_IDS) do
		for AnimationType, AnimationId in pairs(AnimationIDs) do
			if AnimationId == nil then
				continue
			end

			local Animation = Instance.new("Animation")
			Animation.Name = ActionName .. AnimationType .. "Animation"
			Animation.AnimationId = AnimationId

			local Animator = if AnimationType == "CHARACTER" then CharacterAnimator else ViewModelAnimator
			local LoadedAnimation = Animator:LoadAnimation(Animation)

			if not self.WeaponAnimations[ActionName] then
				self.WeaponAnimations[ActionName] = {}
			end
			self.WeaponAnimations[ActionName][AnimationType] = self.WeaponTrove:Add(LoadedAnimation)
		end
	end
end

function AnimationLoader:LoadAbilityAnimations(ViewModel, AbilityInfo)
	local ViewModelAnimator = GetAnimator(ViewModel)
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local CharacterAnimator = GetAnimator(Character)

	for AbilityType, AbilityName in pairs(AbilityInfo) do
		if not AbilitySettings[AbilityType] or not AbilitySettings[AbilityType][AbilityName] then
			continue
		end
		local AbilityData = AbilitySettings[AbilityType][AbilityName]
		for ActionName, AnimationIDs in pairs(AbilityData.ANIMATION_IDS) do
			for AnimationType, AnimationId in pairs(AnimationIDs) do
				if AnimationId == nil then
					continue
				end

				local Animation = Instance.new("Animation")
				Animation.Name = ActionName .. AnimationType .. "Animation"
				Animation.AnimationId = AnimationId

				local Animator = if AnimationType == "CHARACTER" then CharacterAnimator else ViewModelAnimator
				local LoadedAnimation = Animator:LoadAnimation(Animation)

				if not self.AbilityAnimations[AbilityType] then
					self.AbilityAnimations[AbilityType] = {}
				end
				if not self.AbilityAnimations[AbilityType][ActionName] then
					self.AbilityAnimations[AbilityType][ActionName] = {}
				end
				self.AbilityAnimations[AbilityType][ActionName][AnimationType] = self.AbilityTrove:Add(LoadedAnimation)
			end
		end
	end
end

function AnimationLoader:LoadMovementAnimations()
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local CharacterAnimator = GetAnimator(Character)

	for ActionName, AnimationId in pairs(MovementSettings.LOAD_ANIMATION_IDS) do
		if AnimationId == nil then
			continue
		end

		local Animation = Instance.new("Animation")
		Animation.Name = ActionName .. "Animation"
		Animation.AnimationId = AnimationId

		local LoadedAnimation = CharacterAnimator:LoadAnimation(Animation)
		self.MovementAnimations[ActionName] = self.MovementTrove:Add(LoadedAnimation)
	end
end

return AnimationLoader
